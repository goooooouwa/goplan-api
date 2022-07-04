class CreateTodos < ActiveRecord::Migration[6.1]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.float :time_span, null: false, default: 1
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.boolean :repeat, null: false, default: false
      t.string :repeat_period, null: false, default: "week"
      t.integer :repeat_times, null: false, default: 1
      t.integer :instance_time_span, null: false, default: 1

      t.timestamps
    end
  end
end
