class RemovePlayCountFromAudioFiles < ActiveRecord::Migration
  def up
    remove_column :audio_files, :play_count
  end

end
