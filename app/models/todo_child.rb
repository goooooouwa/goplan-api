class TodoChild < ApplicationRecord
  belongs_to :todo, optional: true
  belongs_to :child, class_name: 'Todo', optional: true
  validates_uniqueness_of :child_id, :scope => :todo_id
end
