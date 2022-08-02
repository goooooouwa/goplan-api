class AddColorToTodos < ActiveRecord::Migration[6.1]
  def change
    add_column :todos, :color, :string, null: false, default: ""
  end
end
