class UpdateFilterQueryParameters < ActiveRecord::Migration
  class Filter < ActiveRecord::Base
    serialize :query, JSON
  end

  def up
    Filter.find_each do |filter|
      if filter.query["laboratory"]
        filter.query["laboratory.id"] = filter.query["laboratory"]
        filter.query.delete "laboratory"
      end
      if filter.query["condition"]
        filter.query["test.assays.condition"] = filter.query["condition"]
        filter.query.delete "condition"
      end
      filter.save!
    end
  end

  def down
    Filter.find_each do |filter|
      if filter.query["laboratory.id"]
        filter.query["laboratory"] = filter.query["laboratory.id"]
        filter.query.delete "laboratory.id"
      end
      if filter.query["test.assays.condition"]
        filter.query["condition"] = filter.query["test.assays.condition"]
        filter.query.delete "test.assays.condition"
      end
      filter.save!
    end
  end
end
