class AddMainPhoneNumberAndEmailAddressToSites < ActiveRecord::Migration
  def change
    add_column :sites, :main_phone_number, :string
    add_column :sites, :email_address, :string
  end
end
