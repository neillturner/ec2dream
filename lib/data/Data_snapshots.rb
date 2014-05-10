require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_snapshots

  def initialize(owner)
     puts "data_snapshots.initialize"
     @ec2_main = owner
  end

  # Describe EBS snapshots.
  #
  # Accepts a list of snapshots and/or options: :restorable_by, :owner and :filters
  #
  # Options: :restorable_by => Array or String, :owner => Array or String, :filters => Hash
  #
  # Filters: description, owner-alias, owner-id, progress, snapshot-id, start-time, status, tag-key,
  # tag-value, tag:key, volume-id, volume-size
  #
  #  ec2.describe_snapshots #=>
  #    [{:aws_volume_size=>2,
  #      :tags=>{},
  #      :aws_id=>"snap-d010f6b9",
  #      :owner_alias=>"amazon",
  #      :aws_progress=>"100%",
  #      :aws_status=>"completed",
  #      :aws_description=>
  #       "Windows 2003 R2 Installation Media [Deprecated] - Enterprise Edition 64-bit",
  #      :aws_owner=>"711940113766",
  #      :aws_volume_id=>"vol-351efb5c",
  #      :aws_started_at=>"2008-10-20T18:23:59.000Z"},
  #     {:aws_volume_size=>2,
  #      :tags=>{},
  #      :aws_id=>"snap-a310f6ca",
  #      :owner_alias=>"amazon",
  #      :aws_progress=>"100%",
  #      :aws_status=>"completed",
  #      :aws_description=>"Windows 2003 R2 Installation Media 64-bit",
  #      :aws_owner=>"711940113766",
  #      :aws_volume_id=>"vol-001efb69",
  #      :aws_started_at=>"2008-10-20T18:25:53.000Z"}, ... ]
  #
  def all(owner=nil,filter=nil)
    data = Array.new
    conn = @ec2_main.environment.volume_connection
    if conn != nil
       begin
          if  @ec2_main.settings.openstack
             conn = @ec2_main.environment.connection if !@ec2_main.settings.openstack_hp and !@ec2_main.settings.openstack_rackspace
             x  = conn.snapshots.all
             x.each do |y|
	        r = {}
                r[:aws_id] = y.id.to_s
                if  @ec2_main.settings.openstack_rackspace
                   r[:name] = y.display_name
                   r[:aws_description] = y.display_description
                   r[:zone] = y.availability_zone
                   r[:aws_status] = y.state
                else
                   r[:name] = y.name
	           r[:aws_description] = y.description
	           r[:aws_status] = y.status
	        end
	        r[:aws_started_at] = y.created_at.to_s
	        r[:aws_volume_id] = y.volume_id.to_s
	        r[:aws_progress] = nil
	        r[:aws_volume_size] = y.size.to_s
	        r[:aws_owner] = nil
	        r[:aws_owner_alias] = nil
	        data.push(r)
	     end
		      elsif @ec2_main.settings.google
					response = conn.list_snapshots
					if response.status == 200
						x = response.body['items']
						x.each do |r|
						  r[:aws_id] = r['name']
						  data.push(r)
						end
					else
						data = []
					end
          elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
             filter = {} if filter == nil
             x = conn.snapshots.all(filter)
             x.each do |y|
	        r = {}
                r[:aws_id] = y.id.to_s
 	        r[:aws_description] = y.description
	        r[:aws_started_at] = y.created_at.to_s
	        r[:aws_volume_id] = y.volume_id.to_s
	        r[:aws_status] = y.state
	        r[:aws_progress] = y.progress
	        r[:aws_volume_size] = y.volume_size.to_s
	        r[:aws_owner] = y.owner_id
	        r[:aws_owner_alias] = nil
                data.push(r)
             end
          else
             data = conn.describe_snapshots({:owner => owner, :filters => filter})
          end
       rescue
          puts "ERROR: getting all snapshots  #{$!}"
       end
    end
    return data
  end


  def get(snapshot_id)
     data = {}
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
           data = conn.snapshots.get(volume_id)
        else
           data = conn.snapshots.get(snapshot_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Create a snapshot of specified volume.
  #
  #  ec2.create_snapshot('vol-898a6fe0', 'KD: WooHoo!!') #=>
  #    {:aws_volume_id=>"vol-e429db8d",
  #     :aws_started_at=>"2009-10-01T09:23:38.000Z",
  #     :aws_description=>"KD: WooHoo!!",
  #     :aws_owner=>"648770000000",
  #     :aws_progress=>"",
  #     :aws_status=>"pending",
  #     :aws_volume_size=>1,
  #     :aws_id=>"snap-3df54854"}
  #
  def create_volume_snapshot(volume_id, name, description, force=false)
     data = nil
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
           options = {}
	   if force == true
	      options['force'] = true
	   end
           if  @ec2_main.settings.openstack_rackspace
              options[:display_name] = name
	      options[:display_description] = description
	      if force == true
	         options[:force] = true
	      end
              data = conn.create_snapshot(volume_id, options)
           elsif  @ec2_main.settings.openstack_hp
              if force == true
	        options['force'] = true
	      end
              data = conn.create_snapshot(name, description, volume_id, options)
           else
              data = conn.create_volume_snapshot(volume_id, name, description, force)
           end
           if data.status == 200
	      data = data.body["snapshot"]
	   else
	      data = nil
           end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	    response = conn.create_snapshot(volume_id, description)
            if response.status == 200
              response = response.body
               data = {}
              data[:aws_id] = response['snapshotId']
	      data[:aws_description] = response['description']
	      data[:aws_started_at] = response['startTime']
	      data[:aws_volume_id] = response['volumeId']
	      data[:aws_status] = response['status']
	      data[:aws_progress] = response['progess']
	      data[:aws_volume_size] = response['volumeSize']
	      data[:aws_owner] = response['ownerId']
	    else
	      data = {}
            end
        else
           data = conn.create_snapshot(volume_id,description)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  def get_snapshot_details(snapshot_id)
     data = {}
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
           response = conn.get_snapshot_details(snapshot_id)
           if response.status == 200
	      data = data.body["snapshot"]
	   else
	      data = nil
           end
        else
           data = conn.get_snapshot_details(snapshot_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Delete the specified snapshot.
  #
  #  ec2.delete_snapshot('snap-55a5403c') #=> true
  #
  def  delete_snapshot(snapshot_id, zone_name=nil)
    if zone_name.nil?
     data = false
     conn = @ec2_main.environment.volume_connection
     if conn != nil
        if  @ec2_main.settings.openstack
            response = conn.delete_snapshot(snapshot_id)
            if response.status == 200
	       data = true
	    else
	       data = false
            end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	    response = conn.delete_snapshot(snapshot_id)
            if response.status == 200
	       data = true
	    else
	       data = false
            end
        else
           data = conn.delete_snapshot(snapshot_id)
        end
     else
        raise "Connection Error"
     end
     return data
    else
     # google
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.delete_snapshot(snapshot_id, zone_name)
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

  # Insert a google snapshot
  def  insert_snapshot(disk_name, zone_name, project=nil, opts={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.insert_snapshot(disk_name, zone_name, project, opts)
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