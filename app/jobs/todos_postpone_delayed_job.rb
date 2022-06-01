class TodosPostponeDelayedJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Todo.where.missing(:todo_dependencies).due_date_before(Time.current).in_batches.each do |root_todo|
      delta = Time.current - root_todo.end_date
      root_todo.update(end_date: root_todo.end_date + delta)
      root_todo.dependents.each do |dependent|
        dependent.update(start_date: dependent.start_date + delta, end_date: dependent.end_date + delta)
      end
    end
  end
end
