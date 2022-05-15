json.partial! @project, as: :project
json.todos do
  json.array! @project.todos, partial: 'todos/todo', as: :todo
end
