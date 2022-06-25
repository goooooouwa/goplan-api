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
  if depth < 5
    json.array! todo.dependents, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  else
    json.array! []
  end
end