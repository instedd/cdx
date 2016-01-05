class ApplicationMailer < ActionMailer::Base
  helper :mailer

  default from: ENV['MAILER_SENDER']
  layout 'mailer'
end
