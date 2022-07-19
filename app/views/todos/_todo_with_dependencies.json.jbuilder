depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.dependencies do
  if depth < 5
    json.array! todo.dependencies.undone.reorder(created_at: :desc).filter{ |dependency| todo.first_appearance_of_dependency_in_todos?(dependency, todos) }, partial: 'todos/todo_with_dependencies', as: :todo, locals: { depth: depth + 1, todos: todos }
  end
end