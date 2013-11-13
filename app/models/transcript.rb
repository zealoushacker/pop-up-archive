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

  # def to_doc(format=:srt)
  #   action_view = ActionView::Base.new(Rails.configuration.paths["app/views"])
  #   action_view.class_eval do 
  #     include Rails.application.routes.url_helpers
  #     include Api::BaseHelper
  #     def protect_against_forgery?; false; end
  #   end

  #   action_view.render(template: 'api/v1/transcripts/show', formats: [format], locals: {transcript: self})
  # end

  def to_srt
    srt = ""
    timed_texts.each_with_index do |tt, index|

      end_time = tt.end_time
      end_mils = '000'

      if (index + 1) < timed_texts.size
        end_time_max = [(timed_texts[index + 1].start_time - 1), 0].max
        end_time = [tt.end_time, end_time_max].min
        end_mils = '999'
      end

      if (index > 0)
        srt += "\r\n" 
      end

      srt += "#{index + 1}\n"
      srt += "#{format_time(tt.start_time)},000 --> #{format_time(end_time)},#{end_mils}\n"
      srt += tt.text + "\n"
    end
    srt
  end

  private

  def format_time(seconds)
    Time.at(seconds).getgm.strftime('%H:%M:%S')
  end

end
