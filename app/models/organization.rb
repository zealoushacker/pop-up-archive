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

end
