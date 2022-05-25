class TodoChild < ApplicationRecord
  belongs_to :todo, optional: true
  belongs_to :child, class_name: 'Todo', optional: true
end
