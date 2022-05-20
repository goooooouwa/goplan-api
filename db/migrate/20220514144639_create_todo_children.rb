class CreateTodoChildren < ActiveRecord::Migration[7.0]
  def change
    create_table :todo_children do |t|
      t.references :todo, null: false, foreign_key: true
      t.references :child, null: false, foreign_key: { to_table: :todos }

      t.timestamps
    end
  end
end
