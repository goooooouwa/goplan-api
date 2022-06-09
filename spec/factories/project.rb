FactoryBot.define do
  factory :project do
    user
    name { Faker::Lorem.sentence }

    factory :project_with_full_info do
      target_date { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    end
  end
end

def project_with_todos(todos_count: 5)
  FactoryBot.create(:project) do |project|
    FactoryBot.create_list(:todo, todos_count, project: project)
  end
end
