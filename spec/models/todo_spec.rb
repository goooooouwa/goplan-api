require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo)  { create :todo }

  # it 'can create empty todo' do   #
  #   expect(create(:todo).project).to be_instance_of(Project)
  # end

  it 'can create empty todo' do   #
    expect(create(:todo).project).to be_instance_of(Project)
  end
end
