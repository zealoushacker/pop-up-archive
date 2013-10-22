class Collection < ActiveRecord::Base

  acts_as_paranoid

  # include ActiveModel::ForbiddenAttributesProtection
  attr_accessible :title, :description, :items_visible_by_default, :creator, :creator_id, :storage

  belongs_to :default_storage, class_name: "StorageConfiguration"
  belongs_to :upload_storage, class_name: "StorageConfiguration"
  belongs_to :creator, class_name: "User"
  belongs_to :organization

  has_many :collection_grants, dependent: :destroy
  has_many :uploads_collection_grants, class_name: 'CollectionGrant', conditions: {uploads_collection: true}
  has_many :users, through: :collection_grants
  has_many :items, dependent: :destroy

  validates_presence_of :title

  validate :validate_storage

  scope :is_public, where(items_visible_by_default: true)

  before_validation :set_defaults

  after_commit :grant_to_creator, on: :create

  # def self.visible_to_user(user)
  #   if user.present?
  #     grants = CollectionGrant.arel_table
  #     (includes(:collection_grants).where(grants[:user_id].eq(user.id).or(arel_table[:items_visible_by_default].eq(true))))
  #   else
  #     is_public
  #   end
  # end

  def storage=(provider)
    if (provider == 'InternetArchive') && (!default_storage || (default_storage.provider != 'InternetArchive'))
      self.default_storage = StorageConfiguration.archive_storage
    end
    set_storage
  end

  def storage
    default_storage.provider
  end

  def validate_storage
    errors.add(:default_storage, "must be set") if !default_storage
    errors.add(:upload_storage, "must be set when default does not allow direct upload") if (!upload_storage && !default_storage.direct_upload?)
  end

  def upload_to
    upload_storage || default_storage
  end

  def set_storage
    self.default_storage = StorageConfiguration.popup_storage if !default_storage
    if default_storage.direct_upload?
      self.upload_storage = nil
    else
      self.upload_storage = StorageConfiguration.popup_storage if !upload_storage
    end
  end

  def set_defaults
    self.set_storage
    self.copy_media = true if self.copy_media.nil?
  end

  def grant_to_creator
    return unless creator
    collector = creator.organization || creator
    collector.collections << self
  end

  def uploads_collection?
    uploads_collection_grants.present?
  end

end
