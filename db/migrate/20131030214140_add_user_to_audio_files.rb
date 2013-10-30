class AddUserToAudioFiles < ActiveRecord::Migration
  def change
    add_column :audio_files, :user_id, :integer
  end
end
