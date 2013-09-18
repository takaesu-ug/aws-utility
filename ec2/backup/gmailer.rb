require "mail"
require 'i18n'
require "awesome_print"

require "./common_settings"

module MailSettings
  HOSTNAME = CommonSettings::HOSTNAME

  module GMailer
    USER_NAME = CommonSettings::GMailer::USER_NAME
    PASSWORD  = CommonSettings::GMailer::PASSWORD
    TO        = CommonSettings::GMailer::TO
    FROM      = CommonSettings::GMailer::FROM
  end
end

class GMailer
  def self.sendmail(e)
    self.new.sendmail(e)
  end

  def initialize(opt = {})
    Mail.defaults do
      delivery_method :smtp, {
        :address              => "smtp.gmail.com",
        :port                 => 587,
        :domain               => 'gmail.com',
        :user_name            => MailSettings::GMailer::USER_NAME,
        :password             => MailSettings::GMailer::PASSWORD,
        :authentication       => :plain,
        :enable_starttls_auto => true
      }
    end
  end

  def sendmail(e)
    Mail.deliver do
      to MailSettings::GMailer::TO
      from MailSettings::GMailer::FROM
      subject "[#{MailSettings::HOSTNAME}] Create Snapshot Backup Error"
      body <<-EOF
Snapshot Backup Error

Error:
#{e}

Backtrace:
#{e.backtrace.join('
')}
EOF
    end
  end

end
