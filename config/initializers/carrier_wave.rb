CarrierWave.configure do |config|

  config.remove_previously_stored_files_after_update = false

  config.root = Rails.root.join('tmp')
  config.cache_dir = "#{Rails.root}/tmp/uploads"


  config.storage        = :fog
  config.fog_directory  = ENV['AWS_BUCKET']
  config.fog_public     = false

  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  }

  config.fog_attributes = {}

  if Rails.env.test? or Rails.env.cucumber?
    config.storage = :file
    config.enable_processing = false
  end
end
