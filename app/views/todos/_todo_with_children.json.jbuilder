depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
json.dependencies do
  if depth < 1
    json.array! todo.dependencies, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  else
    json.array! []
  end
end
json.dependents do
  if depth < 1
    json.array! todo.dependents, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  else
    json.array! []
  end
end
json.parents do
  if depth < 5
    json.array! todo.parents, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  else
    json.array! []
  end
end
json.children do
  if depth < 5
    json.array! todo.children.order(:created_at), partial: 'todos/todo_with_children', as: :todo, locals: { depth: depth + 1 }
  else
    json.array! []
  end
end