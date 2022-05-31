class PostponeDelayedTodosJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Todo.due.in_batches.update_all(end_date: DateTime.current)
  end
end
