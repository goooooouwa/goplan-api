class Todo < ApplicationRecord
  IN_REPEAT_PERIOD = {
    'day' => :in_days,
    'week' => :in_weeks,
    'month' => :in_months,
    'year' => :in_years,
  }

  attribute :repeat_period, :string, default: 'week'
  attribute :instance_time_span, :integer, default: 1
  attribute :color, :string, default: 'primary.main'

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

  has_many :children, through: :todo_children, source: :child, before_add: :change_as_repeat
  has_many :parents, through: :todo_parents, source: :todo

  accepts_nested_attributes_for :todo_children, :todo_parents, :parents, :children, allow_destroy: true

  default_scope { order(:start_date) }
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
  scope :independent, -> { left_outer_joins(:dependencies).where(dependencies: { id: nil }) }
  scope :childless, -> { left_outer_joins(:children).where(children: { id: nil }) }
  scope :parentless, -> { left_outer_joins(:parents).where(parents: { id: nil }) }
  scope :end_date_before, ->(date) { where('end_date <= ?', date) }

  validates_presence_of :name
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_length_of :parents, maximum: 1
  validate :start_date_cannot_earlier_than_dependencies_end_date
  validate :start_date_cannot_earlier_than_parents_start_date
  validate :start_date_cannot_later_than_children_start_date, on: :create
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

  before_create :generate_punched_tasks, if: -> { repeat_times > 0 }
  before_update :shift_end_date, if: lambda {
                                       will_save_change_to_start_date? && (!will_save_change_to_end_date? || (end_date - end_date_was).abs / 1.days < 1)
                                     }
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
    id == todos.has_dependency(dependency.id).reorder(:created_at).limit(1).first.try(:id)
  end

  def first_appearance_of_dependent_in_todos?(dependent, todos)
    id == todos.has_dependent(dependent.id).reorder(:created_at).limit(1).first.try(:id)
  end

  private

  def end_date_cannot_earlier_than_start_date
    return if [start_date, end_date].any?(&:nil?)

    if end_date < start_date
      errors.add(:end_date,
                 "end date #{end_date} can't be earlier than start date #{start_date}")
    end
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
      if dependencies.include?(dependent)
        errors.add(:dependencies,
                   "can't add dependent #{dependent.name} as dependency")
      end
    end
  end

  def todo_dependencies_cannot_include_deps_dependencies
    return unless todo_dependencies.present?

    dependencies = Todo.find(todo_dependencies.map(&:todo_id))
    deps_dependencies = dependencies.map { |dependency| dependency.dependencies }.flatten.uniq
    dependencies.each do |dependency|
      if deps_dependencies.include?(dependency)
        errors.add(:dependencies,
                   "can't add dependency #{dependency.name}'s dependencies")
      end
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
      if deps_dependents.include?(dependent)
        errors.add(:dependents,
                   "can't add dependent #{dependent.name}'s dependents")
      end
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
      errors.add(:start_date,
                 "start date #{start_date} can't be earlier than dependency #{latest_dependency.name}'s end date #{latest_dependency.end_date}")
    end
  end

  def end_date_cannot_later_than_dependents_start_date
    return unless todo_dependents.present?

    earliest_dependent = Todo.find(todo_dependents.map(&:dependent_id)).min_by(&:start_date)
    if end_date > earliest_dependent.start_date
      errors.add(:end_date,
                 "end date #{end_date} can't be later than dependent #{earliest_dependent.name}'s start date #{earliest_dependent.start_date}")
    end
  end

  def start_date_cannot_earlier_than_parents_start_date
    return unless todo_parents.present?

    latest_parent = Todo.find(todo_parents.map(&:todo_id)).max_by(&:start_date)
    if start_date < latest_parent.start_date
      errors.add(:start_date,
                 "start date #{start_date} can't be earlier than parent #{latest_parent.name}'s start date #{latest_parent.start_date}")
    end
  end

  def start_date_cannot_later_than_children_start_date
    return unless todo_children.present?

    earliest_child = Todo.find(todo_children.map(&:child_id)).min_by(&:start_date)
    if start_date > earliest_child.start_date
      errors.add(:start_date,
                 "start date #{start_date} can't be later than child #{earliest_child.name}'s start date #{earliest_child.start_date}")
    end
  end

  def end_date_cannot_later_than_parents_end_date
    return unless todo_parents.present?

    earliest_parent = Todo.find(todo_parents.map(&:todo_id)).min_by(&:end_date)
    if end_date > earliest_parent.end_date
      errors.add(:end_date,
                 "end date #{end_date} can't be later than parent #{earliest_parent.name}'s end date #{earliest_parent.end_date}")
    end
  end

  def end_date_cannot_earlier_than_children_end_date
    return unless todo_children.present?

    latest_child = Todo.find(todo_children.map(&:child_id)).max_by(&:end_date)
    if end_date < latest_child.end_date
      errors.add(:end_date,
                 "end date #{end_date} can't be earlier than child #{latest_child.name}'s end date #{latest_child.end_date}")
    end
  end

  def generate_punched_tasks
    number_of_repeat_periods = (end_date - start_date).seconds.public_send(IN_REPEAT_PERIOD[repeat_period]).ceil
    interval_of_punched_tasks = (1.public_send(repeat_period) / repeat_times).in_days.floor.days
    number_of_punched_tasks = repeat_times * number_of_repeat_periods

    children_attributes = []
    number_of_punched_tasks.times do |i|
      punched_task_start_date = start_date + i * interval_of_punched_tasks
      break if punched_task_start_date > end_date

      children_attributes << {
        name: "##{i + 1}",
        project_id: project_id,
        start_date: punched_task_start_date,
        end_date: punched_task_start_date,
        color: color
      }
    end

    self.children_attributes = children_attributes
  end

  def update_dependents_timeline
    logger.debug "#{name} - update_dependents_timeline:"
    delta = end_date - end_date_previously_was
    logger.debug "#{name} - is delta #{delta} >= 1.days ? = #{(delta / 1.days) >= 1}"
    if (delta / 1.days) >= 1
      logger.debug "#{name} - dependents: [#{dependents.map(&:name).join(', ')}]"
      dependents.each do |dependent|
        latest_dependency = dependent.dependencies.reorder(end_date: :desc).first
        logger.debug "#{name} - is latest_dependency ? = #{id == latest_dependency.id} && dependent.start_date #{dependent.start_date} < end_date #{end_date} ? = #{dependent.start_date < end_date}"
        next unless id == latest_dependency.id && dependent.start_date < end_date

        logger.debug "#{name} - update dependent #{dependent.name} timeline from #{dependent.start_date} - #{dependent.end_date} to #{dependent.start_date + delta} - #{dependent.end_date + delta}"
        dependent.start_date = dependent.start_date + delta
        dependent.end_date = dependent.end_date + delta
        logger.error "#{dependent.name} - validation errors: #{dependent.errors.inspect}" unless dependent.valid?
        dependent.save!
      end
    end
  end

  def shift_end_date
    logger.debug "#{name} - shift_end_date:"
    delta = start_date - start_date_was
    logger.debug "#{name} - is delta.abs #{delta} >= 1.days ? = #{(delta.abs / 1.days) >= 1}"
    if (delta.abs / 1.days) >= 1
      logger.debug "#{name} - shift #{name} end date from #{end_date} to #{end_date + delta}"
      self.end_date = end_date + delta
    end
  end

  def update_children_timeline
    logger.debug "#{name} - update_children_timeline:"
    delta = start_date - start_date_previously_was
    logger.debug "#{name} - is delta.abs #{delta} >= 1.days ? = #{(delta.abs / 1.days) >= 1}"
    if (delta.abs / 1.days) >= 1
      logger.debug "#{name} - children: [#{children.map(&:name).join(', ')}]"
      children.each do |child|
        logger.debug "#{name} - update child #{child.name} timeline from #{child.start_date} - #{child.end_date} to #{child.start_date + delta} - #{child.end_date + delta}"
        child.start_date = child.start_date + delta
        child.end_date = child.end_date + delta
        logger.error "#{child.name} - validation errors: #{child.errors.inspect}" unless child.valid?
        child.save!
      end
    end
  end

  def update_parents_end_date
    logger.debug "#{name} - update_parents_end_date:"
    delta = end_date - end_date_previously_was
    logger.debug "#{name} - is delta.abs #{delta} >= 1.days ? = #{(delta.abs / 1.days) >= 1}"
    if (delta.abs / 1.days) >= 1
      logger.debug "#{name} - parents: [#{parents.map(&:name).join(', ')}]"
      parents.each do |parent|
        latest_child = parent.children.reorder(end_date: :desc).first
        logger.debug "#{name} - is latest_child ? = #{id == latest_child.id} && parent.end_date #{parent.end_date} < end_date #{end_date} ? = #{parent.end_date < end_date}"
        next unless id == latest_child.id && parent.end_date < end_date

        logger.debug "#{name} - update parent #{parent.name} end date from #{parent.end_date} to #{end_date}"
        parent.end_date = end_date
        logger.error "#{parent.name} - validation errors: #{parent.errors.inspect}" unless parent.valid?
        parent.save!
      end
    end
  end

  def change_as_repeat(child)
    self.repeat = true unless repeat
  end
end
