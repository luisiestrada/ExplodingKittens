FactoryGirl.define do
  factory :user do
    email     { (0...30).map { ('a'..'z').to_a[rand(26)] }.join + '@test.com' }
    password 'password'
  end
end
