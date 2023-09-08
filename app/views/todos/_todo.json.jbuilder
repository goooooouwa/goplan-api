depth = 0 if depth.nil?

json.(todo, :id, :project_id, :name, :description, :color, :start_date, :end_date, :repeat, :repeat_period, :repeat_times, :instance_time_span, :created_at, :updated_at, :status)
json.project todo.project, partial: 'projects/project', as: :project
json.number_of_dependencies todo.dependencies.length
json.number_of_dependents todo.dependents.length
json.number_of_parents todo.parents.length
json.number_of_children todo.children.length
json.depth depth
json.dependencies do
  if depth > 0
    json.array! todo.dependencies, partial: 'todos/todo', locals: { depth: depth - 1 }, as: :todo
  else
    json.array! []
  end
end
json.dependents do
  if depth > 0
    json.array! todo.dependents, partial: 'todos/todo', locals: { depth: depth - 1 }, as: :todo
  else
    json.array! []
  end
end
json.parents do
  if depth > 0
    json.array! todo.parents, partial: 'todos/todo', locals: { depth: depth - 1 }, as: :todo
  else
    json.array! []
  end
end
json.children do
  if depth > 0
    json.array! todo.children.reorder(:created_at), partial: 'todos/todo', locals: { depth: depth - 1 }, as: :todo
  else
    json.array! []
  end
end
