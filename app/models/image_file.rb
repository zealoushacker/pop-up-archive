class ImageFile < ActiveRecord::Base

  include FileStorage

  attr_accessible :file, :item_id, :original_file_url, :storage_id, :is_uploaded, :remote_file_url
  belongs_to :item
  belongs_to :storage_configuration, class_name: "StorageConfiguration", foreign_key: :storage_id

  mount_uploader :file, ImageUploader

  after_commit :process_file, on: :create
  after_commit :process_update_file, on: :update

  def process_update_file
    # logger.debug "af #{id} call copy_to_item_storage"
    copy_to_item_storage
  end

  def detect_urls
    ImageUploader.version_formats.keys.inject({}){|h, k| h[k] = { url: file.send(k).url, detected_at: nil }; h}
  end

  def process_file
    # don't process file if no file to process yet (s3 upload)
    return if !has_file? && original_file_url.blank?

    copy_original

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def save_thumb_version
    file.recreate_versions!
    logger.info "****************** created  thumb version" 
  end
   
  def file_uploaded(file_name)
    update_attributes(:is_uploaded => true, :file => file_name)
    upload_id = upload_to.id
    update_file!(file_name, upload_id)
    # now copy it to the right place if it needs to be (e.g. s3 -> ia)
    # or if it is in the right spot, process it!
    copy_to_item_storage
    save_thumb_version
    # logger.debug "Tasks::UploadTask: after_tr       
  end
end
