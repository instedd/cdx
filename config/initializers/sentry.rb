require "sentry-raven"

Raven.configure do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.current_environment = ENV.fetch("SENTRY_CDX_ENVIRONMENT") { Rails.env.to_s }
  config.release = Cdp.version

  config.async = lambda do |event|
    SentryJob.perform_later(event)
  end

  config.send_modules = false

  config.sanitize_fields += %w[
    filename
    fields
    sensitive_data
    first_name
    last_name
    email
    phone
    token
    key
    data
    raw_data
    index_failure_data
    message
    description
    result
    ftp
    location_geoid
    lat
    lng
    address
    name
    sms
    patient_id
    encounter_id
  ]
  #config.sanitize_fields_excluded += %w[]
  #config.sanitize_http_headers += %w[]
end
