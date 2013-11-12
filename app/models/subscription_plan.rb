class SubscriptionPlan

  def self.all
    Rails.cache.fetch([:plans, :group, :all], expires_in: 30.minutes) do
      Stripe::Plan.all(count: 100).map {|p| new(p) }.tap do |plans|
        plans.each do |plan|
          Rails.cache.write([:plans, :individual, plan.id], plan, expires_in: 30.minutes)
        end
      end
    end
  end

  def self.ungrandfathered
    Rails.cache.fetch([:plans, :group, :ungrandfathered], expires_in: 30.minutes) do
      all.select { |p| (p.name ||'')[0] != '*' }
    end
  end

  def self.find(id)
    Rails.cache.fetch([:plans, :individual, id], expires_in: 30.minutes) do
      all.find { |p| p.id == id }
    end
  end

  def self.community
    Rails.cache.fetch([:plans, :group, :community], expires_in: 30.minutes) do
      ungrandfathered.find { |p| p.amount == 0 && p != organization } || create(id: '2_community', name: 'Community', amount: 0)
    end
  end

  def self.organization
    Rails.cache.fetch([:plans, :group, :organization], expires_in: 30.minutes) do
      all.find { |p| p.id =~ /organization/ } || create(id: '100_organization', name: 'Organization', amount: 0)
    end
  end

  def self.create(options)
    plan_id = "#{options[:hours]||2}-#{SecureRandom.hex(8)}"
    interval = options[:interval] || 'month'
    new(Stripe::Plan.create(id: plan_id,
      name: options[:name],
      amount: options[:amount],
      currency: 'USD',
      interval: interval)).tap do |plan|
      Rails.cache.delete([:plans, :group, :all])
      Rails.cache.delete([:plans, :group, :ungrandfathered])
      Rails.cache.delete([:plans, :group, :community])
      Rails.cache.write([:plans, :individual, plan_id], plan, expires_in: 30.minutes)
    end
  end

  def initialize(plan)
    @id = plan.id
    @hours = calculate_plan_hours(plan.id)
    @name = plan.name
    @amount = plan.amount
  end

  attr_reader :name, :amount, :hours, :id

  def eql?(plan)
    plan.id == id
  end

  alias_method :==, :eql?

  private

  def calculate_plan_hours(id)
    hours = id.split(/\-|_/)[0].to_i
    if hours == 0
      2
    else
      hours
    end
  end
end
