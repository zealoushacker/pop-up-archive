class ImageFile < ActiveRecord::Base

  include FileStorage

  attr_accessible :file, :item_id, :original_file_url
  belongs_to :item

  mount_uploader :file, ImageUploader

end
