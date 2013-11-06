class AddCacheColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pop_up_hours_cache, :integer
    add_column :users, :used_metered_storage_cache, :integer
  end
end
