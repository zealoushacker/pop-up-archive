class AddOriginalFileUrlToImageFiles < ActiveRecord::Migration
  def change
    add_column :image_files, :original_file_url, :string
  end
end
