FactoryGirl.define do
  factory :game do
    active true

    trait :with_users do
      transient do
        user_count 0
      end

      users { (1..user_count).map { FactoryGirl.create(:user) } }
    end
  end
end
