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
  GENERATION = 10
  BACKUP_MOUNT_POINTS = %w{ /data }
  SNAPSHOT_STATUS_ALERT_NUM = 2
end

class EBSSnapshot
  attr_accessor :access_key, :secret_key, :instance_id, :region_id,
                :generation, :name_parts, :name, :description

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
    @name_parts = "#{@instance_id}_#{script_basename}"
    @name    = "#{hostname}_#{now.strftime("%Y%m%d%H%M%S")}_#{@name_parts}"
    @description = "#{now.strftime("%Y/%m/%d %H:%M:%S")} backuped by #{$0}"
  end

  def run
    create_snapshot
    check_snapshot_status
    delete_snapshot
  end

  def ec2
    AWS.config(:access_key_id => access_key, :secret_access_key => secret_key, :region => region_id)
    AWS::EC2.new
  end

  def ec2_client
    ec2.client
  end

  # 次の形式でハッシュを返す (volume_device => AWS::EC2::Attachment)
  def instance_attachment_volumes
    @instance_attachment_volumes ||= ec2.instances[instance_id].attachments
  end

  # 次の形式でハッシュに変換して (mount_point => volume_device)
  # volume_deviceは /dev/sdf1 が /dev/xvdf1 となっってしまうようなので 「xv」 を 「s」 に置換する
  # http://dqn.sakusakutto.jp/2012/08/amazonec2ebsdevsdf_devxvdj.html
  def volume_device_hash_of_each_mount_point
    MySettings::BACKUP_MOUNT_POINTS.each_with_object({}) do |mount_point, hash|
      vol_device = `df  |awk '{ if ($6 == "#{mount_point}") print $1 }'`.chop
      hash[mount_point] = vol_device.sub("xv","s") unless vol_device.empty?
    end
  end

  def should_deleted_snapshots(volume_id)
    sort_snapshots = ec2.snapshots.filter("volume-id", volume_id).filter("tag:Name", "*_#{name_parts}_*").to_a.sort_by { |x| x.start_time }.reverse
    sort_snapshots[generation.to_i, sort_snapshots.size]
  end

  def create_snapshot
    volume_device_hash_of_each_mount_point.each do |mount_point, vol_device|
      volume_id = instance_attachment_volumes[vol_device].volume.id
      snapshot  = ec2.volumes[volume_id].create_snapshot(description)
      snapshot.add_tag('Name', :value => name + "_(#{mount_point}_#{volume_id})")
    end
  end

  def check_snapshot_status
    my_snapshots = ec2.snapshots.filter("tag:Name", "*_#{name_parts}_*")
    pending_num = my_snapshots.inject(0) do |total_num, snapshot|
      total_num += 1 if snapshot.status === :pending
      total_num
    end
    raise "pending status Alert count: #{pending_num}" if pending_num > MySettings::SNAPSHOT_STATUS_ALERT_NUM
  end

  def delete_snapshot
    volume_device_hash_of_each_mount_point.each do |mount_point, vol_device|
      volume_id = instance_attachment_volumes[vol_device].volume.id
      delete_snapshots = should_deleted_snapshots(volume_id) || []

      delete_snapshots.each do |snapshot|
        snapshot.delete
      end
    end
  end

end


## Run Scripts

if __FILE__ == $0
  begin
    EBSSnapshot.run
  rescue Exception => e
    GMailer.sendmail(e)
  end
end
