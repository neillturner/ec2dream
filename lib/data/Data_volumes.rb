require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_volumes

  def initialize(owner)
     puts "data_security_group.initialize"
     @ec2_main = owner
  end

  # Describe EBS volumes.
  #
  # Accepts a list of volumes and/or a set of filters as the last parameter.
  #
  # Filters: attachement.attach-time, attachment.delete-on-termination, attachement.device, attachment.instance-id,
  # attachment.status, availability-zone, create-time, size, snapshot-id, status, tag-key, tag-value, tag:key, volume-id
  #
  #  ec2.describe_volumes #=>
  #      [{:aws_size              => 94,
  #        :aws_device            => "/dev/sdc",
  #        :aws_attachment_status => "attached",
  #        :zone                  => "merlot",
  #        :snapshot_id           => nil,
  #        :aws_attached_at       => "2008-06-18T08:19:28.000Z",
  #        :aws_status            => "in-use",
  #        :aws_id                => "vol-60957009",
  #        :aws_created_at        => "2008-06-18T08:19:20.000Z",
  #        :aws_instance_id       => "i-c014c0a9"},
  #       {:aws_size       => 1,
  #        :zone           => "merlot",
  #        :snapshot_id    => nil,
  #        :aws_status     => "available",
  #        :aws_id         => "vol-58957031",
  #        :aws_created_at => Wed Jun 18 08:19:21 UTC 2008,}, ... ]
  #
  #  ec2.describe_volumes(:filters => { 'availability-zone' => 'us-east-1a', 'size' => '10' })
  #
  def all(filter=nil)
    data = Array.new
    #conn = @ec2_main.environment.connection
    conn = @ec2_main.environment.volume_connection
    if conn != nil
       begin
          if  @ec2_main.settings.openstack
             x = conn.volumes.all
             x.each do |y|
	        r = {}
                r[:aws_id] = y.id.to_s
                r[:aws_created_at]  = y.created_at.to_s
                r[:zone] = y.availability_zone
                r[:aws_size]  = y.size.to_s
                r[:aws_instance_id] = nil
                r[:aws_attachment_status] = nil
                r[:aws_device] = nil

                if  @ec2_main.settings.openstack_rackspace
                   r[:name] = y.display_name
                   r[:description] = y.display_description
                   r[:aws_size] = "#{y.volume_type}-#{r[:aws_size]}"
                   r[:type] = y.volume_type
                   r[:aws_status] =y.state
                   r[:aws_device] = y.volume_type
                   #r[:snapshot_id] = y.snapshot_id.to_s
                else
                   r[:name] = y.name
                   r[:description] = y.description
                   r[:type] = y.type
                   r[:aws_status] =y.status
                   r[:snapshot_id] = y.snapshot_id.to_s
                end
                r[:attachments] = y.attachments
                if y.attachments != nil and y.attachments.instance_of? Array and y.attachments[0] != nil
                     if y.attachments[0]['serverId'] != nil and y.attachments[0]['serverId'] != ""
                      r[:aws_attachment_status] = "attached"
                      r[:aws_instance_id] = y.attachments[0]['serverId'].to_s
                      r[:aws_device] = y.attachments[0]['device'].to_s
                   elsif y.attachments[0]['server_id'] != nil and y.attachments[0]['server_id'] != ""
                      r[:aws_attachment_status] = "attached"
                      r[:aws_instance_id] = y.attachments[0]['server_id'].to_s
                      r[:aws_device] = y.attachments[0]['device'].to_s
                   end
                end
                  data.push(r)
             end
		  elsif @ec2_main.settings.google
					response = conn.list_disks($google_zone)
					if response.status == 200
						x = response.body['items']
						x.each do |r|
						  data.push(r)
						end
					else
						data = []
					end
          elsif conn.instance_of?(Fog::Compute)
             x = conn.volumes.all(filters)
             x.each do |y|
	        r = {}
                r[:aws_id] = y.id.to_s
                r[:aws_created_at]  = y.created_at.to_s
                r[:zone] = y.availability_zone
                r[:aws_size]  = y.size.to_s
                r[:aws_instance_id] = y.server_id.to_s
                r[:aws_status] =y.state
                r[:aws_attachment_status] = nil
                r[:aws_device] = y.device
                r[:snapshot_id] = y.snapshot_id.to_s
                r[:tags] = y.tags
                data.push(r)
             end
          else
              data = conn.describe_volumes([],{:filters => filter})
          end
       rescue
          puts "ERROR: getting all volumes  #{$!}"
       end
    end
    return data
  end


  def get(volume_id)
    if  @ec2_main.settings.google
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.disks.get(volume_id,$goggle_zone)
     else
        raise "Connection Error"
     end
     return data
	else
     data = {}
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        data = conn.volumes.get(volume_id)
     else
        raise "Connection Error"
     end
     return data
	end
  end

  # Create new EBS volume based on previously created snapshot.
  # +Size+ in Gigabytes.
  #
  #  ec2.create_volume('snap-000000', 10, zone) #=>
  #      {:snapshot_id    => "snap-e21df98b",
  #       :aws_status     => "creating",
  #       :aws_id         => "vol-fc9f7a95",
  #       :zone           => "merlot",
  #       :aws_created_at => "2008-06-24T18:13:32.000Z",
  #       :aws_size       => 94}
  #
  def create_volume(availability_zone, size, snapshot_id = nil, name="", description="",type="", iops=0)
     data = {}
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
           options = {}
           if !snapshot_id.nil? and !snapshot_id.empty?
              options['snapshot_id'] = snapshot_id
           end
           if  @ec2_main.settings.openstack_rackspace
              options[:display_name] = name
	      options[:display_description] = description
              options[:availability_zone] = availability_zone
              options[:volume_type] = type
              response = conn.create_volume(size.to_i, options)
           else
              response = conn.create_volume(name, description, size.to_i, options)
           end
           if response.status == 200 or response.status == 202
	      response = response.body["volume"]
	      # this might be hash when implemented
              data[:zone] = response['availabilityZone']
	      data[:aws_created_at] = response['createdAt']
	      data[:aws_size] = response['size']
	      data[:snapshot_id] = response['snapshotId']
	      data[:aws_status] = response['status']
              data[:aws_id] = response['id']
              data[:type] = response['volumeType']
              data[:name] = response['displayName']
              data[:description] = response['displayDescription']
	   else
	      data = {}
	   end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           options = {}
           options['SnapshotId'] = snapshot_id if !snapshot_id.nil? and !snapshot_id.empty?
           options['VolumeType'] = type if type != "" and type != "standard"
           options['Iops'] = iops.to_i if type == "io1"
	   response = conn.create_volume(availability_zone, size.to_i, options)
           if response.status == 200
              response = response.body
              data[:zone] = response['availabilityZone']
	      data[:aws_created_at] = response['createTime']
	      data[:aws_size] = response['size']
	      data[:snapshot_id] = response['snapshotId']
	      data[:aws_status] = response['status']
              data[:aws_id] = response['volumeId']
              data[:type] = response['volumeType']
              data[:iops] = response['iops']
           else
              data = {}
           end
        else
           data  = conn.create_volume(snapshot_id, size, availability_zone)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Attach the specified EBS volume to a specified instance, exposing the
  # volume using the specified device name.
  #
  #  ec2.attach_volume('vol-898a6fe0', 'i-7c905415', '/dev/sdh') #=>
  #    { :aws_instance_id => "i-7c905415",
  #      :aws_device      => "/dev/sdh",
  #      :aws_status      => "attaching",
  #      :aws_attached_at => "2008-03-28T14:14:39.000Z",
  #      :aws_id          => "vol-898a6fe0" }
  #
  def attach_volume(instance_id, volume_id, device)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack_hp or @ec2_main.settings.openstack_rackspace
            response = conn.attach_volume(instance_id, volume_id, device)
            if response.status == 200
              response = response.body
              #data[:aws_attached_at] = response['attachTime']
              #data[:aws_device] = response['device']
              #data[:aws_instance_id] = response['instanceId']
              data[:request_id] = response['id']
              #data[:aws_attachment_status] = response['status']
              data[:aws_id] = response['volumeId']
            else
              data = {}
            end
        elsif  @ec2_main.settings.openstack
            response = conn.attach_volume(volume_id, instance_id, device)
            if response.status == 200
              response = response.body
              #data[:aws_attached_at] = response['attachTime']
              #data[:aws_device] = response['device']
              #data[:aws_instance_id] = response['instanceId']
              data[:request_id] = response['id']
              #data[:aws_attachment_status] = response['status']
              data[:aws_id] = response['volumeId']
            else
              data = {}
            end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	    response = conn.attach_volume(instance_id, volume_id, device)
            if response.status == 200
              response = response.body
              data[:aws_attached_at] = response['attachTime']
              data[:aws_device] = response['device']
              data[:aws_instance_id] = response['instanceId']
              data[:request_id] = response['requestId']
              data[:aws_attachment_status] = response['status']
              data[:aws_id] = response['volumeId']
            else
              data = {}
            end
        else
           data = conn.attach_volume(volume_id, instance_id, device)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Detach the specified EBS volume from the instance to which it is attached.
  #
  #   ec2.detach_volume('vol-898a6fe0') #=>
  #     { :aws_instance_id => "i-7c905415",
  #       :aws_device      => "/dev/sdh",
  #       :aws_status      => "detaching",
  #       :aws_attached_at => "2008-03-28T14:38:34.000Z",
  #       :aws_id          => "vol-898a6fe0"}
  #
  def detach_volume(volume_id, instance_id="", options = {})
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
            if  @ec2_main.settings.openstack_rackspace
               response = conn.delete_attachment(instance_id, volume_id)
            else
               response = conn.detach_volume(instance_id, volume_id)
            end
            if response.status == 202
              #response = response.body
              #data[:aws_attached_at] = response['attachTime']
              #data[:aws_device] = response['device']
              #data[:aws_instance_id] = response['instanceId']
              #data[:request_id] = response['id']
              #data[:aws_attachment_status] = response['status']
              #data[:aws_id] = response['volumeId']
            else
              data = {}
            end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	   response = conn.detach_volume(volume_id, options)
           if response.status == 200
              response = response.body
              data[:aws_attached_at] = response['attachTime']
              data[:aws_device] = response['device']
              data[:aws_instance_id] = response['instanceId']
              data[:request_id] = response['requestId']
              data[:aws_attachment_status] = response['status']
              data[:aws_id] = response['volumeId']
           else
              data = {}
           end
        else
           data = conn.detach_volume(volume_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Delete the specified EBS volume.
  # This does not deletes any snapshots created from this volume.
  #
  #  ec2.delete_volume('vol-b48a6fdd') #=> true
  #
  def  delete_volume(volume_id)
     data = false
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
           response = conn.delete_volume(volume_id)
           if response.status == 202
              data = response.body
           else
              data = {}
           end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	   response = conn.delete_volume(volume_id)
           if response.status == 200
              data = true
           else
              data = false
           end
        else
           data = conn.delete_volume(volume_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end


  # Attach a google disk
  def  attach_disk(instance, zone, disk_name, device_name=nil, disk_mode='READ_WRITE', disk_type='PERSISTENT')
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.attach_disk(instance, zone, disk_name, device_name, disk_mode, disk_type)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Detach a google disk
  def  detach_disk(instance, zone, device_name)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.detach_disk(instance, zone, device_name)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Delete a google disk
  def  delete_disk(name, zone_name)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.delete_disk(name, zone_name)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

   # Insert a google disk
  def  insert_disk(disk_name, zone_name, image_name=nil, opts={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.insert_disk(disk_name, zone_name, image_name, opts)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end



end