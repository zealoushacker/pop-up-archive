require "digest/sha1"

class Api::V1::AudioFilesController < Api::V1::BaseController

  expose :item
  expose :audio_files, ancestor: :item
  expose :audio_file
  expose :upload_to_storage
  expose :task

  def update
    if params[:task].present?
      audio_file.update_from_fixer(params[:task])
    else
      audio_file.update_attributes(params[:audio_file])
    end
    respond_with :api, audio_file.item, audio_file
  end

  def create
    if params[:file]
      audio_file.file = params[:file]
    end
    audio_file.save
    respond_with :api, audio_file.item, audio_file
  end

  def show
    redirect_to audio_file.url
  end

  def destroy
    audio_file.destroy
    render :api, audio_file
  end

  def transcript_text
    response.headers['Content-Disposition'] = 'attachment'
    render text: audio_file.transcript_text, content_type: 'text/plain'
  end

  def order_transcript
    authorize! :order_transcript, audio_file
    
    # make call to amara to create the video
    logger.debug "order_transcript for audio_file: #{audio_file}"
    self.task = audio_file.order_transcript(current_user)
    respond_with :api
  end

  def add_to_amara
    # make call to amara to create the video
    logger.debug "add_to_amara audio_file: #{audio_file}"
    self.task = audio_file.add_to_amara(current_user)
    respond_with :api
  end

  def upload_to
    respond_with :api
  end

  def latest_task
    audio_file.tasks.last
  end

  def upload_to_storage
    audio_file.upload_to
  end

  # these are for the request signing
  # really need to see if this is an AWS or IA item/collection
  # and depending on that, use a specific bucket/key
  include S3UploadHandler

  def bucket
    storage[:bucket]
  end

  def secret
    storage[:secret]
  end

  def storage
    upload_to_storage
  end

  def init_signature
    result = nil

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      result = task.extras
    else
      extras = {
        user_id:         current_user.id,
        filename:        params[:filename],
        filesize:        params[:filesize].to_i,
        last_modified:   params[:last_modified],
        key:             params[:key]
      }
      task = audio_file.tasks << Tasks::UploadTask.new(extras: extras)
      result = signature_hash(:init)
    end

    render json: result
  end


  def all_signatures
    task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
    raise "No Task found for id:#{upload_identifier}, #{params}" unless task

    task.extras['num_chunks'] = params['num_chunks'].to_i
    task.extras['upload_id'] = params['upload_id']
    task.status = Task::WORKING
    task.save!

    ash = all_signatures_hash

    render json: ash
  end

  def chunk_loaded
    result = {}

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      task.add_chunk!(params[:chunk])
      result = task.extras
    end

    render json: result
  end

  def upload_finished
    result = {}

    if task = audio_file.tasks.incomplete.upload.where(identifier: upload_identifier).first
      FinishTaskWorker.perform_async(task.id)
      result = task.extras
    end

    render json: result
  end

  protected

  def upload_identifier(options=nil)
    o = options || {
      user_id:       current_user.id,
      filename:      params[:filename],
      filesize:      params[:filesize],
      last_modified: params[:last_modified]
    }
    Tasks::UploadTask.make_identifier(o)
  end

end
