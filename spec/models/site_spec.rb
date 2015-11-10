require 'spec_helper'

describe Site do
  it "computes prefix for self" do
    site = Site.make
    expect(site.prefix).to eq(site.uuid.to_s)
  end

  it "computes prefix for self with parent" do
    site1 = Site.make
    site2 = Site.make parent_id: site1.id
    expect(site2.prefix).to eq("#{site1.uuid}.#{site2.uuid}")
  end

  it "computes prefix for self with parent and grandparent" do
    site1 = Site.make
    site2 = Site.make parent_id: site1.id
    site3 = Site.make parent_id: site2.id
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
end
