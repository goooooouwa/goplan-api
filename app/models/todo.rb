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

  accepts_nested_attributes_for :todo_dependents, :todo_dependencies, :dependencies, :dependents

  scope :of_project, ->(project_id) { where('project_id = ?', project_id) }
  scope :name_contains, ->(name) { where('lower(name) LIKE ?', '%' + Todo.sanitize_sql_like(name).downcase + '%') }
  scope :due_date_before, ->(date) { where(status: false).where("end_date <= ?", date) }

  validate :todo_dependencies_cannot_include_self
  validate :todo_dependents_cannot_include_self

  def self.search(query)
    scopes = []
    scopes.push([:of_project, query[:project_id]]) if query.try(:[], :project_id)
    scopes.push([:name_contains, query[:name]]) if query.try(:[], :name)

    if scopes.empty?
      all
    else
      send_chain(scopes)
    end
  end

  def self.send_chain(scopes)
    Array(scopes).inject(self) { |o, a| o.send(*a) }
  end

  after_update :update_end_date, if: Proc.new { |todo| todo.saved_change_to_attribute?(:status) }
  after_update :update_dependents_timeline, if: Proc.new { |todo| todo.saved_change_to_attribute?(:end_date) }

  private
  def todo_dependencies_cannot_include_self
    if todo_dependencies.present? && todo_dependencies.select { |todo_dependency| todo_dependency.todo_id == id }.present?
      errors.add(:dependencies, "can't include self")
    end
  end

  def todo_dependents_cannot_include_self
    if todo_dependents.present? && todo_dependents.select { |todo_dependent| todo_dependent.child_id == id }.present?
      errors.add(:dependents, "can't include self")
    end
  end

  def update_end_date
    update(end_date: Time.current)
  end

  def update_dependents_timeline
    delta = end_date - end_date_previously_was
    dependents.each do |dependent|
      dependent.update(start_date: dependent.start_date + delta, end_date: dependent.end_date + delta)
    end
  end
end
