require "digest/sha1"

class Api::V1::ImageFilesController < Api::V1::BaseController

  expose :item
  expose :image_files, ancestor: :item
  expose :image_file
  expose :upload_to_storage
  expose :original_file_url 
  def create
    image_file.save
    respond_with :api, image_file.item, image_file
  end

  def show
    redirect_to item.url
  end

  def destroy
    image_file.destroy
    respond_with :api, image_file
  end

  def upload_to
    respond_with :api
  end

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
    image_file = ImageFile.find(params[:image_file_id])
    image_file.update_attribute(:upload_id, params[:upload_id])

    render json: all_signatures_hash
  end

  def chunk_loaded
    render json: {}
  end

  def upload_finished
    image_file = ImageFile.find(params[:image_file_id])
    file_name = File.basename(params[:key])
    image_file.file_uploaded(file_name)    
    render json: {}
  end

end
