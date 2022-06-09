FactoryBot.define do
  factory :todo_dependent, class: "TodoChild" do
    todo
    child { association :todo }
  end
end
