class TodosPostponeDelayedJob < ApplicationJob
  queue_as :default

  def perform(*args)
    now = Time.current
    Todo.independent.undone.end_date_before(now).in_batches.each_record do |independent|
      delta = now - end_date
      independent.update(end_date: now) if (delta / 1.days) > 1
    end
  end
end
