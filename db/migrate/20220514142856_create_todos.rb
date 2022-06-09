class CreateTodos < ActiveRecord::Migration[6.1]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.float :time_span
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.boolean :repeat
      t.string :repeat_period
      t.integer :repeat_times
      t.integer :instance_time_span, null: false

      t.timestamps
    end
  end
end
