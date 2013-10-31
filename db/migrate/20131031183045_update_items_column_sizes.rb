class UpdateItemsColumnSizes < ActiveRecord::Migration
  def up
    change_column :items, :title, :text
    change_column :items, :episode_title, :text
    change_column :items, :series_title, :text
    change_column :items, :identifier, :text
    change_column :items, :rights, :text
    change_column :items, :physical_format, :text
    change_column :items, :digital_format, :text
    change_column :items, :physical_location, :text
    change_column :items, :digital_location, :text
    change_column :items, :music_sound_used, :text
    change_column :items, :date_peg, :text
  end

  def down
    change_column :items, :title, :string
    change_column :items, :episode_title, :string
    change_column :items, :series_title, :string
    change_column :items, :identifier, :string
    change_column :items, :rights, :string
    change_column :items, :physical_format, :string
    change_column :items, :digital_format, :string
    change_column :items, :physical_location, :string
    change_column :items, :digital_location, :string
    change_column :items, :music_sound_used, :string
    change_column :items, :date_peg, :string
  end
end
