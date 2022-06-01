class TodosPostponeDelayedJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Todo.where.missing(:todo_dependencies).due_date_before(Time.current).in_batches.each_record do |root_todo|
      root_todo.update(end_date: Time.current)
    end
  end
end
