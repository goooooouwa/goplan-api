json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.dependencies do
  json.array! todo.dependencies, partial: 'todos/todo', as: :todo
end
json.dependents do
  json.array! todo.dependents, partial: 'todos/todo', as: :todo
end
