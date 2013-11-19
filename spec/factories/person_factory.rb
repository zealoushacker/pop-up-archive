FactoryGirl.define do
  factory :person do

    name "person"

    after(:create) do |person, evaluator|
      FactoryGirl.create_list(:contribution, 1, person: person)
    end

  end
end