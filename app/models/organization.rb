class Organization < ActiveRecord::Base
  resourcify

  attr_accessible :name

  has_many :users
  has_many :collection_grants, as: :collector
  has_many :collections, through: :collection_grants

  has_one  :uploads_collection_grant, class_name: 'CollectionGrant', as: :collector, conditions: {uploads_collection: true}
  has_one  :uploads_collection, through: :uploads_collection_grant, source: :collection

  after_commit :add_uploads_collection, on: :create

  ROLES = [:admin, :member]

  def add_uploads_collection
    self.uploads_collection = Collection.new(title: "Uploads", items_visible_by_default: false)
    create_uploads_collection_grant collection: uploads_collection
  end

  def plan
    SubscriptionPlan.organization
  end

  def set_amara_team(options={})
    options    = amara_team_defaults.merge(options)
    amara_team = find_or_create_amara_team(options)
    update_attribute(:amara_team, amara_team.slug)
  end

  def find_or_create_amara_team(options)
    amara_team = amara_client.teams.get(options[:slug]) rescue nil
    unless amara_team
      response = amara_client.teams.create(options)
      amara_team = response.object
    end
    amara_team
  end

  def amara_team_defaults
    {
      name: self.name,
      slug: self.name.parameterize,
      is_visible: false,
      membership_policy: Amara::TEAM_POLICIES[:invite]
    }
  end

  def amara_client
    Amara::Client.new(
      api_key:      amara_key || ENV['AMARA_KEY'],
      api_username: amara_username || ENV['AMARA_USERNAME'],
      endpoint:     "https://#{ENV['AMARA_HOST']}/api2/partners"
    )
  end

end
