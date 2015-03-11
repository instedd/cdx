class AddVerbToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :verb, :string, :default => 'GET'
  end
end
