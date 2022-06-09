FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    password_confirmation { password }

    factory :user_with_full_info do
      reset_password_token { Faker::Lorem.sentence }
      reset_password_sent_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
      remember_created_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
      provider { Faker::Lorem.sentence }
      uid { Faker::Lorem.sentence }
      name { Faker::Lorem.sentence }
      image_url { Faker::Lorem.sentence }
    end
  end
end

def user_with_projects(projects_count: 5)
  FactoryBot.create(:user) do |user|
    FactoryBot.create_list(:project, projects_count, user: user)
  end
end
