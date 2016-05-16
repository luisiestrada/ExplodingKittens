FactoryGirl.define do
  factory :game do
    active true

    trait :with_users do
      transient do
        user_count 0
      end

      after(:build) do |g, factory|
        (1..factory.user_count).map { g.add_user(FactoryGirl.create(:user)) }
      end
    end
  end
end
