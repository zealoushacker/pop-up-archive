require 'utils'

class Task < ActiveRecord::Base
  serialize :extras, HstoreCoder

  attr_accessible :name, :extras, :owner_id, :owner_type, :status, :identifier, :type, :storage_id, :owner, :storage
  belongs_to :owner, polymorphic: true
  belongs_to :storage, class_name: "StorageConfiguration", foreign_key: :storage_id

  CREATED  = 'created'
  WORKING  = 'working'
  FAILED   = 'failed'
  COMPLETE = 'complete'

  scope :incomplete, where('status != ?', COMPLETE)

  # convenient scopes for subclass types
  [:analyze_audio, :analyze, :copy, :detect_derivatives, :order_transcript, :transcode, :transcribe, :upload].each do |task_subclass|
    scope task_subclass, where('type = ?', "Tasks::#{task_subclass.to_s.camelize}Task")
  end

  # we need to retain the storage used to kick off the process
  before_validation :set_task_defaults, on: :create

  before_save :serialize_results

  state_machine :status, initial: :created do

    state :created,  value: CREATED
    state :working,  value: WORKING
    state :failed,   value: FAILED
    state :complete, value: COMPLETE

    event :begin do
      transition all - [:working] => :working
    end

    event :finish do
      transition  all - [:complete] => :complete
    end

    event :failure do
      transition  all - [:failed] => :failed
    end

    after_transition any => :complete do |task, transition|
      task.finish_task
    end
  end

  def update_from_fixer(params)

    # enforce this later
    # return false unless params['cbt'] == self.call_back_token

    # logger.debug "update_from_fixer: task #{params['label']} is #{result}"

    # update with the job id
    if !extras['job_id'] && params['job'] && params['job']['id']
      self.extras['job_id'] = params['job']['id']
      save!
    end

    # get the status of the fixer task
    result = params['result_details']['status']

    case result
    when 'created'
      logger.debug "task #{params['label']} created"
    when 'processing'
      begin!
    when 'complete'
      self.results = params['result_details']
      save!
      FinishTaskWorker.perform_async(id) unless Rails.env.test?
    when 'error'
      failure!
    when 'retrying'
      logger.debug "task #{params['label']} retrying"
    else
      logger.error "task #{params['label']} unrecognized result: #{result}"
    end
    true
  end

  def serialize_results
    self.serialize_extra('results')
  end

  def set_task_defaults
    self.extras        = HashWithIndifferentAccess.new unless extras
    self.storage_id    = owner.storage.id if (!storage_id && owner && owner.storage)
    self.extras['cbt'] = self.extras['cbt'] || SecureRandom.hex(8)
  end

  def call_back_token
    self.extras['cbt']
  end

  def original
    extras['original'] || owner.try(:process_file_url)
  end

  def call_back_url
    url = extras['call_back_url'] || owner.try(:call_back_url)
    if call_back_token
      uri = URI.parse(url)
      p = Rack::Utils.parse_nested_query(uri.query)
      uri.query = p.merge({:cbt => call_back_token}).to_query
      url = uri.to_s
    end
    url
  end

  def finish_task
  end

  def shared_attributes
    []
  end

  def type_name
    tn = self.class.name.demodulize.sub(/Task$/, '').underscore
    tn.blank? ? 'task' : tn
  end

  def serialize_extra(name)
    self.extras = HashWithIndifferentAccess.new unless extras
    self.extras[name] = self.extras[name].to_json if (self.extras[name] && !self.extras[name].is_a?(String))
  end

  def deserialize_extra(name, default=HashWithIndifferentAccess.new)
    return nil unless self.extras
    if self.extras[name].is_a?(String)
      self.extras[name] = HashWithIndifferentAccess.new(JSON.parse(self.extras[name]))
    end

    self.extras[name] ||= default if default

    self.extras[name]    
  end

  def results
    deserialize_extra('results', HashWithIndifferentAccess.new)
  end

  def results=(rs)
    self.extras = HashWithIndifferentAccess.new unless extras
    self.extras['results'] = HashWithIndifferentAccess.new(rs)
  end

  def download_file(connection, uri)
    Utils.download_private_file(connection, uri)
  end

  def create_job
    return 1 if Rails.env.test?

    job_id = nil

    # puts "\n\ntranscode job: " + Thread.current.backtrace.join("\n")

    begin
      new_job = MediaMonsterClient.create_job do |job|
        yield job
      end
      
      logger.debug("create_job: created: #{new_job.inspect}")
      job_id = new_job.id

    rescue Object=>exception
      logger.error "create_job: error: #{exception.class.name}: #{exception.message}\n\t#{exception.backtrace.join("\n\t")}"
      job_id = 1
    end
    job_id
  end

end
