#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'net/smtp'

from_addr = ''
to_addr = ''

message = <<EOM
From: #{from_addr}
To: #{to_addr}
Subject: test

test
EOM

smtpserver = Net::SMTP.new('smtp.gmail.com', 587)
smtpserver.enable_starttls
smtpserver.start('localhost.localdomain', "MAIL_USER_NAME", "MAIL_PASSWORD", :plain) { |smtp|
smtp.send_message message, from_addr, to_addr
}
