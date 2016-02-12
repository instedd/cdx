include Alerts

class HourlyUtilizationEfficiencyJob
  include Sidekiq::Worker

# if the timespan is say 4 hours , sampleid-12, threshold =2 then : every 4 hours check if a sample id=12 occures less than 2 times , 
# if it has not happened throw an alert otherwise check again in 4 hours.
# if the sample id is correctly detected x times then disable the alert.
  def perform
     alerts = Alert.utilization_efficiency.where("enabled=?",true)
     
     # if it has just alert the user
     alerts.each do |alert|
       
       #calculate in hour the frequency
       utilization_efficiency_hours =0;
       amount = alert.utilization_efficiency_number
       
       #convert the aggregation [days or hours] into hours for calculations
       if alert.aggregation_frequency == "day"
         utilization_efficiency_hours = amount * 24 #24 hours in a day
       else
        utilization_efficiency_hours = amount 
      end
        
        hour_difference = ((Time.parse(DateTime.now.to_s) - Time.parse(alert.utilization_efficiency_last_checked.to_s))/3600).round

hour_difference=99  #debugging 
       
        if hour_difference > utilization_efficiency_hours          
          alert.update_column("utilization_efficiency_last_checked", Time.now)
  
  binding.pry        
      alert_history_count=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', hour_difference.hours.ago).where('for_aggregation_calculation=true').count
       # minimum value for the threshold is one
       if alert.aggregation_threshold < alert_history_count
         alert_history_triggered(alert, alert_history_count)
       end      
     
     else
       #the sample was read x times correctly so the alert does not need to monitor for this sample id, now disable the alert
        binding.pry 
        alert.update_column("enabled", false)
        alert.delete_percolator
     end
   end  
  end
end

# Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '10 * * * *', klass: 'HourlyUtilizationEfficiencyJob')   #run hourly at 10 after each hour

Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '*/2 * * * *', klass: 'HourlyUtilizationEfficiencyJob')   #run hourly at 10 after each hour

