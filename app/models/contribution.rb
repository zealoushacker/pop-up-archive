class Contribution < ActiveRecord::Base
  belongs_to :person
  belongs_to :item
  attr_accessible :role, :person, :item, :person_id

  after_save :update_item

  def update_item
    item.update_index_async if item
  end

end
