require "digest/sha1"

class Api::V1::ImageFilesController < Api::V1::BaseController

  expose :item
  expose :image_files, ancestor: :item
  expose :image_file
  expose :upload_to_storage

  # def update
  #   if params[:task].present?
  #     image_file.update_from_fixer(params[:task])
  #   else
  #     image_file.update_attributes(params[:image_file])
  #   end
  #   respond_with :api, image_file.item, image_file
  # end

  def create
    if params[:file]
      image_file.file = params[:file]
    end
    image_file.save
    respond_with :api, image_file.item, image_file
  end

  def show
    redirect_to image_file.url
  end

  def destroy
    image_file.destroy
    respond_with :api, image_file
  end

  # def transcript_text
  #   response.headers['Content-Disposition'] = 'attachment'
  #   render text: image_file.transcript_text, content_type: 'text/plain'
  # end

  # def order_transcript
  #   authorize! :order_transcript, image_file
    
  #   # make call to amara to create the video
  #   logger.debug "order_transcript for image_file: #{image_file}"
  #   self.task = image_file.order_transcript(current_user)
  #   respond_with :api
  # end

  # def add_to_amara
  #   authorize! :add_to_amara, image_file

  #   # make call to amara to create the video
  #   logger.debug "add_to_amara image_file: #{image_file}"
  #   self.task = image_file.add_to_amara(current_user)
  #   respond_with :api
  # end

  def upload_to
    respond_with :api
  end

  # def latest_task
  #   image_file.tasks.last
  # end

  def upload_to_storage
    image_file.upload_to
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

  def all_signatures
    image_file = ImageFile.find(params[:id])
    image_file.update_attribute(:upload_id, params[:upload_id])

    render json: all_signatures_hash
  end

  def chunk_loaded
    render json: {}
  end

  def upload_finished
    image_file = ImageFile.find(params[:id])
    image_file.update_attribute(:is_uploaded, true)
    render json: {}
  end

end
