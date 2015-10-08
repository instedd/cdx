class SetUuidForInstitutionsAndSites < ActiveRecord::Migration
  class Institution < ActiveRecord::Base; end
  class Laboratory < ActiveRecord::Base; end

  def up
    Institution.find_each do |x|
      x.uuid ||= Guid.new.to_s
      x.save!
    end

    Laboratory.find_each do |x|
      x.uuid ||= Guid.new.to_s
      x.save!
    end
  end

  def down
  end
end
