ActiveAdmin.register User do
   menu
    
  actions :all, except: [:destroy] #just view,edit
   
   #remove the delete batch action
  batch_action :destroy, false
  batch_action :disable, confirm: "Are you sure?" do |ids|
    #redirect_to collection_path
    ids.each do |user_id|
      User.find(user_id).update_attribute(:active, false)
    end
    redirect_to admin_users_path
  end

  batch_action :enable, confirm: "Are you sure?" do |ids|
    #redirect_to collection_path
    ids.each do |user_id|
      User.find(user_id).update_attribute(:active, true)
    end
    redirect_to admin_users_path
  end
           
  batch_action :archive, confirm: "Are you sure?" do |ids|
    #redirect_to collection_path
    ids.each do |user_id|
      #TODO put into one update
      User.find(user_id).update_attribute(:archived, true)
      User.find(user_id).update_attribute(:active, false)
    end
    redirect_to admin_users_path
  end

  batch_action :unarchive, confirm: "Are you sure?" do |ids|
    #redirect_to collection_path
    ids.each do |user_id|
      User.find(user_id).update_attribute(:archived,  false)
    end
    redirect_to admin_users_path
  end           
           
    
  # Index
  index do
    selectable_column
    column :email
    column :created_at
    column :login_count
    column :last_sign_in_at
    column "Enabled", :active
    column "Archived", :archived
    actions
  end
  
  
#  action_item :only => :index do
#     link_to 'Upload User List', :action => 'upload_csv'
#   end  
    
  filter :email
  filter :active , label: 'Enabled' 
  filter :archived , label: 'Archived' 
  filter :created_at
  
  scope :active
  scope :archived
  
  form do |f|
    f.inputs do
      f.input :email
      f.input :active, label: 'Enabled'
       f.input :archived, label: 'Archived'
    end
    f.actions
  end
  
  permit_params :email, :active, :archived
    
end
