require 'rubygems'
require 'aws-sdk'
require "open-uri"
require "awesome_print"

require "./common_settings"
require "./gmailer"

module MySettings
  ACCESS_KEY = CommonSettings::ACCESS_KEY
  SECRET_KEY = CommonSettings::SECRET_KEY
  HOSTNAME   = CommonSettings::HOSTNAME
  GENERATION = 3
end

class AMIBackup
  attr_accessor :access_key, :secret_key, :instance_id, :region_id,
                :generation, :name_parts, :ami_name, :description

  def self.run
    self.new.run
  end

  def initialize(opt = {})
    now = Time.now
    script_basename = File.basename($0, ".*")
    hostname = MySettings::HOSTNAME

    @access_key  = MySettings::ACCESS_KEY
    @secret_key  = MySettings::SECRET_KEY
    @generation  = MySettings::GENERATION

    @instance_id = open("http://169.254.169.254/latest/meta-data/instance-id").read
    @region_id   = open("http://169.254.169.254/latest/meta-data/placement/availability-zone").read.chop
    @name_parts = "#{script_basename}_#{@instance_id}"
    @ami_name    = "#{hostname}_#{now.strftime("%Y%m%d%H%M%S")}_#{@name_parts}"
    @description = "#{now.strftime("%Y/%m/%d %H:%M:%S")} backuped by #{$0}"
  end

  def run
    create_ami
    delete_ami
  end

  def ec2_client
    AWS.config(:access_key_id => access_key, :secret_access_key => secret_key, :region => region_id)
    AWS::EC2.new.client
  end

  def should_deleted_images
    images = ec2_client.describe_images(:filters => [{:name => "name", :values => ["*_#{name_parts}"]}])[:images_set]
    sort_images = images.sort_by { |x| x[:name] }.reverse
    sort_images[generation.to_i, images.size]
  end

  def create_ami
    ec2_client.create_image(:instance_id => instance_id,
                            :name        => ami_name,
                            :description => description,
                            :no_reboot   => true)
  end

  def delete_ami
    delete_images = should_deleted_images
    unless delete_images.nil?
      delete_images.each do |image|
        #AMI削除
        ec2_client.deregister_image(:image_id => image[:image_id])
        #AMIに紐づくスナップショット削除
        image[:block_device_mapping].each do |device|
          #ap device[:ebs][:snapshot_id]
          ec2_client.delete_snapshot(:snapshot_id => device[:ebs][:snapshot_id])
        end
      end
    end
  end
end


## Run Scripts
if __FILE__ == $0
  begin
    AMIBackup.run
  rescue Exception => e
    GMailer.sendmail(e)
  end
end
