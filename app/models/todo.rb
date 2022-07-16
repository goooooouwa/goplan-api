class Todo < ApplicationRecord
  belongs_to :project
  delegate :user, to: :project, allow_nil: true

  has_many :todo_dependents, class_name: 'TodoDependent',
                             foreign_key: 'todo_id',
                             dependent: :destroy

  has_many :todo_dependencies, class_name: 'TodoDependent',
                               foreign_key: 'dependent_id',
                               dependent: :destroy

  has_many :dependents, through: :todo_dependents, source: :dependent
  has_many :dependencies, through: :todo_dependencies, source: :todo

  accepts_nested_attributes_for :todo_dependents, :todo_dependencies, :dependencies, :dependents, allow_destroy: true

  has_many :todo_children, class_name: 'TodoChild',
                             foreign_key: 'todo_id',
                             dependent: :destroy

  has_many :todo_parents, class_name: 'TodoChild',
                               foreign_key: 'child_id',
                               dependent: :destroy

  has_many :children, through: :todo_children, source: :child, after_add: :update_as_repeat
  has_many :parents, through: :todo_parents, source: :todo

  accepts_nested_attributes_for :todo_children, :todo_parents, :parents, :children, allow_destroy: true

  scope :of_project, ->(project_id) { where('todos.project_id = ?', project_id) }
  scope :name_contains, lambda { |name|
                          where('lower(todos.name) LIKE ?', '%' + Todo.sanitize_sql_like(name).downcase + '%')
                        }
  scope :has_dependent, ->(dependent_id) { joins(:dependents).where('dependents.id' => dependent_id) }
  scope :has_dependency, ->(dependency_id) { joins(:dependencies).where('dependencies.id' => dependency_id) }
  scope :done, -> { where(status: true) }
  scope :undone, -> { where(status: false) }
  scope :unactionable, -> { left_outer_joins(:dependencies).where(status: false, dependencies: { status: false }) }
  scope :actionable, -> { where.not(id: unactionable) }
  scope :dependentless, -> { left_outer_joins(:dependents).where(dependents: { id: nil }) }
  scope :childless, -> { left_outer_joins(:children).where(children: { id: nil }) }
  scope :parentless, -> { left_outer_joins(:parents).where(parents: { id: nil }) }
  scope :due_date_before, ->(date) { where(status: false).where('end_date <= ?', date) }

  validates_presence_of :name
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_length_of :parents, maximum: 1
  validate :end_date_cannot_earlier_than_start_date
  validate :start_date_cannot_earlier_than_dependencies_end_date
  validate :end_date_cannot_later_than_dependents_start_date, on: :create
  validate :todo_dependencies_cannot_include_self
  validate :todo_dependencies_cannot_include_dependents
  validate :todo_dependencies_cannot_include_deps_dependencies
  validate :todo_dependents_cannot_include_self
  validate :todo_dependents_cannot_include_dependencies
  validate :todo_dependents_cannot_include_depts_dependents
  validate :todo_children_cannot_include_self
  validate :todo_parents_cannot_include_self
  validate :cannot_mark_as_done_if_dependencies_not_done, if: -> { will_save_change_to_attribute?(:status, to: true) }

  after_update :update_dependents_timeline, if: -> { saved_change_to_end_date? }
  after_update :update_children_timeline, if: -> { saved_change_to_start_date? }

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

  def first_appearance_of_dependency_in_todos?(dependency, todos)
    return id == todos.has_dependency(dependency.id).order(:created_at).limit(1).first.try(:id)
  end

  def first_appearance_of_dependent_in_todos?(dependent, todos)
    return id == todos.has_dependent(dependent.id).order(:created_at).limit(1).first.try(:id)
  end

  private

  def end_date_cannot_earlier_than_start_date
    return if [start_date, end_date].any?(&:nil?)
    errors.add(:end_date, "end date can't be earlier than start date") if end_date < start_date
  end

  def todo_dependencies_cannot_include_self
    return unless todo_dependencies.present?

    if todo_dependencies.select do |todo_dependency|
         todo_dependency.todo_id == id
       end.present?
      errors.add(:dependencies, "can't add self as dependency")
    end
  end

  def todo_dependencies_cannot_include_dependents
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    intersection = dependencies.filter { |dependency| dependents.include?(dependency) }
    errors.add(:dependencies, "can't add dependent as dependency") if intersection.present?
  end

  def todo_dependencies_cannot_include_deps_dependencies
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    deps_dependencies = dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    intersection = deps_dependencies.filter { |deps_dependency| dependencies.include?(deps_dependency) }
    errors.add(:dependencies, "can't add dependency's dependencies") if intersection.present?
  end

  def todo_dependents_cannot_include_self
    return unless todo_dependents.present?

    if todo_dependents.select { |todo_dependent| todo_dependent.dependent_id == id }.present?
      errors.add(:dependents, "can't add self as dependent")
    end
  end

  def todo_dependents_cannot_include_dependencies
    return unless todo_dependents.present?

    dependents = Todo.find(todo_dependents.map(&:dependent_id))
    intersection = dependents.filter { |dependent| dependencies.include?(dependent) }
    errors.add(:dependents, "can't add dependency as dependent") if intersection.present?
  end

  def todo_dependents_cannot_include_depts_dependents
    return unless todo_dependents.present?

    dependents = Todo.find(todo_dependents.map(&:dependent_id))
    deps_dependents = dependents.map { |dependent| dependent.dependents }.flatten.uniq
    intersection = deps_dependents.filter { |deps_dependent| dependents.include?(deps_dependent) }
    errors.add(:dependents, "can't add dependent's dependents") if intersection.present?
  end
  
  def cannot_mark_as_done_if_dependencies_not_done
    return unless todo_dependencies.present?

    error_message = "can't mark todo as done since one or more dependencies are still open"
    if Todo.find(todo_dependencies.map(&:todo_id)).select do |dependency|
         dependency.status == false
       end.present?
      errors.add(:status, error_message)
    end
  end

  def todo_children_cannot_include_self
    return unless todo_children.present?

    if todo_children.select { |todo_child| todo_child.child_id == id }.present?
      errors.add(:children, "can't add self as child")
    end
  end

  def todo_parents_cannot_include_self
    return unless todo_parents.present?

    if todo_parents.select { |todo_parent| todo_parent.todo_id == id }.present?
      errors.add(:parents, "can't add self as parent")
    end
  end

  def start_date_cannot_earlier_than_dependencies_end_date
    return unless todo_dependencies.present?

    if start_date < Todo.find(todo_dependencies.map(&:todo_id)).max_by(&:end_date).end_date
      errors.add(:start_date, "start date can't be earlier than dependencies' end date")
    end
  end

  def end_date_cannot_later_than_dependents_start_date
    return unless todo_dependents.present?

    if end_date > Todo.find(todo_dependents.map(&:dependent_id)).min_by(&:start_date).start_date
      errors.add(:end_date, "end date can't be later than dependents' start date")
    end
  end

  def update_dependents_timeline
    delta = end_date - end_date_previously_was
    if (delta.abs / 1.days) > 1
      dependents.each do |dependent|
        latest_dependency = dependent.dependencies.order(end_date: :desc).first
        if id == latest_dependency.id
          dependent.update(start_date: dependent.start_date + delta, end_date: dependent.end_date + delta)
        end
      end
    end
  end

  def update_children_timeline
    delta = start_date - start_date_previously_was
    if (delta.abs / 1.days) > 1 && children.length > 0
      children.each do |child|
        child.update(start_date: child.start_date + delta, end_date: child.end_date + delta)
      end

      latest_child = children.order(end_date: :desc).first
      end_date = latest_child.end_date if end_date < latest_child.end_date
    end
  end

  def update_as_repeat(child)
    update(repeat: true) unless repeat
  end
end
