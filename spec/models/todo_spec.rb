require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo1)  { create :todo, name: "Todo 1" }
  let(:todo2)  { create :todo, name: "Todo 2" }

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
    expect(todo.errors[:start_date]).to include(/start date can't be earlier than dependency Todo (1|2)'s end date/)
  end

  it 'validate :end_date_cannot_later_than_dependents_start_date, on: :create' do
    todo = build(:todo_with_very_late_end_date, todo_dependents_attributes: [todo1, todo2].map{ |todo| { dependent_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include(/end date can't be later than dependent Todo (1|2)'s start date/)
  end

  it 'validates :todo_dependencies_cannot_include_self' do
    todo = create(:todo)
    todo.todo_dependencies_attributes = [{ todo_id: todo.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't add self as dependency")
  end

  it 'validate :start_date_cannot_earlier_than_parents_start_date' do
    todo = build(:todo_with_past_start_and_end_date, todo_parents_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:start_date]).to include(/start date can't be earlier than parent Todo (1|2)'s start date/)
  end

  it 'validates :end_date_cannot_later_than_parents_end_date' do
    todo = build(:todo_with_future_start_and_end_date, todo_parents_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include(/end date can't be later than parent Todo (1|2)'s end date/)
  end

  it 'validates :end_date_cannot_earlier_than_children_end_date' do
    todo = build(:todo_with_past_start_and_end_date, todo_children_attributes: [todo1, todo2].map{ |todo| { child_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include(/end date can't be earlier than child Todo (1|2)'s end date/)
  end

  it 'validates :todo_dependencies_cannot_include_dependents' do
    todo = create(:todo)
    todo.dependents << [todo1, todo2]
    todo.todo_dependencies_attributes = [{ todo_id: todo1.id}]
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include(/can't add dependent Todo 1 as dependency/)
  end

  it 'validates :todo_dependencies_cannot_include_deps_dependencies' do
    todo = create(:todo)
    todo1.dependencies << todo2
    todo.todo_dependencies_attributes = [todo1, todo2].map{ |todo| { todo_id: todo.id } }
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include(/can't add dependency Todo (1|2)'s dependencies/)
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
    expect(todo.errors[:dependents]).to include(/can't add dependency Todo (1|2) as dependent/)
  end

  it 'validates :todo_dependents_cannot_include_depts_dependents' do
    todo = create(:todo)
    todo1.dependents << todo2
    todo.todo_dependents_attributes = [todo1, todo2].map{ |todo| { dependent_id: todo.id } }
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:dependents]).to include(/can't add dependent Todo (1|2)'s dependents/)
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
    expect(todo.errors[:status]).to include(/can't mark todo as done since dependency Todo (1|2) is still open/)
  end

  it '#change_dependents_start_date should update dependents start date if end date is postponed' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 10.days
    todo.update end_date: todo.end_date + delta
    expect(todo).to be_valid
    expect(todo.dependents.first.start_date).to be_within(1.second).of dependent.start_date_previously_was + delta
  end

  it '#change_dependents_start_date should not update dependents start date if end date is earlier than previous' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 8.days
    todo.update end_date: todo.end_date - delta
    expect(todo).to be_valid
    expect(dependent.start_date_previously_was).to eq(nil)
  end

  it '#change_dependents_start_date should debounce if end date is not changed more than 1 day' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    todo.update end_date: todo.end_date + 23.hours
    expect(todo).to be_valid
    expect(dependent.start_date_previously_was).to eq(nil)
  end

  it '#shift_end_date should shift end date if start date is changed' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    delta = 8.days
    todo.update start_date: todo.start_date + delta
    expect(todo).to be_valid
    expect(todo.end_date).to be_within(1.second).of todo.end_date_previously_was + delta
  end

  it '#shift_end_date should shift task, dependents and children end date if their start date is delayed' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    todo.children << todo1
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 5.days
    todo.start_date = todo.start_date + delta
    expect(todo).to be_valid
    expect(todo.save).to eq(true)
    expect(todo.end_date).to be_within(1.second).of todo.end_date_previously_was + delta
    expect(todo.children.first.start_date).to be_within(1.second).of todo.children.first.start_date_previously_was + delta
    expect(todo.children.first.end_date).to be_within(1.second).of todo.children.first.end_date_previously_was + delta
    expect(todo.dependents.first.start_date).to be_within(1.second).of todo.dependents.first.start_date_previously_was + delta
    expect(todo.dependents.first.end_date).to be_within(1.second).of todo.dependents.first.end_date_previously_was + delta
  end

  it '#shift_end_date should only shift task and children end date if their start date is advanced' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    todo.children << todo1
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 8.days
    todo.update start_date: todo.start_date - delta
    expect(todo).to be_valid
    expect(todo.end_date).to be_within(1.second).of todo.end_date_previously_was - delta
    expect(todo.children.first.start_date).to be_within(1.second).of todo.children.first.start_date_previously_was - delta
    expect(todo.children.first.end_date).to be_within(1.second).of todo.children.first.end_date_previously_was - delta
    expect(todo.dependents.first.start_date_previously_was).to eq(nil)
    expect(todo.dependents.first.end_date_previously_was).to eq(nil)
  end

  it '#shift_end_date should not shift end date if end date is to be changed more than 1 day' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    delta_of_start_date = 5.days
    delta_of_end_date = 2.days
    todo.update start_date: todo.start_date + delta_of_start_date, end_date: todo.end_date + delta_of_end_date
    expect(todo).to be_valid
    expect(todo.end_date).to be_within(1.second).of todo.end_date_previously_was + delta_of_end_date
  end

  it '#shift_end_date should not shift end date if start date is not changed more than 1 day' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    delta = 23.hours
    todo.update start_date: todo.start_date + delta
    expect(todo).to be_valid
    expect(todo.end_date).to eq(todo.end_date_previously_was)
  end

  it '#change_children_start_date should change children start date if start date is changed' do
    todo = create(:todo_with_past_start_date_and_future_end_date)
    todo.children << todo1
    delta = 8.days
    todo.update start_date: todo.start_date + delta
    expect(todo).to be_valid
    expect(todo.children.first.start_date).to be_within(1.second).of todo.children.first.start_date_previously_was + delta
  end

  it '#change_children_start_date should debounce if start date is not changed more than 1 day' do
    todo = create(:todo_with_past_start_date_and_future_end_date, todo_children_attributes: [todo1].map{ |todo| { child_id: todo.id } })
    todo.update end_date: todo.end_date + 23.hours
    expect(todo).to be_valid
    expect(todo1.start_date_previously_was).to eq(nil)
  end

  it 'has_many :children, after_add: :update_as_repeat' do
    project = create(:project)
    todo = create(:todo_with_past_start_date_and_future_end_date, children_attributes: [attributes_for(:todo, project_id: project.id)])
    expect(todo.repeat).to eq(true)
  end

end
