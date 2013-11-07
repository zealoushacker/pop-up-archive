FactoryGirl.define do
  factory :transcript do
    ignore do
      timed_texts_count 2
    end

    after(:create) do |transcript, evaluator|
      FactoryGirl.create_list(:timed_text, evaluator.timed_texts_count, transcript: transcript)
    end

  end
end
