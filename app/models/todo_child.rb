class TodoChild < ApplicationRecord
  belongs_to :todo
  belongs_to :child, class_name: 'Todo'
end
