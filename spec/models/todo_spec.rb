require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo1)  { create :todo }
  let(:todo2)  { create :todo }

  it 'can create todo with default value' do
    todo = create(:todo)
    expect(todo.project).to be_instance_of(Project)
    expect(todo.name).to be_instance_of(String)
  end

  it 'can create todo with dependencies' do
    todo = create(:todo_with_future_start_and_end_date, todo_dependencies_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    expect(todo.dependencies.count).to eq(2)
  end

  it 'validates :end_date_cannot_earlier_than_start_date' do
    todo = build(:todo_with_end_date_earlier_than_start_date)
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include("end date can't be earlier than start date")
  end

  it 'validates :start_date_cannot_earlier_than_dependencies_end_date' do
    todo = build(:todo_with_very_early_start_date, todo_dependencies_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:start_date]).to include("start date can't be earlier than dependencies' end date")
  end

  it 'validate :end_date_cannot_later_than_dependents_start_date, on: :create' do
    todo = build(:todo_with_very_late_end_date, todo_dependents_attributes: [todo1, todo2].map{ |todo| { dependent_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include("end date can't be later than dependents' start date")
  end

  it 'validates :todo_dependencies_cannot_include_self' do
    todo = create(:todo)
    todo.todo_dependencies_attributes = [{ todo_id: todo.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't add self as dependency")
  end

  it 'validates :todo_dependencies_cannot_include_dependents' do
    todo = create(:todo)
    todo.dependents << todo1
    todo.todo_dependencies_attributes = [{ todo_id: todo1.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't add dependent as dependency")
  end

  it 'validates :todo_dependencies_cannot_include_deps_dependencies' do
    todo = create(:todo)
    todo1.dependencies << todo2
    todo.todo_dependencies_attributes = [todo1, todo2].map{ |todo| { todo_id: todo.id } }
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't add dependency's dependencies")
  end

  it 'validates :todo_dependents_cannot_include_self' do
    todo = create(:todo)
    todo.todo_dependents_attributes = [{ dependent_id: todo.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependents]).to include("can't add self as dependent")
  end

  it 'validates :todo_dependents_cannot_include_dependencies' do
    todo = create(:todo)
    todo.dependencies << todo1
    todo.todo_dependents_attributes = [{ dependent_id: todo1.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependents]).to include("can't add dependency as dependent")
  end

  it 'validates :todo_dependents_cannot_include_depts_dependents' do
    todo = create(:todo)
    todo1.dependents << todo2
    todo.todo_dependents_attributes = [todo1, todo2].map{ |todo| { dependent_id: todo.id } }
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependents]).to include("can't add dependent's dependents")
  end

  it 'validates :todo_children_cannot_include_self' do
    todo = create(:todo)
    todo.todo_children_attributes = [{ child_id: todo.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:children]).to include("can't add self as child")
  end

  it 'validates :todo_parents_cannot_include_self' do
    todo = create(:todo)
    todo.todo_parents_attributes = [{ todo_id: todo.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:parents]).to include("can't add self as parent")
  end

  it 'validates :cannot_mark_as_done_if_dependencies_not_done' do
    todo = create(:todo_with_future_start_and_end_date, todo_dependencies_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    todo.status = true
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:status]).to include("can't mark todo as done since one or more dependencies are still open")
  end

  it 'should #update_dependents_timeline if end date has overlap with earlist dependent' do
    todo = create(:todo)
    dependent = create(:todo, start_date: todo.end_date + 2.days, end_date: todo.end_date + 10.days)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date + 5.days
    delta = 3.days
    expect(todo.dependents.first.start_date).to be_within(1.second).of dependent.start_date_previously_was + delta
    expect(todo.dependents.first.end_date).to be_within(1.second).of dependent.end_date_previously_was + delta
  end

  it 'should not #update_dependents_timeline if end_date is earlier than earlist dependent' do
    todo = create(:todo)
    dependent = create(:todo, start_date: todo.end_date + 2.days, end_date: todo.end_date + 10.days)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date + 1.days
    expect(dependent.start_date_previously_was).to eq(nil)
    expect(dependent.end_date_previously_was).to eq(nil)
  end

  it 'should not #update_dependents_timeline if end_date is earlier than previously was' do
    todo = create(:todo)
    dependent = create(:todo, start_date: todo.end_date + 2.days, end_date: todo.end_date + 10.days)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date - 1.days
    expect(dependent.start_date_previously_was).to eq(nil)
    expect(dependent.end_date_previously_was).to eq(nil)
  end

  it 'should debounce #update_dependents_timeline if end_date is not changed more than 1 day' do
    todo = create(:todo)
    dependent = create(:todo, start_date: todo.end_date, end_date: todo.end_date + 10.days)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date + 23.hours
    expect(dependent.start_date_previously_was).to eq(nil)
    expect(dependent.end_date_previously_was).to eq(nil)
  end

  it 'after_update :update_parents_end_date, if: -> { saved_change_to_end_date? }' do
    todo = create(:todo)
    todo.parents << [todo1]
    todo.update start_date: Time.zone.local(1979, 1, 1, 0, 0)
    expect(todo1.start_date).to eq(todo.start_date)
  end

  it 'after_update :update_parents_start_date, if: -> { saved_change_to_start_date? }' do
    todo = create(:todo)
    todo.parents << [todo1]
    todo.update end_date: Time.zone.local(3000, 1, 1, 0, 0)
    expect(todo1.end_date).to eq(todo.end_date)
  end

  it 'has_many :children, after_add: :update_as_repeat' do
    project = create(:project)
    todo = create(:todo, children_attributes: [attributes_for(:todo, project_id: project.id)])
    expect(todo.repeat).to eq(true)
  end

end
