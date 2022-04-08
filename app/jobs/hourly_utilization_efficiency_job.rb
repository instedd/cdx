require "alerts"
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
      begin
        #calculate in hours the frequency
        utilization_efficiency_hours = 0
        amount = alert.utilization_efficiency_number

        #convert the aggregation [days or hours] into hours for calculations
        hours_per_day = 24
        if alert.aggregation_frequency == "month"
          utilization_efficiency_hours = amount * hours_per_day * 30 
        elsif alert.aggregation_frequency == "week"
          utilization_efficiency_hours = amount * hours_per_day * 7 
        elsif alert.aggregation_frequency == "day"
          utilization_efficiency_hours = amount * hours_per_day 
        else
          utilization_efficiency_hours = amount
        end

        hour_difference = (Time.parse(DateTime.now.to_s) - Time.parse(alert.utilization_efficiency_last_checked.to_s))/3600
        if hour_difference > utilization_efficiency_hours
          alert.update_column("utilization_efficiency_last_checked", Time.now)
          alert_history_count=AlertHistory.where('alert_id=?', alert.id).where('created_at >= ?', alert.utilization_efficiency_last_checked).where('for_aggregation_calculation=true').count

          # minimum value for the threshold is one
          if alert_history_count <= alert.aggregation_threshold
            alert_history_triggered(alert, alert_history_count)
          else
            #the sample was read x times correctly so the alert does not need to monitor for this sample id, now disable the alert
            # or do we reset the utilization_efficiency_last_checked and recheck??
            alert.update_column("enabled", false)
            alert.delete_percolator
          end
        end

      rescue => e
        Rails.logger.error { "Encountered an error when trying to run background job HourlyUtilizationEfficiencyJob : #{alert.id}, #{e.message} #{e.backtrace.join("\n")}" }
      end
    end
  end
end

#run every 30 mins to give more accuracy, +/- 30 mins
Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '*/30 * * * *', klass: 'HourlyUtilizationEfficiencyJob')


#every 2 minsutes for testing
#Sidekiq::Cron::Job.create(name: 'Alert Utilization Efficiency - hourly', cron: '*/2 * * * *', klass: 'HourlyUtilizationEfficiencyJob')
