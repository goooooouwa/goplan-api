class Todo < ApplicationRecord
  belongs_to :project

  has_many :todo_dependents, class_name: 'TodoChild',
                               foreign_key: 'todo_id',
                               dependent: :destroy

  has_many :todo_dependencies, class_name: 'TodoChild',
                             foreign_key: 'child_id',
                             dependent: :destroy

  has_many :dependents, through: :todo_dependents, source: :child
  has_many :dependencies, through: :todo_dependencies, source: :todo

  accepts_nested_attributes_for :todo_dependents, :todo_dependencies
end
