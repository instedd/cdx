class AddAuthTokenToSubscribers < ActiveRecord::Migration
  def change
    add_column :subscribers, :auth_token, :string
  end
end
