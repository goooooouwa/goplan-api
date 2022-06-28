class TodoChild < ApplicationRecord
  belongs_to :todo, optional: true
  belongs_to :child, class_name: 'Todo', optional: true
  validates_uniqueness_of :child_id, :scope => :todo_id
  validates_uniqueness_of :todo_id, :scope => :child_id
  validate :todo_child_cannot_include_self
  validate :todo_cannot_be_child_dependencies_dependency
  validate :child_cannot_be_dependents_dependent

  private
  
  def todo_child_cannot_include_self
    errors.add(:child_id, "can't add self as dependency / dependent") if child_id == todo_id
  end

  def todo_cannot_be_child_dependencies_dependency
    deps_dependencies = child.dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    intersection = deps_dependencies.filter { |deps_dependency| todo_id == deps_dependency.id }
    errors.add(:todo_id, "can't add dependencies' dependency") if intersection.present?
  end

  def child_cannot_be_dependents_dependent
    depts_dependents = todo.dependents.map { |dependent| dependent.dependents }.flatten.uniq
    intersection = depts_dependents.filter { |depts_dependent| child_id == depts_dependent.id }
    errors.add(:child_id, "can't add dependents' dependent") if intersection.present?
  end
end
