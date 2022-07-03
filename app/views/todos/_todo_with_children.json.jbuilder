depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.children do
  if depth < 5
    json.array! todo.children.order(created_at: :desc), partial: 'todos/todo_with_children', as: :todo, locals: { depth: depth + 1, todos: todos }
  end
end