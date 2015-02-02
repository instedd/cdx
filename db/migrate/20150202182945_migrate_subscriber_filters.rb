class MigrateSubscriberFilters < ActiveRecord::Migration
  class Subscriber < ActiveRecord::Base
    self.table_name = "subscribers"
  end

  class Filter < ActiveRecord::Base
    self.table_name = "filters"
  end

  def up
    Subscriber.find_each do |subscriber|
      filter = Filter.create! user_id: subscriber.user_id, name: "Filter for '#{subscriber.name}' subscriber", params: subscriber.filter
      subscriber.update_attributes! filter_id: filter.id
    end
  end

  def down
    Subscriber.find_each do |subscriber|
      filter = Filter.find(subscriber.filter_id)
      subscriber.update_attributes! filter: filter.params
      filter.delete
    end
  end
end
