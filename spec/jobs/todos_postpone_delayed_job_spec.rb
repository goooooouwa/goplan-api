require "rails_helper"

RSpec.describe TodosPostponeDelayedJob, type: :job do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  it "sets end_date to now for independent undone todos more than one day past end_date" do
    travel_to Time.zone.parse("2025-06-15 12:00") do
      todo = create(:todo, project: project, start_date: 5.days.ago, end_date: 3.days.ago, status: false)
      expect(todo.dependencies).to be_empty

      described_class.perform_now

      todo.reload
      expect(todo.end_date).to be_within(1.second).of(Time.zone.now)
    end
  end

  it "does not change todos that are less than one full day overdue" do
    travel_to Time.zone.parse("2025-06-15 12:00") do
      end_at = 12.hours.ago
      todo = create(:todo, project: project, start_date: 2.days.ago, end_date: end_at, status: false)

      described_class.perform_now

      todo.reload
      expect(todo.end_date).to be_within(1.second).of(end_at)
    end
  end

  it "does not process todos that still have dependencies" do
    travel_to Time.zone.parse("2025-06-15 12:00") do
      # Blocker is done so the job will not touch it (undone scope); blocked stays out of :independent.
      blocker = create(:todo, project: project, start_date: 10.days.ago, end_date: 8.days.ago, status: true)
      blocked = create(:todo, project: project, start_date: 5.days.ago, end_date: 3.days.ago, status: false)
      TodoDependent.create!(todo_id: blocker.id, dependent_id: blocked.id)

      described_class.perform_now

      blocked.reload
      expect(blocked.end_date).to be_within(1.second).of(3.days.ago)
    end
  end
end
