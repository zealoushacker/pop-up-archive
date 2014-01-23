class EmbedPlayerController < ApplicationController
  def show
    @name=params[:name]
    @file_id=params[:file_id]
    @item_id=params[:item_id]
    @collection_id=params[:collection_id]
    @mp3 = AudioFile.find(params[:file_id]).public_url(extension: :mp3)
    @ogg = AudioFile.find(params[:file_id]).public_url(extension: :ogg)
  end
end


