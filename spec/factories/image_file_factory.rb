FactoryGirl.define do 
  factory :image_file do 
    association :item, factory: :item

  	file "test.jpg"
  	is_uploaded true
    upload_id 1	
    # url "http://popuparchive.dev/items/1/image_files/1"
  end
end