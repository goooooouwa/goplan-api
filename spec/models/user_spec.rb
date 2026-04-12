require 'rails_helper'

RSpec.describe User, type: :model do
  it 'can create new user' do   #
    expect(create(:user)).to be_instance_of(User)
  end

  it 'exposes projects and todos through projects' do
    user = create(:user)
    project = create(:project, user: user)
    todo = create(:todo, project: project)

    expect(user.projects).to include(project)
    expect(user.todos).to include(todo)
  end
end
