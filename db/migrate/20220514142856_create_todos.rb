class CreateTodos < ActiveRecord::Migration[6.1]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.float :time_span, null: false, default: 0
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.boolean :repeat, null: false, default: false
      t.string :repeat_period, null: false, default: ""
      t.integer :repeat_times, null: false, default: 0
      t.integer :instance_time_span, null: false, default: 0

      t.timestamps
    end
  end
end
