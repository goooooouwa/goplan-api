class Todo < ApplicationRecord
  belongs_to :project
  delegate :user, to: :project, allow_nil: true

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
  scope :name_contains, lambda { |name|
                          where('lower(todos.name) LIKE ?', '%' + Todo.sanitize_sql_like(name).downcase + '%')
                        }
  scope :done, -> { where(status: true) }
  scope :undone, -> { where(status: false) }
  scope :top_level_undone, -> { where(status: false).where.not(id: Todo.left_outer_joins(:dependencies).where(status: false, dependencies: { status: false })) }
  scope :due_date_before, ->(date) { where(status: false).where('end_date <= ?', date) }

  validates_presence_of :name
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_presence_of :instance_time_span
  validate :end_date_cannot_earlier_than_start_date
  validate :start_date_cannot_earlier_than_dependencies_end_date
  validate :end_date_cannot_later_than_dependents_start_date, on: :create
  validate :todo_dependencies_cannot_include_self
  validate :todo_dependencies_cannot_include_deps_dependencies
  validate :todo_dependents_cannot_include_self
  validate :cannot_mark_as_done_if_dependencies_not_done, if: proc { |todo|
                                                                todo.will_save_change_to_attribute?(:status, to: true)
                                                              }

  before_update :change_start_date_and_end_date, if: proc { |todo|
                                                       todo.will_save_change_to_attribute?(:status, to: true)
                                                     }
  after_update :update_dependents_timeline, if: proc { |todo|
                                                  todo.saved_change_to_end_date?
                                                }

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

  private

  def with_deps

  end

  def end_date_cannot_earlier_than_start_date
    errors.add(:end_date, "can't be earlier than start date") if end_date < start_date
  end

  def todo_dependencies_cannot_include_self
    return unless todo_dependencies.present?

    if todo_dependencies.select do |todo_dependency|
         todo_dependency.todo_id == id
       end.present?
      errors.add(:dependencies, "can't include self")
    end
  end

  def todo_dependencies_cannot_include_deps_dependencies
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    deps_dependencies = dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    intersection = deps_dependencies.filter { |deps_dependency| dependencies.include?(deps_dependency) }
    errors.add(:dependencies, "can't include dependency's dependencies") if intersection.present?
  end

  def todo_dependents_cannot_include_self
    return unless todo_dependents.present?

    if todo_dependents.select { |todo_dependent| todo_dependent.child_id == id }.present?
      errors.add(:dependents, "can't include self")
    end
  end

  def cannot_mark_as_done_if_dependencies_not_done
    return unless todo_dependencies.present?

    error_message = "can't mark as done since one or more dependencies are still open"
    if Todo.find(todo_dependencies.map(&:todo_id)).select do |dependency|
         dependency.status == false
       end.present?
      errors.add(:status, error_message)
    end
  end

  def start_date_cannot_earlier_than_dependencies_end_date
    return unless todo_dependencies.present?

    if start_date < Todo.find(todo_dependencies.map(&:todo_id)).max_by(&:end_date).end_date
      errors.add(:start_date, "can't be earlier than dependencies' end date")
    end
  end

  def end_date_cannot_later_than_dependents_start_date
    return unless todo_dependents.present?

    if end_date > Todo.find(todo_dependents.map(&:child_id)).min_by(&:start_date).start_date
      errors.add(:end_date, "can't be later than dependents' start date")
    end
  end

  def change_start_date_and_end_date
    self.start_date = Time.current if start_date > Time.current
    self.end_date = Time.current if end_date > Time.current
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
end
