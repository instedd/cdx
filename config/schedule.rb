# Use this file to easily define all of your cron jobs.
#
#
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

set :output, "./cron_log.log"
set :environment, Rails.env

# GEM_PATH and other environment variables are not being correctly loaded when running in a crontab
# so we load them in the job to be able to run it
# see: https://github.com/javan/whenever/issues/656
ENV.each { |k, v| env(k, v) }

every 1.week do
  rake "assay_files:garbage_collector"
end
