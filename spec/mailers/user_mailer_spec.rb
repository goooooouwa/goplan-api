require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "welcome_message" do
    let(:mail) { UserMailer.welcome_message }

    it "renders the headers" do
      expect(mail.subject).to eq("Test Mail")
      expect(mail.to).to eq(["example@email.com"])
      expected_from = ApplicationMailer.default[:from]
      expect(mail.from).to eq(Array.wrap(expected_from))
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
