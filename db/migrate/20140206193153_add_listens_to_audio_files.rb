class AddListensToAudioFiles < ActiveRecord::Migration
  def up
    add_column :audio_files, :play_count, :integer, :null => false, :default => 1
  end

  def down
  	remove_column :audio_files, :play_count, :integer
  end 	
end
