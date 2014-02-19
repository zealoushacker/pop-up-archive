class ImageFile < ActiveRecord::Base
  attr_accessible :file, :item_id
  belongs_to :item

  mount_uploader :file, ImageUploader

  def upload_to
    item.upload_to
  end

  def filename(version=nil)
	File.basename(file.path)
  end

  def url(*args)
    file.try(:url, *args)
  end

end
