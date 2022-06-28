depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.dependencies do
  if depth < 1
    json.array! todo.dependencies, partial: 'todos/todo', as: :todo
  end
end
json.dependents do
  if depth < 5
    json.array! todo.dependents.filter{ |dependent| todo.first_appearance_of_dependent_in_todos?(dependent, todos) }, partial: 'todos/todo_with_deps', as: :todo, locals: { depth: depth + 1, todos: todos }
  end
end