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

  it '#update_dependents_timeline should update dependents timeline if end date is changed' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 10.days
    todo.update end_date: todo.end_date + delta
    expect(dependent.start_date).to be_within(1.second).of dependent.start_date_previously_was + delta
    expect(dependent.end_date).to be_within(1.second).of dependent.end_date_previously_was + delta
  end

  it '#update_dependents_timeline should debounce if end date is not changed more than 1 day' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date + 23.hours
    expect(dependent.start_date_previously_was).to eq(nil)
    expect(dependent.end_date_previously_was).to eq(nil)
  end

  it '#update_children_timeline should update children timeline if start date is changed' do
    todo = create(:todo_with_past_start_date_and_future_end_date, todo_children_attributes: [todo1, todo2].map{ |todo| { child_id: todo.id } })
    delta = 10.days
    todo.update start_date: todo.start_date + delta
    expect(todo.children.first.start_date).to be_within(1.second).of todo.children.first.start_date_previously_was + delta
    expect(todo.children.last.end_date).to be_within(1.second).of todo.children.last.end_date_previously_was + delta
  end

  it '#update_children_timeline should postpone end date if is earlier than latest child' do
    todo = create(:todo_with_past_start_date_and_future_end_date, todo_children_attributes: [todo1, todo2].map{ |todo| { child_id: todo.id } })
    delta = 10.days
    todo.update start_date: todo.start_date + delta
    expect(todo.end_date).to be_within(1.second).of todo.children.order(end_date: :desc).first.end_date
  end
  
  it 'should debounce #update_dependents_timeline if start date is not changed more than 1 day' do
    todo = create(:todo, todo_children_attributes: [todo1].map{ |todo| { child_id: todo.id } })
    todo.update end_date: todo.end_date + 23.hours
    expect(todo1.start_date_previously_was).to eq(nil)
    expect(todo1.end_date_previously_was).to eq(nil)
  end

  it 'has_many :children, after_add: :update_as_repeat' do
    project = create(:project)
    todo = create(:todo, children_attributes: [attributes_for(:todo, project_id: project.id)])
    expect(todo.repeat).to eq(true)
  end

end
