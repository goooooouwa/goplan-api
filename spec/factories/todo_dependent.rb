FactoryBot.define do
  factory :todo_dependency, class: "TodoDependent" do
    todo
    dependent { association :todo }
  end
end
