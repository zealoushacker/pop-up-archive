class SubscriptionPlan < ActiveRecord::Base
  attr_accessible :pop_up_hours, :name, :amount

  COMMUNITY_PLAN_HOURS = 2
  ORGANIZATION_PLAN_HOURS = 100

  before_save :save_stripe_plan
  after_destroy :delete_stripe_plan
  delegate :name, :name=, :amount, to: :stripe_plan

  def self.community
    find_or_create_by_stripe_plan_id('community') do |plan|
      plan.pop_up_hours = COMMUNITY_PLAN_HOURS
      plan.name = "Community"
      plan.amount = 0
    end
  end

  def self.organization
    find_or_create_by_stripe_plan_id('organization') do |plan|
      plan.pop_up_hours = 100
      plan.name = "Organization"
      plan.amount = 0
    end
  end

  def stripe_plan
    @stripe_plan ||= Stripe::Plan.retrieve(stripe_plan_id)
  rescue Stripe::InvalidRequestError
    @stripe_new_plan = true
    @stripe_plan = Stripe::Plan.construct_from(id: stripe_plan_id,
      currency: 'usd',
      interval: 'month',
      name: stripe_plan_id,
      amount: 0)
  end

  def stripe_plan_id=(id)
    super.tap do
      @stripe_plan = nil
    end
  end

  def stripe_plan_id
    super || self.stripe_plan_id = generate_stripe_plan_id
  end

  def stripe_persisted?
    stripe_plan && !@stripe_new_plan
  end

  def amount=(new_amount)
    if stripe_persisted?
      @plan_to_delete = stripe_plan
      self.stripe_plan_id = generate_stripe_plan_id
      stripe_plan.name = @plan_to_delete.name
    end
    stripe_plan.amount = new_amount
  end

  private

  def delete_stripe_plan
    @plan_to_delete.delete if @plan_to_delete.present?
    if stripe_persisted?
      stripe_plan.delete
    end
  end

  def generate_stripe_plan_id
    Digest::SHA1.hexdigest("#{object_id}-#{DateTime.now}")
  end

  def save_stripe_plan
    if stripe_persisted?
      stripe_plan.save
    else
      @stripe_plan = Stripe::Plan.create(stripe_plan.to_hash.slice(:id, :amount, :currency, :interval, :name))
      @plan_to_delete.delete and @plan_to_delete = nil if @plan_to_delete.present?
      @stripe_new_plan =  false
      true
    end
  rescue Stripe::InvalidRequestError => e
    false
  end
end
