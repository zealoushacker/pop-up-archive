FactoryGirl.define do
  factory :collection do

    title "test collection"
    items_visible_by_default true
    association :default_storage, factory: :storage_configuration_popup
  
    factory :collection_public do
      items_visible_by_default true
      association :default_storage, factory: :storage_configuration_archive
      association :upload_storage, factory: :storage_configuration_popup
    end

    factory :collection_private do
      items_visible_by_default false
      association :default_storage, factory: :storage_configuration_popup
    end
    
  end
end