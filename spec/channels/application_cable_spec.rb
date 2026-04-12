require "rails_helper"

RSpec.describe "ApplicationCable" do
  it "defines a Channel base class" do
    expect(ApplicationCable::Channel.superclass).to eq(ActionCable::Channel::Base)
  end

  it "defines a Connection base class" do
    expect(ApplicationCable::Connection.superclass).to eq(ActionCable::Connection::Base)
  end
end
