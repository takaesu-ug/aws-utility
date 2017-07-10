#!/usr/bin/env ruby
# execution command
# ./smtp_send.rb port_str user password

require 'net/smtp'

port         = 587 # 465 or 587 or 25
user         = 'USER ACCESS KEY'
pass         = 'PASSWORD SECRET ACCESS KEY'
hello_domain = 'takapra.com'
from         = 'from@takapra.com'
to           = 'to@takapra.com'
subject      = 'test_hello ああああ'
message      = <<-MESSAGE
aaaa
bbbb
ほげふが
               MESSAGE
data = <<-DATA
From: #{from}
To: #{to}
Subject: #{subject}
Date: #{Time.now}

#{message} PORT: #{port}
       DATA

def smtp(port)
  Net::SMTP.new('email-smtp.us-west-2.amazonaws.com', port).tap do |smtp|
    if port == 465
      smtp.enable_tls # 465ポート(SMTPS)
    elsif port == 587 || port == 25
      smtp.enable_starttls # 587, 25ポート(STARTTLS)
    else
      raise
    end
  end
end

smtp = smtp(port)
smtp.start(hello_domain, user, pass, :login)
smtp.send_message(data, from, to)
smtp.finish
