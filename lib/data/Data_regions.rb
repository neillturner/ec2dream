require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

class Data_regions

  def initialize(owner)
    puts "Data_regions.initialize"
    @ec2_main = owner
  end

  # List Regions
  #
  # Returns a array of strings containing region urls for accessing api
  #
  def all(type,platform="")
    data = Array.new
    if  platform == "amazon"
      case type
      when "EC2"
        data.push("https://ec2.us-east-1.amazonaws.com/ (Virgina)")
        data.push("https://ec2.us-west-1.amazonaws.com/ (California)")
        data.push("https://ec2.us-west-2.amazonaws.com/ (Oregon)")
        data.push("https://ec2.eu-west-1.amazonaws.com/ (Ireland)")
        data.push("https://ec2.eu-central-1.amazonaws.com/ (Frankfurt)")
        data.push("https://ec2.ap-southeast-1.amazonaws.com/ (Singapore)")
        data.push("https://ec2.ap-southeast-2.amazonaws.com/ (Sydney)")
        data.push("https://ec2.ap-northeast-1.amazonaws.com/ (Tokyo)")
        data.push("https://ec2.sa-east-1.amazonaws.com/ (Sao Paulo)")
        data.push("https://ec2.us-gov-west-1.amazonaws.com/ (US GovCloud)")
      when "AS"
        data.push("https://autoscaling.us-east-1.amazonaws.com/ (Virgina)")
        data.push("https://autoscaling.us-west-1.amazonaws.com/ (California)")
        data.push("https://autoscaling.us-west-2.amazonaws.com/ (Oregon)")
        data.push("https://autoscaling.eu-west-1.amazonaws.com/ (Ireland)")
        data.push("https://autoscaling.eu-central-1.amazonaws.com/ (Frankfurt)")
        data.push("https://autoscaling.ap-southeast-1.amazonaws.com/ (Singapore)")
        data.push("https://autoscaling.ap-southeast-2.amazonaws.com/ (Sydney)")
        data.push("https://autoscaling.ap-northeast-1.amazonaws.com/ (Tokyo)")
        data.push("https://autoscaling.sa-east-1.amazonaws.com/ (Sao Paulo)")
        data.push("https://autoscaling.us-gov-west-1.amazonaws.com/ (US GovCloud)")
      end
    elsif  platform == "openstack_rackspace" and type == "EC2"
      data.push('https://dfw.servers.api.rackspacecloud.com/v2 (Dallas)')
      data.push('https://ord.servers.api.rackspacecloud.com/v2 (Chicago)')
      data.push('https://lon.servers.api.rackspacecloud.com/v2 (London)')
      data.push('https://iad.servers.api.rackspacecloud.com/v2 (Northern Virginia)')
      data.push('https://syd.servers.api.rackspacecloud.com/v2 (Sydney)')
      data.push('https://hkg.servers.api.rackspacecloud.com/v2 (Hong Kong)')
    elsif  platform == "google"
      data.push('us-central1')
      data.push('europe-central1')
    elsif  platform == "cloudfoundry"
      data.push("http://api.vcap.me                                   (Local CloudFoundry")
      data.push("http://api.aws.af.cm                                (AppFog - AWS service)")
      data.push("http://api.hp.af.cm                                  (AppFog - HP Cloud service)")
      data.push("http://api.joyent.af.cm                           (AppFog - Joyent service)")
      data.push("http://api.rackspace.af.cm                      (AppFog - Rackspace service)")
      data.push("http://api.cloudfoundry.hpcloud.com/ (HP Cloud Services)")
      data.push("http://api.gofoundry.net                         (Iron Foundry)")
      data.push("https://api.stacka.to                                 (Stackato Sandbox)")
      data.push("http://api.cloudfoundry.com                 (VMware CloudFoundry)")
      data.push("http://api.{Domain}.cloudfoundry.me  (VMware Micro CloudFoundry)")
      data.push("{Cloud Controller URL}                            (Other)")
    end
    return data
  end
end