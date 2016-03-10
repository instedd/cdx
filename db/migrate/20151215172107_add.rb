class Add < ActiveRecord::Migration
  def change
  end
end



class AddSiteToAlert < ActiveRecord::Migration
  def change
    change_table :alerts do |t|
      t.references :site
    end   
  end
end


class CreateAlertRecipients < ActiveRecord::Migration
  def change
    create_table :alert_recipients do |t|
      t.references :user, index: true
      t.references :alert, index: true
      t.timestamps
    end
  end
end
