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

  has_many :children, through: :todo_children, source: :child, after_add: :update_repeat
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
  validates_associated :children
  validates_associated :dependents
  validate :start_date_cannot_earlier_than_dependencies_end_date
  validate :start_date_cannot_earlier_than_parents_start_date
  validate :end_date_cannot_earlier_than_start_date
  validate :end_date_cannot_later_than_dependents_start_date, on: :create
  validate :end_date_cannot_later_than_parents_end_date, on: :create
  validate :end_date_cannot_earlier_than_children_end_date
  validate :todo_dependencies_cannot_include_self
  validate :todo_dependencies_cannot_include_dependents
  validate :todo_dependencies_cannot_include_deps_dependencies
  validate :todo_dependents_cannot_include_self
  validate :todo_dependents_cannot_include_dependencies
  validate :todo_dependents_cannot_include_depts_dependents
  validate :todo_children_cannot_include_self
  validate :todo_parents_cannot_include_self
  validate :cannot_mark_as_done_if_dependencies_not_done, if: -> { will_save_change_to_attribute?(:status, to: true) }

  before_update :shift_end_date, if: -> { will_save_change_to_start_date? }
  after_update :update_children_timeline, if: -> { saved_change_to_start_date? && saved_change_to_end_date? }
  after_update :update_dependents_timeline, :update_parents_end_date, if: -> { saved_change_to_end_date? }

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
    dependents.each do |dependent|
      errors.add(:dependencies, "can't add dependent #{dependent.name} as dependency") if dependencies.include?(dependent)
    end
  end

  def todo_dependencies_cannot_include_deps_dependencies
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    deps_dependencies = dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    dependencies.each do |dependency|
      errors.add(:dependencies, "can't add dependency #{dependency.name}'s dependencies") if deps_dependencies.include?(dependency)
    end
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
    dependencies.each do |dependency|
      errors.add(:dependents, "can't add dependency #{dependency.name} as dependent") if dependents.include?(dependency)
    end
  end

  def todo_dependents_cannot_include_depts_dependents
    return unless todo_dependents.present?

    dependents = Todo.find(todo_dependents.map(&:dependent_id))
    deps_dependents = dependents.map { |dependent| dependent.dependents }.flatten.uniq
    dependents.each do |dependent|
      errors.add(:dependents, "can't add dependent #{dependent.name}'s dependents") if deps_dependents.include?(dependent)
    end
  end
  
  def cannot_mark_as_done_if_dependencies_not_done
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    dependencies.each do |dependency|
      if dependency.status == false
        errors.add(:status,
                   "can't mark todo as done since dependency #{dependency.name} is still open")
      end
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

    latest_dependency = Todo.find(todo_dependencies.map(&:todo_id)).max_by(&:end_date)
    if start_date < latest_dependency.end_date
      errors.add(:start_date, "start date can't be earlier than dependency #{latest_dependency.name}'s end date")
    end
  end

  def end_date_cannot_later_than_dependents_start_date
    return unless todo_dependents.present?

    earliest_dependent = Todo.find(todo_dependents.map(&:dependent_id)).min_by(&:start_date)
    if end_date > earliest_dependent.start_date
      errors.add(:end_date, "end date can't be later than dependent #{earliest_dependent.name}'s start date")
    end
  end

  def start_date_cannot_earlier_than_parents_start_date
    return unless todo_parents.present?

    latest_parent = Todo.find(todo_parents.map(&:todo_id)).max_by(&:start_date)
    if start_date < latest_parent.start_date
      errors.add(:start_date, "start date can't be earlier than parent #{latest_parent.name}'s start date")
    end
  end

  def end_date_cannot_later_than_parents_end_date
    return unless todo_parents.present?
    
    earliest_parent = Todo.find(todo_parents.map(&:todo_id)).min_by(&:end_date)
    if end_date > earliest_parent.end_date
      errors.add(:end_date, "end date can't be later than parent #{earliest_parent.name}'s end date")
    end
  end

  def end_date_cannot_earlier_than_children_end_date
    return unless todo_children.present?
    
    latest_child = Todo.find(todo_children.map(&:child_id)).max_by(&:end_date)
    if end_date < latest_child.end_date
      errors.add(:end_date, "end date can't be earlier than child #{latest_child.name}'s end date")
    end
  end
  
  def update_dependents_timeline
    delta = end_date - end_date_previously_was
    if (delta / 1.days) > 1
      dependents.each do |dependent|
        latest_dependency = dependent.dependencies.order(end_date: :desc).first
        if id == latest_dependency.id && dependent.start_date < end_date
          dependent.update start_date: dependent.start_date + delta, end_date: dependent.end_date + delta
        end
      end
    end
  end

  def shift_end_date
    delta = start_date - start_date_was
    if ((delta.abs / 1.days) > 1) && (!will_save_change_to_end_date? || (end_date - end_date_was).abs / 1.days < 1)
      self.end_date = end_date + delta
    end
  end

  def update_children_timeline
    delta = start_date - start_date_previously_was
    if (delta.abs / 1.days) > 1
      children.each do |child|
        child.update start_date: child.start_date + delta, end_date: child.end_date + delta
      end
    end
  end

  def update_parents_end_date
    delta = end_date - end_date_previously_was
    if (delta.abs / 1.days) > 1
      parents.each do |parent|
        latest_child = parent.children.order(end_date: :desc).first
        if id == latest_child.id && parent.end_date < end_date
          parent.update end_date: end_date
        end
      end
    end
  end

  def update_repeat(_child)
    update repeat: true unless repeat
  end
end
