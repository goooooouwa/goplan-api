json.array! @todos.parentless.undone.includes_associations.reorder(created_at: :desc) + @todos.parentless.done.includes_associations.reorder(updated_at: :desc), partial: 'todos/todo', as: :todo