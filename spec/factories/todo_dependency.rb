FactoryBot.define do
  factory :todo_dependent, class: "TodoDependent" do
    todo
    dependent { association :todo }
  end
end
