class EmbedPlayerController < ApplicationController
  def show
    @name=params[:name]
    @file_id=params[:file_id]
    @item_id=params[:item_id]
    @collection_id=params[:collection_id]
    @url=Rails.application.routes.url_helpers.api_item_audio_file_url(@item_id, @file_id)
  end
end

