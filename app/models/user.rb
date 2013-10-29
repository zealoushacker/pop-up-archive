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
  before_save :save_customer

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
    customer.card = card_token
    customer.save
  end

  def card
    customer.card
  end

  def subscribe!(plan)
    customer.update_subscription(plan: plan.stripe_plan_id)
  end

  def plan
    if stripe_subscription.present?
      SubscriptionPlan.where(stripe_plan_id: stripe_subscription.plan.id).first
    else
      SubscriptionPlan.community
    end
  end

  def plan_name
    plan.stripe_plan_id
  end

  def plan_amount
    plan.amount
  end

  def customer
    @customer ||= if customer_id.present?
      Stripe::Customer.retrieve(customer_id)
    else
      Stripe::Customer.create(email: email, description: name).tap do |cus|
        self.customer_id = cus.id
      end
    end
  end

  def pop_up_hours
    plan.pop_up_hours
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
    customer.cards.data[0]
  end

  private

  def save_customer
    customer.save
  end

  def delete_customer
    customer.delete
  end

  def stripe_subscription
    customer.subscription
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
end
