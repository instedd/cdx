require 'spec_helper'

describe Institution do
  let(:user) {User.make}

  describe "roles" do
    it "creates predefined roles for institution" do
      institution = nil
      expect {
        institution = Institution.make user_id: user.id
      }.to change(Role, :count).by(2)
      roles = Role.where(institution_id: institution.id).all
      roles.each do |role|
        expect(role.key).not_to eq(nil)
      end
    end

    it "renames predefined roles for institution on update" do
      institution = Institution.make user_id: user.id
      institution.name = "New Institution"
      institution.save!

      predefined = Policy.predefined_institution_roles(institution)
      existing = institution.roles.all

      existing.each do |existing_role|
        pre = predefined.find { |role| role.key == existing_role.key }
        expect(existing_role.name).to eq(pre.name)
      end
    end

    it "deletes all roles when destroyed" do
      institution = Institution.make user_id: user.id
      expect {
        institution.destroy
      }.to change(Role, :count).by(-2)
    end
  end
end
