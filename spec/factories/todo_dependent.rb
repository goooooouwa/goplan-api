FactoryBot.define do
  factory :todo_dependency, class: "TodoChild" do
    todo
    child { association :todo }
  end
end
