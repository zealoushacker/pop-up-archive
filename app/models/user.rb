class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :provider, :uid, :name, :invitation_token

  belongs_to :organization

  after_validation :customer #ensure that a stripe customer has been created
  after_destroy :delete_customer

  has_many :collection_grants, as: :collector
  has_one  :uploads_collection_grant, class_name: 'CollectionGrant', as: :collector, conditions: {uploads_collection: true}, autosave: true

  has_one  :uploads_collection, through: :uploads_collection_grant, source: :collection
  has_many :collections, through: :collection_grants
  has_many :items, through: :collections
  has_many :audio_files, through: :items
  has_many :csv_imports
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner

  validates_presence_of :invitation_token, if: :invitation_token_required?
  validates_presence_of :name, if: :name_required?
  validates_presence_of :uploads_collection

  OVERAGE_CALC = 'coalesce(used_metered_storage_cache - pop_up_hours_cache * 3600, 0)'

  scope :over_limits, -> { select("users.*, #{OVERAGE_CALC} as overage").where("#{OVERAGE_CALC} > 0").order('overage DESC') }

  delegate :name, :id, :amount, to: :plan, prefix: true

  def self.find_for_oauth(auth, signed_in_resource=nil)
    where(provider: auth.provider, uid: auth.uid).first ||
    find_invited(auth) ||
    create{|user| user.apply_oauth(auth)}
  end

  def self.find_invited(auth)
    user = where(invitation_token: auth.invitation_token).first if auth.invitation_token
    user = where(email: auth.info.email).first if !user && auth.info.email
    user.apply_oauth(auth) if user
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.oauth_data"]
        user.provider = data['provider']
        user.uid      = data['uid']
        user.email    = data["email"] if user.email.blank?
        user.name     = data["name"] if user.name.blank?
        user.invitation_token = session[:invitation_token]
        user.valid? if data[:should_validate]
      end
    end
  end

  def apply_oauth(auth)
    self.provider = auth.provider
    self.uid      = auth.uid
    self.name     = auth.info.name
    self.email    = auth.info.email
  end

  def password_required?
    # logger.debug "password_required? checked on #{self.inspect}\n"
    !provider.present? && !@skip_password && super
  end

  def name_required?
    # logger.debug "name_required? checked on #{self.inspect}\n"
    !provider.present? && !@skip_password && !name.present?
  end

  def invitation_token_required?
    !invitation_accepted_at.present?
  end

  def searchable_collection_ids
    collection_ids - [uploads_collection.id]
  end

  def collections
    organization ? organization.collections : super
  end

  def collection_ids
    organization ? organization.collection_ids : super
  end

  def uploads_collection
    organization.try(:uploads_collection) || uploads_collection_grant.collection || add_uploads_collection
  end

  def in_organization?
    !!organization_id
  end

  # everyone is considered an admin on their own, role varies for those in orgs
  def role
    return :admin unless organization
    has_role?(:admin, organization) ? :admin : :member
  end

  def update_card!(card_token)
    cus = Stripe::Customer.retrieve(customer.id)
    cus.card = card_token
    cus.save
    invalidate_cache
  end

  def subscribe!(plan)
    cus = Stripe::Customer.retrieve(customer.id)
    cus.update_subscription(plan: plan.id)
    invalidate_cache
  end

  def add_invoice_item!(invoice_item)
    cus = Stripe::Customer.retrieve(customer.id)
    cus.add_invoice_item(invoice_item)
  end

  def plan
    organization ? organization.plan : customer.plan
  end

  def plan_json
      {
        name: plan.name,
        id: plan.id,
        amount: plan.amount,
        pop_up_hours: pop_up_hours
      }
  end

  def customer
    if customer_id.present?
      Rails.cache.fetch([:customer, :individual, customer_id], expires_in: 5.minutes) do
        Customer.new(Stripe::Customer.retrieve(customer_id))
      end
    else
      Customer.new(Stripe::Customer.create(email: email, description: name)).tap do |cus|
        self.customer_id = cus.id
        update_attribute :customer_id, cus.id if persisted?
        Rails.cache.write([:customer, :individual, cus.id], cus, expires_in: 5.minutes)
      end
    end
  end

  def pop_up_hours
    plan.hours
  end

  def used_metered_storage
    @_used_metered_storage ||= audio_files.where(metered: true).sum(:duration)
  end

  def used_unmetered_storage
    @_used_unmetered_storage ||= audio_files.where(metered: false).sum(:duration)
  end

  def active_credit_card_json
    active_credit_card.as_json.try(:slice, *%w(last4 type exp_month exp_year))
  end

  def active_credit_card
    customer.card
  end

  def update_usage_report!
    update_attribute :used_metered_storage_cache, used_metered_storage
    update_attribute :pop_up_hours_cache, pop_up_hours
  end

  private

  def delete_customer
    Stripe::Customer.retrieve(customer.id).delete
    invalidate_cache
  end

  def add_uploads_collection
    uploads_collection_grant.collection = Collection.new(title: 'My Uploads', creator: self, items_visible_by_default: false)
    if persisted?
      uploads_collection_grant.collection.save
      if grant = collection_grants.where(collection_id: uploads_collection_grant.collection.id).first
        self.uploads_collection_grant = grant
        grant.uploads_collection = true
      end
      uploads_collection_grant.save
    end
    uploads_collection_grant.collection
  end

  def uploads_collection_grant
    super or self.uploads_collection_grant = CollectionGrant.new(collector: self, uploads_collection: true)
  end

  def customer_cache_id
    [:customer, :individual, customer_id]
  end

  def invalidate_cache
    Rails.cache.delete(customer_cache_id)
  end

  class Customer
    attr_reader :id, :plan_id, :card

    def initialize(stripe_customer)
      @id = stripe_customer.id
      if stripe_customer.subscription.present?
        @plan_id = stripe_customer.subscription.plan.id
      end
      @card = stripe_customer.cards.data[0].as_json.try(:slice, *%w(last4 type exp_month exp_year))
    end

    def plan
      SubscriptionPlan.find(plan_id) || subscribe_to_community
    end

    def eql?(customer)
      customer.id == id
    end

    alias :eql? :==

    def subscribe_to_community
      Stripe::Customer.retrieve(customer.id).update_subscription(plan: SubscriptionPlan.community.id)
      SubscriptionPlan.community
    end
  end
end
