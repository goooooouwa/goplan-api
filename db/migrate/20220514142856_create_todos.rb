class CreateTodos < ActiveRecord::Migration[7.0]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.float :time_span
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :repeat
      t.string :repeat_period
      t.integer :repeat_times
      t.integer :instance_time_span

      t.timestamps
    end
  end
end
