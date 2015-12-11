require 'spec_helper'

describe Site do
  it "validates self institution match parent institution" do
    institution1 = Institution.make
    institution2 = Institution.make
    site1 = Site.make institution: institution1
    site2 = Site.make_unsaved institution: institution2, parent: site1
    expect(site2).to_not be_valid
  end

  it "computes prefix for self" do
    site = Site.make
    expect(site.prefix).to eq(site.uuid.to_s)
  end

  it "computes prefix for self with parent" do
    site1 = Site.make
    site2 = Site.make :child, parent: site1
    expect(site2.prefix).to eq("#{site1.uuid}.#{site2.uuid}")
  end

  it "computes prefix for self with parent and grandparent" do
    site1 = Site.make
    site2 = Site.make :child, parent: site1
    site3 = Site.make :child, parent: site2
    expect(site3.prefix).to eq("#{site1.uuid}.#{site2.uuid}.#{site3.uuid}")

    expect(site3.path).to eq([site1.uuid, site2.uuid, site3.uuid])
  end

  it "can't destroy a site with associated devices" do
    site1 = Site.make
    site1.devices.make

    expect(site1.devices).not_to be_empty
    expect {
      site1.destroy
    }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end

  it "destroys sites logically" do
    site1 = Site.make
    expect(Site.count).to eq(1)

    expect {
      site1.destroy
    }.to change(Site, :count).by(-1)

    expect(Site.all).not_to include(site1)
    expect(Site.with_deleted).to include(site1)
    expect(site1).to be_deleted
  end

  context "within institution or site scope" do
    let(:institution) { Institution.make }
    let(:other_institution) { Institution.make }

    let(:site1)  { Site.make institution: institution }
    let(:site11) { Site.make :child, parent: site1 }
    let(:site12) { Site.make :child, parent: site1 }
    let(:site2)  { Site.make institution: institution }

    it "should filter by institution" do
      expect(Site.within(institution)).to eq([site1, site11, site12, site2])
    end

    it "filtering by site should include self" do
      expect(Site.within(site1)).to include(site1)
    end

    it "filtering by site should include descendants" do
      expect(Site.within(site1)).to include(site11)
      expect(Site.within(site1)).to include(site12)
    end

    it "filtering by site should not include sibling" do
      expect(Site.within(site1)).to_not include(site2)
    end
  end

  describe "roles" do
    it "creates predefined roles for site" do
      user = User.make
      institution = Institution.make user_id: user.id
      site = nil
      expect {
        site = Site.make institution_id: institution.id
      }.to change(Role, :count).by(4)
      roles = Role.where(site_id: site.id).all
      roles.each do |role|
        expect(role.key).not_to eq(nil)
      end
    end

    it "renames predefined roles for site on update" do
      user = User.make
      institution = Institution.make user_id: user.id
      site = Site.make institution_id: institution.id
      site.name = "New site"
      site.save!

      predefined = Policy.predefined_site_roles(site)
      existing = site.roles.all

      existing.each do |existing_role|
        pre = predefined.find { |role| role.key == existing_role.key }
        expect(existing_role.name).to eq(pre.name)
      end
    end

    it "deletes all roles when destroyed" do
      user = User.make
      institution = Institution.make user_id: user.id
      site = Site.make institution_id: institution.id
      expect {
        site.destroy
      }.to change(Role, :count).by(-4)
    end
  end
end
