class AddFilterIdToSubscriber < ActiveRecord::Migration
  def change
    add_reference :subscribers, :filter, index: true
  end
end
