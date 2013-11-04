class StorageConfiguration < ActiveRecord::Base
  attr_accessible :bucket, :key, :provider, :secret, :is_public

  validates_presence_of :key, :secret, :provider

  def ==(acoll)
    return false unless (acoll && acoll.is_a?(StorageConfiguration))
    [:bucket, :key, :provider, :secret, :is_public].inject(true){|equal, a| equal && (self.send(a) == acoll.send(a))}
  end

  def provider_attributes
    {}
  end

  def credentials
    options = nil
    abbr = abbr_for_provider
    if key && secret && provider && abbr
      options = {
        :provider => provider,
        "#{abbr}_access_key_id".to_sym => key,
        "#{abbr}_secret_access_key".to_sym => secret
      }
      options[:path_style] = true if provider.downcase == 'aws'
    end
    options
  end

  def abbr_for_provider
    case provider.downcase
    when 'aws' then 'aws'
    when 'internetarchive' then 'ia'
    else provider.downcase
    end
  end

  def direct_upload?
    at_amazon?
  end

  def automatic_transcode?
    at_internet_archive?
  end

  def use_folders?
    at_amazon?
  end

  def at_internet_archive?
    provider.downcase == 'internetarchive'
  end

  def at_amazon?
    provider.downcase == 'aws'
  end

  def self.archive_storage
    self.new({
      provider:  'InternetArchive',
      key:       ENV['IA_ACCESS_KEY_ID'],
      secret:    ENV['IA_SECRET_ACCESS_KEY'],
      is_public: true
    })
  end

  def self.popup_storage
    self.new({
      provider:  'AWS',
      key:       ENV['AWS_ACCESS_KEY_ID'],
      secret:    ENV['AWS_SECRET_ACCESS_KEY'],
      bucket:    ENV['AWS_BUCKET'],
      is_public: false
    })
  end

end
