class S3UploadRequest

  require 'base64'
  require 'digest'

  attr_accessor :date, :upload_id, :key, :chunk, :mime_type,
    :bucket, :signature

  def initialize(data)
    params          = data[:params]
    type            = data[:type]
    @bucket         = data[:bucket]
    @secret         = data[:secret]
    @date           = Time.now.utc.strftime("%a, %d %b %Y %X %Z")
    @upload_id      = params[:upload_id]
    @key            = params[:key]
    @chunk          = params[:chunk]
    @mime_type      = params[:mime_type] || params[:content_type] || 'application/octet-stream'

    if type == :init
      @signature = upload_init_signature
    elsif type == :part
      @signature = upload_part_signature
    elsif type == :complete
      @signature = upload_complete_signature
    elsif type == :list
      @signature = upload_list_signature
    elsif type == :delete
      @signature = upload_delete_signature
    else
      @signature = nil
    end
  end

  def to_h
    {
      :date      => @date,
      :bucket    => @bucket,
      :upload_id => @upload_id,
      :chunk     => @chunk,
      :mime_type => @mime_type,
      :signature => @signature
    }
  end

  private

  def upload_init_signature
    encode("POST\n\n#{@mime_type}\n\nx-amz-acl:public-read\nx-amz-date:#{@date}\n/#{@bucket}/#{@key}?uploads")
  end

  def upload_part_signature
    encode("PUT\n\n#{@mime_type}\n\nx-amz-date:#{@date}\n/#{@bucket}/#{@key}?partNumber=#{@chunk}&uploadId=#{@upload_id}")
  end

  def upload_complete_signature
    encode("POST\n\n#{@mime_type}\n\nx-amz-date:#{@date}\n/#{@bucket}/#{@key}?uploadId=#{@upload_id}")
  end

  def upload_list_signature
    encode("GET\n\n\n\nx-amz-date:#{@date}\n/#{@bucket}/#{@key}?uploadId=#{@upload_id}")
  end

  def upload_delete_signature
    encode("DELETE\n\n\n\nx-amz-date:#{@date}\n/#{@bucket}/#{@key}?uploadId=#{@upload_id}")
  end

  def encode(data)
    Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', @secret, data))
  end

end
