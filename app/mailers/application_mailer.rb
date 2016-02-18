class ApplicationMailer < ActionMailer::Base
  helper :mailer

  default from: ENV['MAILER_SENDER'] || 'info@instedd.org'
  layout 'mailer'
end
