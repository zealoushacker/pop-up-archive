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

  def serialize_results
    self.serialize_extra('results')
  end

  def set_task_defaults
    self.extras = {} unless extras
    self.storage_id = owner.storage.id if (!storage_id && owner && owner.storage)
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
    self.extras = {} unless extras
    self.extras[name] = self.extras[name].to_json if (self.extras[name] && !self.extras[name].is_a?(String))
  end

  def deserialize_extra(name, default={})
    return nil unless self.extras
    if self.extras[name].is_a?(String)
      self.extras[name] = JSON.parse(self.extras[name])
    end

    self.extras[name] ||= default if default

    self.extras[name]    
  end

  def results
    HashWithIndifferentAccess.new(deserialize_extra('results', {}))
  end

  def results=(rs)
    self.extras = {} unless extras
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
