class StorageConfiguration < ActiveRecord::Base
  attr_accessible :bucket, :key, :provider, :secret, :is_public

  validates_presence_of :key, :secret, :provider

  def ==(acoll)
    return false unless (acoll && acoll.is_a?(StorageConfiguration))
    [:bucket, :key, :provider, :secret, :is_public].inject(true){|equal, a| equal && (self.send(a) == acoll.send(a))}
  end

  def attributes
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
    # currently using aws for this
    case provider.downcase
    when 'aws' then true
    when 'internetarchive' then false
    else false
    end
  end

  def automatic_transcode?
    # currently using aws for this
    case provider.downcase
    when 'aws' then false
    when 'internetarchive' then true
    else false
    end
  end

  def use_folders?
    case provider.downcase
    when 'aws' then true
    when 'internetarchive' then false
    else false
    end
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
