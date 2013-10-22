FactoryGirl.define do
  factory :storage_configuration do
    initialize_with { StorageConfiguration.popup_storage }

    factory :storage_configuration_archive do
      initialize_with { StorageConfiguration.archive_storage }
    end

    factory :storage_configuration_popup do
      initialize_with { StorageConfiguration.popup_storage }
    end
  end
end
