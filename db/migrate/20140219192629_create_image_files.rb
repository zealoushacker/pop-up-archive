class CreateImageFiles < ActiveRecord::Migration
  def change
    create_table :image_files do |t|
      t.integer :item_id
      t.string :file
      t.boolean :is_uploaded
      t.string :upload_id

      t.timestamps
    end
  end
end
