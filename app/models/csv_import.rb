# encoding: utf-8

require 'csv'

class CsvImport < ActiveRecord::Base

  STATES = ["new", "queued_analyze", "analyzing", "analyzed", "queued_import", "importing", "imported", "cancelled", "error"]

  attr_accessible :file, :mappings_attributes, :collection_id, :commit
  before_save :set_file_name, on: :create
  if Rails.env.test?
    after_save :enqueue_processing, if: :processing_required?
  else
    after_commit :enqueue_processing, if: :processing_required?
  end
  validates_presence_of :file
  mount_uploader :file, ::CsvFileUploader

  has_many :rows, class_name: 'CsvRow', dependent: :destroy
  has_many :items, dependent: :destroy

  has_many :mappings, order: "position", class_name:'ImportMapping', dependent: :destroy do
    def [](index)
      conditions(['import_mappings.position = ?', index - 1]).limit(1).first
    end
  end
  accepts_nested_attributes_for :mappings

  default_scope order('state_index ASC, created_at ASC')

  belongs_to :collection
  belongs_to :user
  attr_accessor :commit

  def state
    STATES[state_index]
  end

  def collection_with_build
    if collection_id == 0
      self.collection = Collection.new(title: file_name, creator: user)
    elsif collection_id == -1
      self.collection = Collection.new(title: file_name, creator: user, items_visible_by_default: true)
    elsif collection_id == -2
      self.collection = Collection.new(title: file_name, creator: user, items_visible_by_default: true, storage:'InternetArchive')
    else
      collection
    end
  end

  def analyze!
    raise "Invalid state for analysis: #{state}" if %w(new analyzing).include? state
    self.state = "analyzing"
    file.cache!
    CSV.foreach(file.path) do |row|
      if self.headers.present?
        rows.create values: row
      else
        analyze_headers! row
      end
    end
    self.state = "analyzed"
  end

  def import!
    raise "Invalid state for import: #{state}" unless %(queued_import).include? state
    current_mappings = mappings
    self.state = "importing"
    transaction do
      collection = collection_with_build
      collection.save
      rows.find_each do |csv_row|
        logger.debug "processing row: #{csv_row.inspect}"
        data = csv_row.values
        item = items.build do |item|
          item.collection_id = collection.id
          current_mappings.each do |mapping|
            index = mapping.position - 1
            mapping.apply(data[index], item)
          end
        end

        # need to record user who uploads each audio file for notifications
        item.audio_files.each{|af| af.user_id = self.user_id}

        item.save
      end

      # I suspect these two lines are unnecessary, b/c of Collection#grant_to_creator
      user.collections << collection unless user.collections.include? collection
      user.save

      self.collection_id = collection.id
      self.state = "imported"
    end
  end

  def error!(exception=nil)
    self.error_message = exception.message
    self.backtrace     = exception.backtrace
    self.state         = "error"
  end

  def processing_required?
    state == 'new' || commit.present?
  end

  def process!
    case state
    when "queued_analyze" then analyze!
    when "queued_import"  then import!
    end
  end

  alias_method :mappings_attributes_set, :mappings_attributes=
  def mappings_attributes=(values)
    mappings.delete_all
    self.mappings_attributes_set values
  end

  def reset!
    CsvImport.transaction do
      self.state = 'new'
      self.headers = nil
      save!
      mappings.delete_all
      rows.delete_all
    end
  end

  private

  def state=(state)
    raise "Invalid state: #{state}" unless new_state_index = STATES.index(state.downcase)
    update_attribute :state_index, new_state_index
  end

  def enqueue_processing
    type_of_processing = (commit || 'analyze')
    if type_of_processing == 'cancel'
      self.commit = nil
      self.state = 'cancelled'
    else
      self.commit = nil
      self.state = "queued_#{type_of_processing}"
      CsvImportWorker.perform_async(id) unless Rails.env.test?
    end
  end

  def set_file_name
    self.file_name = File.basename(file.path)
  end

  def analyze_headers!(headers)
    self.headers = headers
    mappings.delete_all

    headers.each_with_index do |header, index|
      header = header.blank? ? "Field #{index}" : header.downcase
      column, type = case header
      when /item id|identifier/ then ["identifier", "string"]
      when /episode/ then ['episode_title', 'string']
      when /series/ then ['series_title', 'string']
      when /piece|title/ then ["title", "string"]
      when /duration/ then ["duration", "number"]
      when /url|digital loc|audio/ then ["audio_files[][remote_file_url]", "array"]
      when /broadcast/ then ['date_broadcast', 'date']
      when /date/ then ["date_created", "date"]
      when /creator/ then ['creators[]', 'person']
      when /host/ then ['hosts[]', 'person']
      when /interviewer/ then ["interviewers[]", 'person']
      when /interviewee/ then ["interviewees[]", "person"]      
      when /producer/ then ['producers[]', 'person']
      when /guest/ then ['guests[]', 'person']
      when /description/ then ['description', 'text']
      when /rights/ then ['rights', 'text']
      when /phy(.*)format/ then ['physical_format', 'short_text']
      when /dig(.*)format/ then ['digital_format', 'short_text']
      when /digital|f(.*)m(.*)t(.*)/ then ['digital_format', 'short_text']
      when /phy(.*)location|hardcopy/ then ['physical_location', 'short_text']
      when /(music|sound)(.*)used|music/ then ['music_sound_used', 'short_text']
      when /date(.*)peg/ then ['date_peg', 'short_text']
      when /tags/ then ['tags', 'array']
      when /geo|location/ then ['geographic_location', 'geolocation']
      when /notes/ then ['notes', 'text']
      else [make_column_name(header), "*"]
      end

      mappings.create(type:type, column:column) do |mapping|
        mapping.position = index + 1
      end
    end
  end

  def make_column_name(name)
    "extra[#{name.downcase.gsub(/\W+/,'_')}]"
  end                                  
end
