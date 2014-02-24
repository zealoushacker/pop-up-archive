class AddListensToAudioFiles < ActiveRecord::Migration
  def up
    add_column :audio_files, :listens, :integer, :null => false, :default => 0
  end

  def down 
  	remove_column :audio_files, :listens
  end	
end
