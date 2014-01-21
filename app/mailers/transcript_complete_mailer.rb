class TranscriptCompleteMailer < ActionMailer::Base
  default from: ENV['EMAIL_USERNAME'], template_path: ['base', 'transcript_complete_mailer']

  def new_auto_transcript(user, audio_file, item)
    @user, @audio_file, @item = user, audio_file, item
    mail(to: @user.email, subject: 'Transcription of audio complete')
  end

  def new_amara_transcript(user, audio_file, item)
    @user, @audio_file, @item = user, audio_file, item
    mail(to: @user.email, subject: 'New transcript for audio')
  end
  
  def new_user_email(user)
  	@user = user
  	mail(to: @user.email, subject: 'Welcome to Pop Up Archive')
  end

end
