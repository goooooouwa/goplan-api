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

  describe '.from_omniauth' do
    it 'finds or creates a user from an auth hash' do
      auth = {
        provider: 'github',
        uid: 'omniauth-uid-1',
        info: { email: 'oauth.user@example.com', name: 'OAuth', image: 'https://example.com/i.png' }
      }
      user = User.from_omniauth(auth)
      expect(user).to be_persisted
      expect(user.email).to eq('oauth.user@example.com')
      expect(user.provider).to eq('github')
    end
  end

  describe '.new_with_session' do
    it 'fills email from session when blank' do
      session = { 'devise.oauth.data' => { 'info' => { 'email' => 'session@example.com' } } }
      allow($stdout).to receive(:puts)
      user = User.new_with_session({ email: '' }, session)
      expect(user.email).to eq('session@example.com')
    end
  end
end
