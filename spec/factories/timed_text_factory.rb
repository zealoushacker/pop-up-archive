FactoryGirl.define do
  factory :timed_text do

    transcript

    sequence(:start_time) {|t| (t - 1) * 5}
    sequence(:end_time) {|t| (t * 5) - 1}

    text 'this is some transcript text'

    confidence 0.8
  end
end

