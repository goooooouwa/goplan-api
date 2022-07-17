FactoryBot.define do
  factory :todo, aliases: %i[dependent dependencies] do
    project
    name { Faker::Lorem.sentence }
    start_date { Faker::Time.between(from: Time.current - 1, to: Time.current) }
    end_date { Faker::Time.between(from: start_date + 9.days, to: start_date + 10.days) }

    factory :todo_with_full_info do
      description { Faker::Lorem.sentence }
      time_span { Faker::Number.number(digits: 5) }
      instance_time_span { Faker::Number.number(digits: 5) }
      repeat { Faker::Boolean.boolean }
      repeat_period { 'week' }
      repeat_times { Faker::Number.number(digits: 5) }
      status { Faker::Boolean.boolean }
    end

    factory :todo_with_end_date_earlier_than_start_date do
      start_date { Faker::Time.between(from: Time.current - 1, to: Time.current) }
      end_date { Faker::Time.between(from: start_date - 10.days, to: start_date - 1.days) }
    end

    factory :todo_with_very_early_start_date do
      start_date { Time.zone.local(1979, 1, 1, 0, 0) }
    end

    factory :todo_with_very_late_end_date do
      end_date { Time.zone.local(3000, 1, 1, 0, 0) }
    end

    factory :todo_with_past_start_date_and_future_end_date do
      start_date { Faker::Time.between(from: Time.current - 2.days, to: Time.current - 1.days) }
      end_date { Faker::Time.between(from: Time.current + 14.days, to: Time.current + 15.days) }
    end

    factory :todo_with_slightly_later_start_date_and_end_date do
      start_date { Faker::Time.between(from: Time.current + 1.days, to: Time.current + 2.days) }
      end_date { Faker::Time.between(from: Time.current + 10.days, to: Time.current + 11.days) }
    end

    factory :todo_with_past_start_and_end_date do
      start_date { Faker::Time.between(from: Time.current - 12.days, to: Time.current - 11.days) }
      end_date { Faker::Time.between(from: Time.current - 2.days, to: Time.current - 1.days) }
    end

    factory :todo_with_future_start_and_end_date do
      start_date { Faker::Time.between(from: Time.current + 11.days, to: Time.current + 12.days) }
      end_date { Faker::Time.between(from: Time.current + 21.days, to: Time.current + 22.days) }
    end

    factory :todo_with_distant_start_and_end_date do
      start_date { Time.zone.local(3000, 1, 1, 0, 0) }
      end_date { Time.zone.local(3000, 1, 2, 0, 0) }
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
