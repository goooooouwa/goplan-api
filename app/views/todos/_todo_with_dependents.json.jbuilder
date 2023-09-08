depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.dependents do
  if depth > 0
    json.array! todo.dependents.reorder(created_at: :desc).filter{ |dependent| todo.first_appearance_of_dependent_in_todos?(dependent, todos) }, partial: 'todos/todo_with_dependents', as: :todo, locals: { depth: depth - 1, todos: todos }
  else
    json.array! []
  end
end