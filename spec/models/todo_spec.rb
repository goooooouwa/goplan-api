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
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include("end date can't be earlier than start date")
  end

  it 'validates :start_date_cannot_earlier_than_dependencies_end_date' do
    todo = create(:todo_with_very_early_start_date)
    todo.todo_dependencies_attributes = FactoryBot.create_list(:todo, 5).map{ |todo| { todo_id: todo.id }}
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
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't add self as dependency")
  end

  it 'validates :todo_dependencies_cannot_include_dependents' do
  end

  it 'validates :todo_dependents_cannot_include_dependencies' do
  end

  it 'validates :todo_dependents_cannot_include_self' do
  end

  it 'validates :todo_children_cannot_include_self' do
  end

  it 'validates :todo_parents_cannot_include_self' do
  end

  it 'validates :todo_dependencies_cannot_include_deps_dependencies' do
  end

  it 'validates :todo_dependents_cannot_include_depts_dependents' do
  end

  it 'validates :cannot_mark_as_done_if_dependencies_not_done' do
  end

  it 'after_update :update_dependents_timeline, if: -> { saved_change_to_end_date? }' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 10.days
    todo.update end_date: todo.end_date + delta
    expect(todo.dependents.first.start_date).to be_within(1.second).of dependent.start_date_previously_was + delta
    expect(todo.dependents.first.end_date).to be_within(1.second).of dependent.end_date_previously_was + delta
  end

  it 'after_update :update_parents_end_date, if: -> { saved_change_to_end_date? }' do
  end

  it 'after_update :update_parents_start_date, if: -> { saved_change_to_start_date? }' do
  end

  it 'after_add: :update_as_repeat' do
  end

  it 'after_add: :update_start_date_and_end_date' do
  end

end
