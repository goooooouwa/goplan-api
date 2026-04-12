require "rails_helper"

RSpec.describe Project, type: :model do
  let(:user) { create(:user) }

  it "requires a name" do
    project = build(:project, user: user, name: "")
    expect(project).not_to be_valid
    expect(project.errors[:name]).to be_present
  end

  describe ".search" do
    let!(:matching) { create(:project, user: user, name: "Quarterly Review") }
    let!(:other) { create(:project, user: user, name: "Other work") }

    it "returns the full scoped relation when no filters are present" do
      expect(user.projects.search({})).to include(matching, other)
    end

    it "filters by case-insensitive name substring" do
      scoped = user.projects.search({ name: "quarter" })
      expect(scoped).to include(matching)
      expect(scoped).not_to include(other)
    end
  end
end
