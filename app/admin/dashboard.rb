ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Most Recent Users" do
          ul do
            User.order('created_at DESC').limit(5).map do |user|
              li user.email                 
            end
          end
        end
     end  
          
      column do
        panel "News" do
          para "Welcome to FIND."
        end
      end
          
    end
  
  end # content
end
