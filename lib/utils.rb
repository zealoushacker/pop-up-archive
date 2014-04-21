require 'excon'

class Utils

  AUDIO_EXTENSIONS = ['aac', 'aif', 'aiff', 'alac', 'flac', 'm4a', 'm4p', 'mp2', 'mp3', 'mp4', 'ogg', 'raw', 'spx', 'wav', 'wma']
  IMAGE_EXTENSIONS = ['gif', 'png', 'jpg', 'jpeg']

	class<<self

    def http_resource_exists?(uri, retry_count=10)
      # logger.debug "http_resource_exists?: #{uri}"
      result = false
      try_count = 0
      request_uri = uri.to_s
      while(!result && (try_count < retry_count)) do

        # logger.debug "head: #{request_uri}"
        response = new_connection(request_uri).head(idempotent: true, retry_limit: retry_count)

        # logger.debug "response: #{response.inspect}"

        if response.status.to_s.start_with?('2')
          result = true
        elsif response.status.to_s.start_with?('3')
          # logger.debug "redirect: #{response.headers['Location']}"
          request_uri = response.headers['Location']
        else
          sleep(1)
        end
        try_count += 1
      end

      result
    end

    def new_connection(uri)
      Excon.new(uri)
    end

    def download_private_file(connection, uri, retry_count=10)
      bucket = uri.host
      key = uri.path[1..-1]
      file_name = key.split("/").last

      directory = connection.directories.get(bucket)

      try_count = 0
      file_exists = false
      while !file_exists && try_count < retry_count
        # logger.debug "s3_download_file: try: #{try_count}, checking for #{key} in #{bucket}"
        try_count += 1
        file_exists = directory.files.head(key)

        if !file_exists
          sleep(1)
        end
      end

      if !file_exists
        raise "File not found on s3: #{bucket}: #{key}"
      end

      result = directory.files.get(key).body

      if result.length <= 0
        raise "Zero length file from: #{uri}"
      end

      result
    end

    def is_audio_file?(url)
      #puts "is_audio_file? url:#{url}"
      begin
        uri = URI.parse(url)
        ext = (File.extname(uri.path)[1..-1] || "").downcase
        AUDIO_EXTENSIONS.include?(ext)
      rescue URI::BadURIError
        false
      rescue URI::InvalidURIError
        false
      end
    end
    
    def is_image_file?(url)
      #puts "is_audio_file? url:#{url}"
      begin
        uri = URI.parse(url)
        ext = (File.extname(uri.path)[1..-1] || "").downcase
        IMAGE_EXTENSIONS.include?(ext)
      rescue URI::BadURIError
        false
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
