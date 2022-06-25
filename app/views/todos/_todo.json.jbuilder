depth = 0 if depth.nil?

json.merge! todo.attributes
json.project todo.project, partial: 'projects/project', as: :project
if depth < 1
  json.dependencies do
    json.array! todo.dependencies, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  end
  json.dependents do
    json.array! todo.dependents, partial: 'todos/todo', locals: { depth: depth + 1 }, as: :todo
  end
end