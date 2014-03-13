class ImageFile < ActiveRecord::Base
  attr_accessible :file, :item_id, :original_file_url
  belongs_to :item

  mount_uploader :file, ImageUploader

  def upload_to
    item.upload_to
  end

  def has_file?
    !self.file.try(:path).nil?
  end

  def filename(version=nil)
    fn = if has_file?
      f = version ? file.send(version) : file
      File.basename(f.path)
    elsif !original_file_url.blank?
      f = URI.parse(original_file_url).path || ''
      x = File.extname(f)
      v = !version.blank? ? ".#{version}" : nil
      File.basename(f, x) + (v || x)
    end || ''
    fn
  end

  def url(*args)
    file.try(:url, *args)
  end

end
