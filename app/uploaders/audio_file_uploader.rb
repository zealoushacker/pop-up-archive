# encoding: utf-8

class AudioFileUploader < CarrierWave::Uploader::Base
  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  def self.version_formats
    {
      'mp3' => {'format' => 'mp3', 'bit_rate' => 128, 'sample_rate' => 44100, 'channel_mode' => 's'},
      'ogg' => {'format' => 'ogg', 'bit_rate' => 96, 'sample_rate' => 44100, 'channel_mode' => 's'}
    }
  end

  # we're gonna make them on fixer, but define the versions
  version_formats.keys.each do |label|
    version label
  end

  def extension_white_list
    ['aac', 'aif', 'aiff', 'alac', 'flac', 'm4a', 'm4p', 'mp2', 'mp3', 'mp4', 'ogg', 'raw', 'spx', 'wav', 'wma']
  end

  def public_url

    if !asset_host && (provider == "InternetArchive")
      "http://archive.org/download/#{model.destination_directory}#{model.destination_path}"
    else
      super
    end
  end

  def store_dir
    model.store_dir
  end

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

  def full_filename(for_file)
    if !version_name
      return super(for_file)
    else
      ext = File.extname(for_file)
      base = File.basename(for_file, ext)
      "#{base}.#{version_name}"
    end
  end

  def full_original_filename
    if !version_name
      super
    else
      fn = super
      ext = File.extname(fn)
      base = File.basename(fn, ext)
      "#{base}.#{version_name}"
    end
  end

end
