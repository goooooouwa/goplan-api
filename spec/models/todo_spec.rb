require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo1)  { create :todo }
  let(:todo2)  { create :todo }

  it 'can create empty todo' do
    expect(create(:todo).project).to be_instance_of(Project)
  end

  it 'can create todo with dependencies' do
    todo = create(:todo_with_future_start_and_end_date, todo_dependencies_attributes: [todo1, todo2].map{ |todo| { todo_id: todo.id } })
    expect(todo.todo_dependencies.count).to eq(2)
  end

  it 'can not create todo that depends on itself' do
    todo = create(:todo)
    todo.todo_dependencies_attributes = [{ todo_id: todo.id}]
    expect(todo).to_not be_valid
    expect(todo.errors[:dependencies]).to include("can't include self")
  end

  it 'can not create todo with end date earlier than start date' do
    todo = build(:todo_with_end_date_earlier_than_start_date)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include("can't be earlier than start date")
  end

  it 'can not update todo with start date earlier than dependencies end date' do
    todo = create(:todo_with_very_early_start_date)
    todo.todo_dependencies_attributes = FactoryBot.create_list(:todo, 5).map{ |todo| { todo_id: todo.id }}
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:start_date]).to include("can't be earlier than dependencies' end date")
  end

  it 'can not create todo with end date later than dependents start date' do
    todo = build(:todo_with_very_late_end_date, todo_dependents_attributes: [todo1, todo2].map{ |todo| { dependent_id: todo.id } })
    expect(todo.save).to eq(false)
    expect(todo).to_not be_valid
    expect(todo.errors[:end_date]).to include("can't be later than dependents' start date")
  end

  it 'should change future start date and end date to today if status changed' do
    todo = create(:todo_with_future_start_and_end_date)
    todo.update status: true
    expect(todo.start_date).to be_within(1.second).of Time.current
    expect(todo.end_date).to be_within(1.second).of Time.current
  end

  it 'should update dependents timeline if end date changed' do
    todo = create(:todo)
    dependent = create(:todo_with_future_start_and_end_date)
    todo.dependents << [dependent]
    delta = 10.days
    todo.update end_date: todo.end_date + delta
    expect(todo.dependents.first.start_date).to be_within(1.second).of dependent.start_date_previously_was + delta
    expect(todo.dependents.first.end_date).to be_within(1.second).of dependent.end_date_previously_was + delta
  end
end
