class AddImageToItems < ActiveRecord::Migration
  def up
    add_column :items, :image, :string
  end

  def down 
  	remove_column :items, :image
  end	
end
