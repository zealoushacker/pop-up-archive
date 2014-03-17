class AddStorageIdToImageFiles < ActiveRecord::Migration
  def change
    add_column :image_files, :storage_id, :string
  end
end
