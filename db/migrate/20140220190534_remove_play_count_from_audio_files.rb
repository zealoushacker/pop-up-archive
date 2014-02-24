class RemovePlayCountFromAudioFiles < ActiveRecord::Migration
  def up
    remove_column :audio_files, :play_count
  end

  def down
    add_column :audio_files, :play_count, :integer
  end
end
