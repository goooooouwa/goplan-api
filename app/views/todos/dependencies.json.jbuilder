json.array! @todos.childless.undone.order(created_at: :desc) + @todos.done.order(updated_at: :desc), partial: 'todos/todo_with_dependencies', as: :todo, locals: { depth: 0, todos: @todos.undone}