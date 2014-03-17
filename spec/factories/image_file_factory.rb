FactoryGirl.define do 
  factory :image_file do 
    association :item, factory: :item

    is_uploaded true
    upload_id 1 

    after(:create) { |f|
      f.send(:raw_write_attribute, :file, 'test.jpg')
      f.save!
    }

  end
end