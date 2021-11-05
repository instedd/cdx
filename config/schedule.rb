# Use this file to easily define all of your cron jobs.
#

set :output, "./cron_log.log"
set :environment, Rails.env

ENV.each { |k, v| env(k, v) }

every 1.week do
  rake "assay_files:garbage_collector"
end
