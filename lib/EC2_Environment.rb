require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'
#require 'cloudfoundry'
require 'EC2_Settings'
require 'data/Data_availability_zones'
require 'data/Data_security_group'
require 'data/Data_addresses'
require 'data/Data_flavors'
require 'data/Data_regions'
require 'data/Data_images'
require 'data/Data_servers'
require 'data/Data_snapshots'
require 'data/Data_volumes'
require 'data/Data_keypairs'
require 'data/Data_tags'
require 'data/Data_elb'
require 'data/Data_vpc'
require 'data/Data_cloud_watch'
#require 'data/Data_cfy_app'
#require 'data/Data_cfy_service'
#require 'data/Data_cfy_system'
#require 'data/Data_cfy_user'
require 'data/Data_auto_scaling_activities'
require 'data/Data_auto_scaling_groups'
require 'data/Data_auto_scaling_instances'
require 'data/Data_auto_scaling_policies'
require 'data/Data_scheduled_actions'
require 'data/Data_launch_configurations'
require 'data/Data_roles'
require 'cache/EC2_TreeCache'
require 'common/error_message'
require 'common/browser'

class EC2_Environment < FXImageFrame
  def initialize(owner, app)
    @ec2_main = owner
    @ec2 = nil
    @ec2_thread = nil
    @mon = nil
    @s3 = nil
    @as = nil
    @ec2_failed = false
    @ec2_image = nil
    @ec2_image_failed = false
    @ec2_volume = nil
    @ec2_volume_failed = false
    @elb = nil
    @iam = nil
    @env = nil
    @data_security_group = nil
    @data_servers = nil
    @data_roles = nil
    @data_addresses = nil
    @data_keypairs = nil
    @data_tags = nil
    @data_flavors = nil
    @data_regions = nil
    @data_elb = nil
    @data_vpc = nil
    @data_cloud_watch = nil
    #@data_cfy_app = nil
    #@data_cfy_service = nil
    #@data_cfy_system = nil
    #@data_cfy_user = nil
    @data_auto_scaling_activities = nil
    @data_launch_configurations = nil
    @data_auto_scaling_policies = nil
    @data_auto_scaling_groups = nil
    @data_auto_scaling_instances = nil
    @data_scheduled_actions = nil
  end
  def load
    puts "environment.load"
    @settings = @ec2_main.settings
    @env = @settings.get_system("ENVIRONMENT")
    if @env != nil and @env.length>0
      load_env
    else
      load_empty_env
    end
  end
  def initial_load
    puts "environment.initial_load"
    @settings = @ec2_main.settings
    @env = @settings.get_system("ENVIRONMENT")
    @auto = @settings.get_system("AUTO")
    if @env != nil and @env.length>0
      puts "Initial Environment "+@env
    end
    if @env != nil and @env.length>0
      puts "Auto Loaded? "+@auto
    end
    if @env != nil and @env.length>0 and @auto == "true"
      @treeCache = @ec2_main.treeCache
      @treeCache.load_empty
      load_env
    else
      load_empty_env
    end
  end
  def load_env
    puts "environment.load_env"
    reset_connection
    @settings = @ec2_main.settings
    @server = @ec2_main.server
    @server.clear_panel
    @launch = @ec2_main.launch
    @launch.clear_panel
    @secgrp = @ec2_main.secgrp
    @secgrp.clear
    @env = @settings.get_system("ENVIRONMENT")
    @auto = @settings.get_system("AUTO")
    @settings.load
    @treeCache = @ec2_main.treeCache
    @treeCache.load(@env)
    @ec2_main.list.clear
    @ec2_main.list.load("Instance Status") if @settings.amazon
    @ec2_main.app.forceRefresh
  end
  def load_empty_env
    puts "environment.load_empty_env"
    reset_connection
    @settings = @ec2_main.settings
    #@settings.load_system
    @env = ""
    @settings.put_system('ENVIRONMENT', "")
    @auto = false
    @settings.put_system('AUTO', "false")
    if File.exists?(ENV['EC2DREAM_HOME']+"/system/system.properties")
      @settings.save_system
    end
    #show_repository_loc
    @settings.get_system('REPOSITORY_LOCATION')
    @server = @ec2_main.server
    @server.clear_panel
    @launch = @ec2_main.launch
    @launch.clear_panel
    @secgrp = @ec2_main.secgrp
    @secgrp.clear
    @treeCache = @ec2_main.treeCache
    @treeCache.load_empty
    @ec2_main.app.forceRefresh
  end
  def env
    return @env
  end
  def image_connection
    puts "environment.image_connection"
    platform = @ec2_main.settings.get("EC2_PLATFORM")
    puts "Platform #{platform}"
    if platform == "openstack_hp"
      $ec2_main.cloud.conn("Image")
    elsif platform == "openstack_rackspace"
      $ec2_main.cloud.conn("Compute")
    elsif platform == "openstack"
      $ec2_main.cloud.conn("Image")
    end
  end
  def volume_connection
    puts "environment.volume_connection"
    if  !@ec2_main.settings.openstack
      connection
    else
      settings = @ec2_main.settings
      platform = @ec2_main.settings.get("EC2_PLATFORM")
      puts "Platform #{platform}"
      if platform == "openstack_hp"
        $ec2_main.cloud.conn("BlockStorage")
      elsif platform == "openstack_rackspace"
        $ec2_main.cloud.conn("BlockStorage")
      elsif platform == "openstack"
        $ec2_main.cloud.conn("Volume")
      end
    end
  end
  def connection
    puts "environment.connection"
    platform = @ec2_main.settings.get("EC2_PLATFORM")
    puts "Platform #{platform}"
    $ec2_main.cloud.conn("Compute")
  end
  def connection_failed
    return @ec2_failed
  end
  def set_connection_failed
    @ec2 = nil
    @ec2_failed = true
  end
  def reset_connection
    puts "environment.reset_connection"
    @ec2 = nil
    @ec2_failed = false
    $ec2_main.cloud_reset
  end
  def as_connection
    puts "environment.as_connection"
    $ec2_main.cloud.conn("AutoScaling")
  end
  def reset_as_connection
    @as = nil
  end
  def as_connection_2
    puts "environment.as_connection_2"
    $ec2_main.cloud.conn("AutoScaling")
  end
  def reset_as2_connection
    @as2 = nil
  end
  def mon_connection
    puts "environment.mon_connection"
    $ec2_main.cloud.conn("CloudWatch")
  end
  def reset_mon_connection
    @mon = nil
  end
  def elb_connection
    puts "environment.elb_connection"
    $ec2_main.cloud.conn("ELB")
  end
  def reset_elb_connection
    @elb = nil
  end
  def cf_connection
    puts "environment.cf_connection"
    $ec2_main.cloud.conn("CloudFormation")
  end
  def reset_cf_connection
    @cf = nil
  end
  def iam_connection
    puts "environment.iam_connection"
    $ec2_main.cloud.conn("IAM")
  end
  def reset_iam_connection
    @iam = nil
  end
  def security_group
    puts "environment.security_group"
    if @data_security_group != nil
      return @data_security_group
    else
      @data_security_group = Data_security_group.new(@ec2_main)
    end
  end
  def addresses
    puts "environment.addresses"
    if @data_addresses != nil
      return @data_addresses
    else
      @data_addresses = Data_addresses.new(@ec2_main)
    end
  end
  def availability_zones
    puts "environment.availability_zones"
    if @data_availability_zones != nil
      return @data_availability_zones
    else
      @data_availability_zones = Data_availability_zones.new(@ec2_main)
    end
  end
  def keypairs
    puts "environment.keypairs"
    if @data_keypairs != nil
      return @data_keypairs
    else
      @data_keypairs = Data_keypairs.new(@ec2_main)
    end
  end

  def tags
    puts "environment.tags"
    if @data_tags != nil
      return @data_tags
    else
      @data_tags = Data_tags.new(@ec2_main)
    end
  end

  def flavors
    puts "environment.flavors"
    if @data_flavors != nil
      return @data_flavors
    else
      @data_flavors = Data_flavors.new(@ec2_main)
    end
  end

  def regions
    puts "environment.regions"
    if @data_regions != nil
      return @data_regions
    else
      @data_regions = Data_regions.new(@ec2_main)
    end
  end

  def images
    puts "environment.images"
    if @data_images != nil
      return @data_images
    else
      @data_images = Data_images.new(@ec2_main)
    end
  end

  def servers
    puts "environment.servers"
    if @data_servers != nil
      return @data_servers
    else
      @data_servers = Data_servers.new(@ec2_main)
    end
  end

  def snapshots
    puts "environment.snapshots"
    if @data_snapshots != nil
      return @data_snapshots
    else
      @data_snapshots = Data_snapshots.new(@ec2_main)
    end
  end
  def volumes
    puts "environment.volumes"
    if @data_volumes != nil
      return @data_volumes
    else
      @data_volumes = Data_volumes.new(@ec2_main)
    end
  end
  def elb
    puts "environment.elb"
    if @data_elb != nil
      return @data_elb
    else
      @data_elb = Data_elb.new(@ec2_main)
    end
  end
  def vpc
    puts "environment.vpc"
    if @data_vpc != nil
      return @data_vpc
    else
      @data_vpc = Data_vpc.new(@ec2_main)
    end
  end
  def cloud_watch
    puts "environment.cloud_watch"
    if @data_cloud_watch != nil
      return @data_cloud_watch
    else
      @data_cloud_watch = Data_cloud_watch.new(@ec2_main)
    end
  end
  #def cfy_app
  #  puts "environment.cfy_app"
  #  if @data_cfy_app != nil
  #    return @data_cfy_app
  #  else
  #    @data_cfy_app = Data_cfy_app.new(@ec2_main)
  #  end
  #end
  #def cfy_service
  #  puts "environment.cfy_service"
  #  if @data_cfy_service != nil
  #    return @data_cfy_service
  #  else
  #    @data_cfy_service = Data_cfy_service.new(@ec2_main)
  #  end
  #end
  #def cfy_system
  #  puts "environment.cfy_system"
  #  if @data_cfy_system != nil
  #    return @data_cfy_system
  #  else
  #    @data_cfy_system = Data_cfy_system.new(@ec2_main)
  #  end
  #end
  #def cfy_user
  #  puts "environment.cfy_user"
  #  if @data_cfy_user != nil
  #    return @data_cfy_user
  #  else
  #    @data_cfy_user = Data_cfy_user.new(@ec2_main)
  #  end
  #end
  def roles
    puts "environment.roles"
    if @data_roles != nil
      return @data_roles
    else
      @data_roles = Data_roles.new(@ec2_main)
    end
  end
  def auto_scaling_activities
    puts "environment.auto_scaling_activities"
    if @data_auto_scaling_activities != nil
      return @data_auto_scaling_activities
    else
      @data_auto_scaling_activities = Data_auto_scaling_activities.new(@ec2_main)
    end
  end

  def auto_scaling_groups
    puts "environment.auto_scaling_groups"
    if @data_auto_scaling_groups != nil
      return @data_auto_scaling_groups
    else
      @data_auto_scaling_groups = Data_auto_scaling_groups.new(@ec2_main)
    end
  end
  def auto_scaling_instances
    puts "environment.auto_scaling_instances"
    if @data_auto_scaling_instances != nil
      return @data_auto_scaling_instances
    else
      @data_auto_scaling_instances = Data_auto_scaling_instances.new(@ec2_main)
    end
  end

  def auto_scaling_policies
    puts "environment.auto_scaling_policies"
    if @data_auto_scaling_policies != nil
      return @data_auto_scaling_policies
    else
      @data_auto_scaling_policies = Data_auto_scaling_policies.new(@ec2_main)
    end
  end

  def scheduled_actions
    puts "environment.scheduled_actions"
    if @data_scheduled_actions != nil
      return @data_scheduled_actions
    else
      @data_scheduled_actions = Data_scheduled_actions.new(@ec2_main)
    end
  end
  def launch_configurations
    puts "environment.launch_configurations"
    if @data_launch_configurations != nil
      return @data_launch_configurations
    else
      @data_launch_configurations = Data_launch_configurations.new(@ec2_main)
    end
  end

end
