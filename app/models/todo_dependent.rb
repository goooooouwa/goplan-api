class TodoDependent < ApplicationRecord
  belongs_to :todo, optional: true
  belongs_to :dependent, class_name: 'Todo', optional: true
  validates_uniqueness_of :dependent_id, :scope => :todo_id
  validates_uniqueness_of :todo_id, :scope => :dependent_id
  validate :todo_dependent_cannot_include_self, unless: -> { dependent_id.nil? || todo_id.nil?  }
  validate :todo_cannot_be_dependent_dependencies_dependency, unless: -> { dependent_id.nil? || todo_id.nil?  }
  validate :dependent_cannot_be_dependents_dependent, unless: -> { dependent_id.nil? || todo_id.nil?  }

  private
  
  def todo_dependent_cannot_include_self
    errors.add(:dependent_id, "can't add self as dependency / dependent") if dependent_id == todo_id
  end

  def todo_cannot_be_dependent_dependencies_dependency
    deps_dependencies = dependent.dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    intersection = deps_dependencies.filter { |deps_dependency| todo_id == deps_dependency.id }
    errors.add(:todo_id, "can't add dependencies' dependency") if intersection.present?
  end

  def dependent_cannot_be_dependents_dependent
    depts_dependents = todo.dependents.map { |dependent| dependent.dependents }.flatten.uniq
    intersection = depts_dependents.filter { |depts_dependent| dependent_id == depts_dependent.id }
    errors.add(:dependent_id, "can't add dependents' dependent") if intersection.present?
  end
end
