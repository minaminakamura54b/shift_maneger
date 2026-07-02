class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "onboarding@resend.dev")
  layout "mailer"
end
