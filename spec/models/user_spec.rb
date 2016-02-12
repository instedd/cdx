require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe User, type: :model do
  describe '.full_name' do
    it 'concatenates the users first and last name' do
      user = User.make(first_name: 'Roger', last_name: 'Melly')
      expect(user.full_name).to eq('Roger Melly')
    end
  end

  describe '.invited_pending?' do
    context 'when outstanding invitation' do
      let(:user) { User.make(:invited_pending) }
      it 'is truthy' do
        expect(user.invited_pending?).to be_truthy
      end
    end

    context 'when no outstanding invitation' do
      let(:user) { User.make }
      it 'is falsey' do
        expect(user.invited_pending?).to be_falsey
      end
    end
  end

  describe '.active_for_authentication?' do
    let(:user) { User.make(is_active: false) }
    it 'is falsey when is_active flag is :false' do
      expect(user.active_for_authentication?).to be_falsey
    end
  end

  describe "scoping" do
    let(:granter_1) { User.make }
    let!(:institution_1) { granter_1.create Institution.make }
    let(:granter_2) { User.make }
    let!(:institution_2) { granter_2.create Institution.make }
    let!(:user_institution_1) { User.make }
    let!(:user_site_1) { User.make }
    let!(:user_institution_2) { User.make }
    let!(:site_1) { Site.make(institution_id: institution_1.id) }
    let!(:subsite_1) { Site.make(institution_id: institution_1.id, parent_id: site_1.id) }
    let!(:user_subsite_1) { User.make }

    before(:each) do
      policy_1 = Policy.make(definition: policy_definition(institution_1, READ_INSTITUTION, false), granter_id: granter_1.id, user_id: user_institution_1)
      policy_2 = Policy.make(definition: policy_definition(institution_2, READ_INSTITUTION, false), granter_id: granter_2.id, user_id: user_institution_2)
      policy_3 = Policy.make(definition: policy_definition(site_1, READ_SITE, false), granter_id: granter_1.id, user_id: user_site_1)
      user_institution_1.roles << Role.make(institution: institution_1, policy: policy_1, site: nil)
      user_site_1.roles << Role.make(institution: institution_1, site: site_1, policy: policy_3)
      user_subsite_1.roles << Role.make(institution: institution_1, site: subsite_1, policy: policy_3)
      user_institution_2.roles << Role.make(institution: institution_2, policy: policy_2)
    end

    it "should show institution users" do
      expect(User.within(institution_1)).to eq([user_institution_1, user_site_1, user_subsite_1])
    end

    it "should show institution users in site" do
      expect(User.within(site_1)).to eq([user_site_1, user_subsite_1])
    end

    it "institution, with exclusion, should show users with roles in institution only" do
      expect(User.within(institution_1,true)).to eq([user_institution_1])
    end

    it "site, with exclusion, should show users with roles in site only" do
      expect(User.within(site_1,true)).to eq([user_site_1])
    end

  end

end
