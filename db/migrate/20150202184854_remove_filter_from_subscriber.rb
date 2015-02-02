class RemoveFilterFromSubscriber < ActiveRecord::Migration
  def change
    remove_column :subscribers, :filter, :text
  end
end
