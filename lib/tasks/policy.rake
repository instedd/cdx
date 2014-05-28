namespace :policy do
  desc "Make a user a superadmin"
  task :make_superadmin, [:user_id] => :environment do |task, args|
    unless args[:user_id]
      puts "Usage: $> rake policy:make_superadmin[{user_id}] RAILS_ENV={env}"
      exit
    end

    user = User.find args[:user_id]

    superadmin = Policy.superadmin
    superadmin.user_id = user.id
    superadmin.granter_id = user.id
    superadmin.save!
  end
end
