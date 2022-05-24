class TodoChild < ApplicationRecord
  belongs_to :todo
  belongs_to :child, class_name: 'Todo'
  validates :todo_id, presence: true
  validates :child_id, presence: true
end
