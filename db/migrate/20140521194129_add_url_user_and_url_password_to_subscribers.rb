class AddUrlUserAndUrlPasswordToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :url_user, :string
    add_column :subscribers, :url_password, :string
  end
end
