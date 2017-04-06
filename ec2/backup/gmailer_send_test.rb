require 'rubygems'
require "./gmailer"

class Hoge
  attr_accessor :backtrace

  def initialize
    @backtrace = ["TEST","aaaa","bbbb"]
  end
end

GMailer.sendmail(Hoge.new)
