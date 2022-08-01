FactoryBot.define do
  factory :todo, aliases: %i[dependent dependencies] do
    project
    name { Faker::Lorem.sentence }
    start_date { '2022-01-01' }
    end_date { '2022-01-10' }

    factory :todo_with_full_info do
      description { Faker::Lorem.sentence }
      instance_time_span { Faker::Number.number(digits: 5) }
      repeat { Faker::Boolean.boolean }
      repeat_period { 'week' }
      repeat_times { Faker::Number.number(digits: 5) }
      status { Faker::Boolean.boolean }
    end

    factory :todo_with_end_date_earlier_than_start_date do
      start_date { '2022-01-10' }
      end_date { '2022-01-01' }
    end

    factory :todo_with_very_early_start_date do
      start_date { '1979-01-01' }
    end

    factory :todo_with_very_late_end_date do
      end_date { '3000-01-01' }
    end

    factory :todo_with_past_start_date_and_future_end_date do
      start_date { '2021-12-31' }
      end_date { '2022-01-15' }
    end

    factory :todo_with_slightly_later_start_date_and_end_date do
      start_date { '2022-01-02' }
      end_date { '2022-01-11' }
    end

    factory :todo_with_past_start_and_end_date do
      start_date { '2021-12-21' }
      end_date { '2021-12-31' }
    end

    factory :todo_with_future_start_and_end_date do
      start_date { '2022-01-11' }
      end_date { '2022-01-20' }
    end

    factory :todo_with_distant_start_and_end_date do
      start_date { '3000-01-01' }
      end_date { '3000-01-02' }
    end
  end
end

def todo_with_dependencies_and_dependents(dependencies_count: 5, dependents_count: 5)
  FactoryBot.create(:todo) do |todo|
    created_dependencies = FactoryBot.create_list(:dependency, dependencies_count)
    created_dependencies.each do |dependency|
      FactoryBot.create(:todo_dependency, todo: dependency, dependent: todo)
    end
    created_dependents = FactoryBot.create_list(:dependent, dependents_count)
    created_dependents.each do |dependent|
      FactoryBot.create(:todo_dependent, todo: todo, dependent: dependent)
    end
  end
end

def todo_with_start_date_earlier_than_dependencies_end_date
  FactoryBot.build(:todo_with_very_early_start_date) do |todo|
    created_dependencies = FactoryBot.create_list(:dependencies, 5)
    created_dependencies.each do |dependency|
      FactoryBot.create(:todo_dependency, todo: dependency, dependent: todo)
    end
  end
end

def todo_with_end_date_later_than_dependents_start_date
  FactoryBot.create(:todo_with_very_late_end_date) do |todo|
    created_dependents = FactoryBot.create_list(:dependent, 5)
    created_dependents.each do |dependent|
      FactoryBot.create(:todo_dependent, todo: todo, dependent: dependent)
    end
  end
end
