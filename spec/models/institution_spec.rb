require 'spec_helper'

describe Institution do
  let(:user) {User.make}

  describe "roles" do
    it "creates predefined roles for institution" do
      expect {
        Institution.make user_id: user.id
      }.to change(Role, :count).by(2)
    end

    it "deletes all roles when destroyed" do
      institution = Institution.make user_id: user.id
      expect {
        institution.destroy
      }.to change(Role, :count).by(-2)
    end
  end
end
