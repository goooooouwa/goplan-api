class CreateTodoDependents < ActiveRecord::Migration[6.1]
  def change
    create_table :todo_dependents do |t|
      t.references :todo, null: false, foreign_key: true
      t.references :dependent, null: false, foreign_key: { to_table: :todos }

      t.timestamps
    end
  end
end
