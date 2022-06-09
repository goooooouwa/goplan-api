require 'rails_helper'

RSpec.describe User, type: :model do
  it 'can create new user' do   #
    expect(create(:user)).to be_instance_of(User)
  end
end
