require "#{Rails.root}/lib/demo_data"

namespace :demo do

include DemoData

  desc "Insert demo data for all the device templates"
  task :demodata, [:repeat] => :environment do |task, args|
    unless args[:repeat]
      puts "Usage: $> rake demo:demodata[{repeat}] RAILS_ENV={env}"
      exit
    end
    
    if args[:repeat].to_s != args[:repeat].to_i.to_s
      puts "parameter must be an integer"
      exit
    end
   
    error_reason = insert_demo_data(args[:repeat].to_i) 
    if error_reason
      puts "Error: "+error_reason
    end
    
  end
end