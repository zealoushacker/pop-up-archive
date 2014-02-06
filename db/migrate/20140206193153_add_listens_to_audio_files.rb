class AddListensToAudioFiles < ActiveRecord::Migration
  def change
    add_column :audio_files, :listens, :integer
  end
end
