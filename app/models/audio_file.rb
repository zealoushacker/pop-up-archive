# encoding: utf-8
require "digest/md5"

class AudioFile < ActiveRecord::Base

  include PublicAsset

  acts_as_paranoid

  before_validation :set_metered

  belongs_to :item, :with_deleted => true
  belongs_to :instance
  has_many :tasks, as: :owner
  has_many :transcripts, order: 'created_at desc'

  belongs_to :storage_configuration, class_name: "StorageConfiguration", foreign_key: :storage_id

  attr_accessible :file, :storage_id

  mount_uploader :file, ::AudioFileUploader

  after_commit :process_create_file, on: :create
  after_commit :process_update_file, on: :update

  attr_accessor :should_trigger_fixer_copy

  #default_scope includes(:transcripts)

  delegate :collection_title, to: :item

  TRANSCRIBE_RATE_PER_MINUTE = 2.00;

  def collection
    instance.try(:item).try(:collection) || item.try(:collection)
  end

  def filename(version=nil)
    fn = if file.try(:path)
      f = version ? file.send(version) : file
      File.basename(f.path)
    elsif !original_file_url.blank?
      File.basename(URI.parse(original_file_url).path || '')
    end || ''
    fn
  end

  def url(*args)
    file.try(:url, *args) || original_file_url
  end

  def transcoded?
    !transcoded_at.nil?
  end

  def urls
    if transcoded?
      AudioFileUploader.version_formats.keys.collect{|v| url(v)}
    else
      [url]
    end
  end

  def storage
    storage_configuration || item.try(:storage)
  end

  def store_dir(stor=storage)
    stor.use_folders? ? "#{item.try(:token)}/#{path}" : nil
  end

  def remote_file_url=(url)
    self.original_file_url = url
    self.should_trigger_fixer_copy = !!url
  end

  def upload_to
    storage.direct_upload? ? storage : item.upload_to
  end

  def update_file!(name, sid)
    sid = sid.to_i
    file_will_change!
    raw_write_attribute(:file, name)
    if (sid > 0) && (self.storage.id != sid)
      # see if the item is right
      if item.storage.id == sid
        self.storage_id = nil
        self.storage_configuration = nil
      else
        self.storage_id = sid
        self.storage_configuration = StorageConfiguration.find(sid)
      end
    end

    save!
  end

  def metered?
    metered.nil? ? is_metered? : super
  end


  def update_from_fixer(params)

    # get the status of the fixer task
    result = params['result_details']['status']

    # get the task id from the label
    task = tasks.where(id: params['label']).last
    return unless task

    # logger.debug "update_from_fixer: task #{params['label']} is #{result}"

    # update with the job id
    if !task.extras['job_id'] && params['job'] && params['job']['id']
      task.extras['job_id'] = params['job']['id']
      task.save!
    end

    task.params = params

    case result
    when 'created'    then logger.debug "task #{params['label']} created"
    when 'processing' then task.begin!
    when 'complete'   then task.finish!
    when 'error'      then task.failure!
    else nil
    end

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def process_update_file
    # logger.debug "af #{id} call copy_to_item_storage"
    copy_to_item_storage
  end

  def process_create_file
    # don't process file if no file to process yet (s3 upload)
    return if file.blank? && original_file_url.blank?

    analyze_audio

    copy_original
    
    transcribe_audio

    transcode_audio

  rescue Exception => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def analyze_audio(force=false)
    if !force && task = tasks.analyze_audio.without_status(:failed).last
      logger.debug "analyze task #{task.id} already exists for audio_file #{self.id}"
    else
      self.tasks << Tasks::AnalyzeAudioTask.new(extras: { original: process_audio_url })
    end
  end

  def complete_analysis(analysis)
    update_attribute :duration, analysis[:length].to_i
  end

  def copy_original
    return false unless (should_trigger_fixer_copy && item.collection.copy_media && original_file_url)
    create_copy_task(original_file_url, destination, storage)
    self.should_trigger_fixer_copy = false
  end

  def copy_to_item_storage
    # refresh storage related
    audio_file_storage = self.storage_configuration
    item_storage = item(true).storage
    # audio_file_storage = self.storage_configuration
    # item_storage = item.storage
    # puts "\ncopy_to_item_storage: storage(#{audio_file_storage.inspect}) == item.storage(#{item_storage.inspect})\n"
    return false if (!audio_file_storage || (audio_file_storage == item_storage))

    orig = destination
    dest = destination(storage: item_storage)
    # puts "\ncopy_to_item_storage: create task: orig: #{orig}, dest: #{dest}, stor: #{item_storage.inspect}\n"
    create_copy_task(orig, dest, item_storage)
    return true
  end

  def order_transcript(user)
    raise 'cannot create transcript when duration is 0' if (duration.to_i <= 0)
    task = Tasks::OrderTranscriptTask.new(
      identifier: 'order_transcript',
      extras: {
        user_id: user.id,
        amount: amount_for_transcript
      }
    )
    self.tasks << task
    task
  end

  def amount_for_transcript
    (duration.to_i / 60.0).ceil * TRANSCRIBE_RATE_PER_MINUTE
  end

  def add_to_amara(user)
    self.tasks << Tasks::AddToAmaraTask.new(identifier: 'add_to_amara', extras: { user_id: user.id })
  end

  def create_copy_task(orig, dest, stor)
    # see if there is already a copy task
    if task = tasks.copy.where(identifier: dest).last
      logger.debug "copy task #{task.id} already exists for audio_file #{self.id}"
    else
      task = Tasks::CopyTask.new(
        identifier: dest,
        storage_id: stor.id,
        extras: {
          original:    orig,
          destination: dest
        })
      self.tasks << task
    end
    task
  end

  def transcribe_audio
    # see if there is a non-failed task for this audio file
    if task = tasks.transcribe.without_status(:failed).where(identifier: 'ts_start').last
      logger.debug "transcribe task ts_start #{task.id} already exists for audio_file #{self.id}"
    else
      self.tasks << Tasks::TranscribeTask.new(identifier: 'ts_start', extras: { start_only: true, original: process_audio_url })
    end

    if task = tasks.transcribe.without_status(:failed).where(identifier: 'ts_all').last
      logger.debug "transcribe task ts_all #{task.id} already exists for audio_file #{self.id}"
    else
      self.tasks << Tasks::TranscribeTask.new(identifier: 'ts_all', extras: { original: process_audio_url })
    end
  end

  def transcode_audio
    return if transcoded_at

    if storage.automatic_transcode?
      if task = tasks.detect_derivatives.without_status(:failed).where(identifier: 'detect_derivatives').last
        logger.debug "detect_derivatives task #{task.id} already exists for audio_file #{self.id}"
      else
        urls = AudioFileUploader.version_formats.keys.inject({}){|h, k| h[k] = { url: file.send(k).url, detected_at: nil }; h}
        self.tasks << Tasks::DetectDerivativesTask.new(identifier: 'detect_derivatives', extras: { 'urls' => urls })
      end

    else
      AudioFileUploader.version_formats.each do |label, info|
        next if (label == filename_extension) # skip this version if that is alreay the file's format
        self.tasks << Tasks::TranscodeTask.new(identifier: "#{label}_transcode", extras: info)
      end
    end
  end

  def is_transcode_complete?
    return true if storage.automatic_transcode?

    complete = true
    AudioFileUploader.version_formats.each do |label, info|
      next if (label == filename_extension) # skip this version if that is alreay the file's format
      task = tasks.transcode.with_status('complete').where(identifier: "#{label}_transcode").last
      complete = !!task
      break if !complete
    end
    complete
  end

  def check_transcode_complete
    update_attribute(:transcoded_at, DateTime.now) if is_transcode_complete?
  end

  def transcript_array
    timed_transcript_array.present? ? timed_transcript_array : (@_tta ||= JSON.parse(transcript)) rescue []
  end

  def transcript_text
    txt = timed_transcript_text
    txt = JSON.parse(transcript).collect{|i| i['text']}.join("\n") if (txt.blank? && !transcript.blank?)
    txt || ''
  end

  def timed_transcript_text(language='en-US')
    (timed_transcript(language).try(:timed_texts) || []).collect{|tt| tt.text}.join("\n")
  end

  def timed_transcript_array(language='en-US')
    @_timed_transcript_arrays ||= {}
    @_timed_transcript_arrays[language] ||= (timed_transcript(language).try(:timed_texts) || []).collect{|tt| tt.as_json(only: [:id, :start_time, :end_time, :text])}
  end

  def timed_transcript(language='en-US')
    transcripts.detect{|t| t.language == language }
  end

  def process_transcript(json)
    return nil if json.blank?

    identifier = Digest::MD5.hexdigest(json)

    if trans = transcripts.where(identifier: identifier).first
      logger.debug "transcript #{trans.id} already exists for this json: #{json[0,50]}"
      return false
    end

    trans_json = JSON.parse(json) if json.is_a?(String)
    trans = transcripts.build(language: 'en-US', identifier: identifier, start_time: 0, end_time: 0)
    sum = 0.0
    count = 0.0
    trans_json.each do |row|
      tt = trans.timed_texts.build({
        start_time: row['start_time'],
        end_time:   row['end_time'],
        confidence: row['confidence'],
        text:       row['text']
      })
      trans.end_time = tt.end_time if tt.end_time > trans.end_time
      trans.start_time = tt.start_time if tt.start_time < trans.start_time
      sum = sum + tt.confidence.to_f
      count = count + 1.0
    end
    trans.confidence = sum / count if count > 0
    trans.save!

    # delete trans which cover less time
    partials_to_delete = transcripts.where("language = ? AND end_time < ?", trans.language, trans.end_time)
    partials_to_delete.each{|t| t.destroy}

    trans
  end

  def analyze_transcript
    # TODO add dupe check and force
    self.tasks << Tasks::AnalyzeTask.new(extras: { original: transcript_text_url })
  end

  def transcript_text_url
    Rails.application.routes.url_helpers.api_item_audio_file_transcript_text_url(item_id, id)
  end

  def call_back_url
    Rails.application.routes.url_helpers.api_item_audio_file_url(item_id, id)
  end

  def process_audio_url
    if !file.blank?
      if file.fog_credentials[:provider].downcase == 'aws'
        destination
      else
        file.url
      end
    else
      original_file_url
    end
  end

  def destination_options(options={})
    stor = options[:storage] || storage
    dest_opts = options[:options] || {}
    da = stor.attributes || {}
    da.reverse_merge!(dest_opts)

    if stor.provider == 'InternetArchive'
      if Rails.env.production?
        da[:collections] = [] unless da.has_key?(:collections)
        da[:collections] << 'popuparchive' unless da[:collections].include?('popuparchive')
      end

      default_subject = item.try(:collection).try(:title)
      da[:subjects] = [] unless da.has_key?(:subjects)
      da[:subjects] << default_subject unless da[:subjects].include?(default_subject)

      da[:metadata] = {} unless da.has_key?(:metadata)
      da[:metadata]['x-archive-meta-title'] ||= item.try(:title)
      da[:metadata]['x-archive-meta-mediatype'] ||= 'audio'
    end

    da
  end

  def destination_path(options={})
    dir = store_dir(options[:storage] || storage) || ''
    version = options.delete(:version)
    File.join("/", dir, filename(version))
  end

  def destination_directory(options={})
    stor = options[:storage] || storage
    stor.use_folders? ? stor.bucket : item.token
  end

  def destination(options={})
    stor = options[:storage] || storage
    suffix = options[:suffix] || ''
  
    scheme = case stor.provider.downcase
    when 'aws' then 's3'
    when 'internetarchive' then 'ia'
    else 's3'
    end

    opts = destination_options(options)
    query = opts.inject({}){|h, p| h["x-fixer-#{p[0]}"] = p[1]; h}.to_query if !opts.blank?

    host = destination_directory(options)
    path = destination_path(options) + suffix

    # logger.debug("audio_file: destination: scheme: #{scheme}, host:#{host}, path:#{path}")
    uri = URI::Generic.build scheme: scheme, host: host, path: path, query: query
    if scheme == 'ia'
      uri.user = stor.key
      uri.password = stor.secret
    end
    uri.to_s
  end

  private

  def set_metered
    self.metered = is_metered?
    true
  end

  def is_metered?
    storage == StorageConfiguration.popup_storage
  end
end
