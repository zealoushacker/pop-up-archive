class Transcript < ActiveRecord::Base
  attr_accessible :language, :audio_file_id, :identifier, :start_time, :end_time, :confidence

  belongs_to :audio_file
  has_many :timed_texts, order: 'start_time ASC'

  default_scope includes(:timed_texts)

  def timed_texts
    super.each do |tt|
      tt.transcript = self
    end
    super
  end

  def set_confidence
    sum = 0.0
    count = 0.0
    self.timed_texts.each{|tt| sum = sum + tt.confidence.to_f; count = count + 1.0}
    if count > 0.0
      average = sum / count
      self.update_attribute(:confidence, average)
    end
    average
  end

  def as_json(options={})
    { sections: timed_texts } 
  end
end
