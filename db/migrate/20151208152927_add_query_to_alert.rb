class AddQueryToAlert < ActiveRecord::Migration
  def change
    add_column :alerts, :query, :text
  end
end
