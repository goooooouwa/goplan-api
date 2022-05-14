class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :goal_name
      t.datetime :target_date

      t.timestamps
    end
  end
end
