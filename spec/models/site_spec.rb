require 'spec_helper'

describe Site do
  it "validates self institution match parent institution" do
    institution1 = Institution.make!
    institution2 = Institution.make!
    site1 = Site.make! institution: institution1
    site2 = Site.make institution: institution2, parent: site1
    expect(site2).to_not be_valid
  end

  it "computes prefix for self" do
    site = Site.make!
    expect(site.prefix).to eq(site.uuid.to_s)
  end

  it "computes prefix for self with parent" do
    site1 = Site.make!
    site2 = Site.make! :child, parent: site1
    expect(site2.prefix).to eq("#{site1.uuid}.#{site2.uuid}")
  end

  it "computes prefix for self with parent and grandparent" do
    site1 = Site.make!
    site2 = Site.make! :child, parent: site1
    site3 = Site.make! :child, parent: site2
    expect(site3.prefix).to eq("#{site1.uuid}.#{site2.uuid}.#{site3.uuid}")

    expect(site3.path).to eq([site1.uuid, site2.uuid, site3.uuid])
  end

  it "can't destroy a site with associated devices" do
    site1 = Site.make!
    Device.make!(site: site1)

    expect(site1.devices).not_to be_empty
    expect {
      site1.destroy
    }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end

  it "destroys sites logically" do
    site1 = Site.make!
    expect(Site.count).to eq(1)

    expect {
      site1.destroy
    }.to change(Site, :count).by(-1)

    expect(Site.all).not_to include(site1)
    expect(Site.with_deleted).to include(site1)
    expect(site1).to be_deleted
  end

  context "within institution or site scope" do
    let(:institution) { Institution.make! }
    let(:other_institution) { Institution.make! }

    let(:site1)  { Site.make! institution: institution }
    let(:site11) { Site.make! :child, parent: site1 }
    let(:site12) { Site.make! :child, parent: site1 }
    let(:site2)  { Site.make! institution: institution }

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
      user = User.make!
      institution = Institution.make! user: user
      site = nil
      expect {
        site = Site.make! institution: institution
      }.to change(Role, :count).by(4)
      roles = Role.where(site_id: site.id).all
      roles.each do |role|
        expect(role.key).not_to eq(nil)
      end
    end

    it "renames predefined roles for site on update" do
      user = User.make!
      institution = Institution.make! user: user
      site = Site.make! institution: institution
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
      user = User.make!
      institution = Institution.make! user: user
      site = Site.make! institution: institution
      expect {
        site.destroy
      }.to change(Role, :count).by(-4)
    end
  end

  describe "generate next sample entity id" do
    let(:site) { Site.make! }

    it "should start with 100000 and go on" do
      expect(site.generate_next_sample_entity_id!).to eq("100000")
      expect(site.generate_next_sample_entity_id!).to eq("100001")
      expect(site.generate_next_sample_entity_id!).to eq("100002")
      expect(site.generate_next_sample_entity_id!).to eq("100003")
      expect(site.generate_next_sample_entity_id!).to eq("100004")
      expect(site.generate_next_sample_entity_id!).to eq("100005")
      expect(site.generate_next_sample_entity_id!).to eq("100006")
      expect(site.generate_next_sample_entity_id!).to eq("100007")
      expect(site.generate_next_sample_entity_id!).to eq("100008")
      expect(site.generate_next_sample_entity_id!).to eq("100009")
      expect(site.generate_next_sample_entity_id!).to eq("100010")
    end

    # if with_lock is removed, serialization will be lost (ref 46ccfd) fix #712
    # it "should serialize sample creation on a threaded environment" do
    #   threads = []
    #   10.times do |i|
    #     threads << Thread.new do
    #       Site.find(site.id).generate_next_sample_entity_id!
    #       ActiveRecord::Base.connection.close
    #     end
    #   end
    #   threads.map(&:join)
    #   expect(Site.find(site.id).generate_next_sample_entity_id!).to eq("100010")
    # end

    describe "should recycle using the site policy" do
      def it_recycle_within(start, before_next, start_next, start_next2)
        begin
          Timecop.freeze(start)
          expect(site.generate_next_sample_entity_id!).to eq("100000")
          expect(site.generate_next_sample_entity_id!).to eq("100001")

          Timecop.freeze(before_next)
          expect(site.generate_next_sample_entity_id!).to eq("100002")

          Timecop.freeze(start_next)
          expect(site.generate_next_sample_entity_id!).to eq("100000")
          expect(site.generate_next_sample_entity_id!).to eq("100001")

          Timecop.freeze(start_next2)
          expect(site.generate_next_sample_entity_id!).to eq("100000")
          expect(site.generate_next_sample_entity_id!).to eq("100001")
        ensure
          Timecop.return
        end
      end

      it "works weekly" do
        site.sample_id_reset_policy = "weekly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 12,  7, 15,  0, 0),
          Time.utc(2015, 12, 13, 23, 59, 0),
          Time.utc(2015, 12, 14,  0,  0, 0),
          Time.utc(2015, 12, 21,  0,  0, 0))
      end

      it "works monthly" do
        site.sample_id_reset_policy = "monthly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 10,  3, 15,  0, 0),
          Time.utc(2015, 10, 30, 23, 59, 0),
          Time.utc(2015, 11,  1,  0,  0, 0),
          Time.utc(2015, 12,  1,  0,  0, 0))
      end

      it "works yearly" do
        site.sample_id_reset_policy = "yearly"
        site.save!
        it_recycle_within(
          Time.utc(2015, 10,  3, 15,  0, 0),
          Time.utc(2015, 12, 31, 23, 59, 0),
          Time.utc(2016,  1,  1,  0,  0, 0),
          Time.utc(2017,  2,  1,  0,  0, 0))
      end
    end

    it "should be scoped by site" do
      other_site = Site.make!
      expect(site.generate_next_sample_entity_id!).to eq(other_site.generate_next_sample_entity_id!)
      expect(site.generate_next_sample_entity_id!).to eq(other_site.generate_next_sample_entity_id!)
    end

    it "should return a valid id to be used as sample identifier" do
      entity_id = site.generate_next_sample_entity_id!
      expect {
        SampleIdentifier.make!(site: site, entity_id: entity_id)
      }.to change(SampleIdentifier, :count).by(1)
    end

    it "should skip existing sample identifiers of site" do
      SampleIdentifier.make!(site: site, entity_id: "100000")
      SampleIdentifier.make!(site: site, entity_id: "100001")
      SampleIdentifier.make!(site: site, entity_id: "100003")

      other_site = Site.make!
      SampleIdentifier.make!(site: other_site, entity_id: "100002")

      expect(site.generate_next_sample_entity_id!).to eq("100002")
      expect(site.generate_next_sample_entity_id!).to eq("100004")
      expect(site.generate_next_sample_entity_id!).to eq("100005")
    end

    it "should skip existing sample identifiers of site within time window" do
      site.sample_id_reset_policy = "weekly"
      site.save!

      begin
        Timecop.freeze(Time.utc(2015, 12,  7, 15,  0, 0))
        SampleIdentifier.make!(site: site, entity_id: "100000")
        SampleIdentifier.make!(site: site, entity_id: "100001")

        Timecop.freeze(Time.utc(2015, 12,  14, 15,  0, 0))
        SampleIdentifier.make!(site: site, entity_id: "100002")

        expect(site.generate_next_sample_entity_id!).to eq("100000")
        expect(site.generate_next_sample_entity_id!).to eq("100001")
        expect(site.generate_next_sample_entity_id!).to eq("100003")
      ensure
        Timecop.return
      end
    end
  end

  context "within" do
    let!(:site) { Site.make! }
    let!(:subsite) { Site.make! parent: site, institution: site.institution }
    let!(:other_site) { Site.make! }

    it "institution, no exclusion, should show all sites assigned" do
      expect(Site.within(site.institution).to_a).to eq([site, subsite])
    end

    it "institution, with exclusion, should show only direct children" do
      expect(Site.within(site.institution,true).to_a).to eq([site])
    end

    it "site, with exclusion, should show only direct children" do
      expect(Site.within(site,true).to_a).to eq([subsite])
    end

    it "institution should not show sites from other institutions" do
      expect(Site.within(other_site.institution).to_a).to eq([other_site])
    end
  end
end
