json.array! @todos.reorder(:created_at).includes_associations, partial: 'todos/todo', as: :todo