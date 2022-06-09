FactoryBot.define do
  factory :todo, aliases: %i[dependent dependencies] do
    project
    name { Faker::Lorem.sentence }
    start_date { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    end_date { Faker::Time.between(from: start_date, to: start_date + 100.days) }
    instance_time_span { Faker::Number.number(digits: 5) }

    factory :todo_with_full_info do
      description { Faker::Lorem.sentence }
      time_span { Faker::Number.number(digits: 5) }
      repeat { Faker::Boolean.boolean }
      repeat_period { 'week' }
      repeat_times { Faker::Number.number(digits: 5) }
      status { Faker::Boolean.boolean }
    end
  end
end

def todo_with_dependencies_and_dependents(dependencies_count: 5, dependents_count: 5)
  FactoryBot.create(:todo) do |todo|
    created_dependencies = FactoryBot.create_list(:dependency, dependencies_count)
    created_dependencies.each do |dependency|
      FactoryBot.create(:todo_dependency, todo: dependency, child: todo)
    end
    created_dependents = FactoryBot.create_list(:dependent, dependents_count)
    created_dependents.each do |dependent|
      FactoryBot.create(:todo_dependent, todo: todo, child: dependent)
    end
  end
end
