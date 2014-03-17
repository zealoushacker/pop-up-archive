class ImageFile < ActiveRecord::Base

  include FileStorage

  attr_accessible :file, :item_id, :original_file_url, :storage_id
  belongs_to :item

  mount_uploader :file, ImageUploader

  after_commit :process_file, on: :create
  after_commit :process_update_file, on: :update

  def process_update_file
    # logger.debug "af #{id} call copy_to_item_storage"
    copy_to_item_storage
  end

  def process_file
    # don't process file if no file to process yet (s3 upload)
    return if !has_file? && original_file_url.blank?

    copy_original

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end
end
