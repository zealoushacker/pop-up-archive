# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base
  
  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper
  
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  
  version :thumb do
    process :resize_to_fill => [75, 75]
  end
  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #   "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  # end

  def store_dir
    model.store_dir
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end
  process :resize_to_fit => [200, 200]

  # Create different versions of your uploaded files:


  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
  def fog_attributes
    # build off these options, set rest that are needed (some are defaults in fixer already)
    fa = model.destination_options
    fa ||= {}

    if provider == 'InternetArchive'
      fa[:collections] = [] unless fa.has_key?(:collections)
      fa[:collections] << 'test_collection' if !Rails.env.production?
      fa[:ignore_preexisting_bucket] = 0
      fa[:interactive_priority] = 1
      fa[:auto_make_bucket] = 1
      fa[:cascade_delete] = 1
    end

    fa
  end

  def fog_directory
    model.destination_directory
  end

  def fog_public
    model.storage.is_public?
  end

  def provider
    model.storage.credentials[:provider].to_s
  end

  def fog_credentials
    model.storage.credentials
  end

  private

  # def full_filename(for_file)
  #   if !version_name
  #     return super(for_file)
  #   else
  #     ext = File.extname(for_file)
  #     base = File.basename(for_file, ext)
  #     "#{version_name}.#{base}"
  #   end
  # end

  # def full_original_filename
  #   if !version_name
  #     super
  #   else
  #     fn = super
  #     ext = File.extname(fn)
  #     base = File.basename(fn, ext)
  #     "#{base}.#{version_name}"
  #   end
  # end  

  # # we're gonna make them on fixer, but define the versions
  # version_formats.keys.each do |label|
  #   version label
  # end

  def public_url
    if !asset_host && (provider == "InternetArchive")
      "http://archive.org/download/#{model.destination_directory}#{model.destination_path}"
    else
      super
    end
  end





end

