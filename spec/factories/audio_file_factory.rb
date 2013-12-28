FactoryGirl.define do
  factory :audio_file do

    association :item, factory: :item
    association :user, factory: :user

    duration 60

    factory :audio_file_private do
      association :item, factory: :item_private
    end

    factory :audio_file_no_copy_media do
      association :item, factory: :item_no_copy_media
    end

    after(:create) { |af| af.update_file!('test.mp3', 0) if af.copy_media? }

  end
end
