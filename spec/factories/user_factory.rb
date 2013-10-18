FactoryGirl.define do
  factory :user do
    name "test"
    sequence(:email) {|n| "email#{n}@example.com" }
    password "foo123"
    sequence(:invitation_token) {|n| "invitation_token_#{n}" }

    factory :organization_user do
      association :organization, factory: :organization
    end
  end
end