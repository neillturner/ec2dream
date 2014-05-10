require 'rubygems'
require 'net/http'
require 'resolv'
require 'fog'
require 'common/EC2_ResourceTags'


class Data_images

def initialize(owner)
     puts "data_images.initialize"
     @ec2_main = owner
     @error_message = ""
  end

  def get_images(type, platform, root, search, filter)
          puts "Data_Images.get_images(#{type}, #{platform}, #{root}, #{search}, #{filter})"
          owner = ""
          executable = ""
          arch = ""
          search = search.downcase
          if @ec2_main.settings.openstack and root == "ebs"
             root = "snapshot"
          end
          root_device=root
          image_locs = Array.new
          @tags_filter = filter
          if platform == "Small(i386)"
            arch = "i386"
          end
          if platform == "Large(x86_64)"
            arch = "x86_64"
          end
          case type
             when "Owned By Me"
                owner = "self"
             when "Amazon Images"
                owner = "amazon"
             when "Public Images"
                executable = "all"
              when "Private Images"
                executable = "self"
             else
                search = type.downcase
     	        type = "Public Images"
                executable = "all"
          end
          if @tags_filter[:image] != nil and !@tags_filter[:image].empty?
             i=0
             begin
              #ec2.describe_images(:filters => @tags_filter[:image]).each do |r|
              @ec2_main.environment.images.all(@tags_filter[:image]).each do |r|
                if search != nil and search != ""
                   loc = r['imageLocation'].downcase
                   if loc.index(search) != nil
                      if arch == nil or  arch == "" or arch == r['architecture']
                         if root_device == nil or  root_device == "" or root_device == r['rootDeviceType']
                            image_locs[i] = r
                            i = i+1
                         end
                      end
                   end
                else
                   if arch == nil or  arch == "" or arch == r['architecture']
                      if root_device == nil or  root_device == "" or root_device == r['rootDeviceType']
                         image_locs[i] = r
                         i = i+1
                      end
                   end
                end
             end
            rescue
	      @error_message = "Image Listing Error #{$!.to_s}"
              image_locs = Array.new
            end
          else
           if owner != "" and !@ec2_main.settings.openstack_hp
             i=0
             #ec2.describe_images_by_owner(owner).each do |r|
             @ec2_main.environment.images.find_by_owner(owner).each do |r|
                if search != nil and search != ""
                   loc = r['imageLocation'].downcase
                   if loc.index(search) != nil
                      if arch == nil or  arch == "" or arch == r['architecture']
                         if root_device == nil or  root_device == "" or root_device == r['rootDeviceType']
                            image_locs[i] = r
                            i = i+1
                         end
                      end
                   end
                else
                   if arch == nil or  arch == "" or arch == r['architecture']
                      if root_device == nil or  root_device == "" or root_device == "all" or root_device == r['rootDeviceType']
                         image_locs[i] = r
                         i = i+1
                      end
                   end
                end
             end
          else
           if executable == "all" or @ec2_main.settings.openstack and !@ec2_main.settings.google
              status = @ec2_main.imageCache.status
              if status == "loading"
                 error_message("Public Images","Public Images currently are loading")
                 image_locs = Array.new
                 return image_locs
              end
              if status == "empty"
                 @ec2_main.imageCache.load
              end
              image_list = @ec2_main.imageCache.get(search,arch,root_device,owner)
              if image_list != nil
                 i = 0
  	       image_list.each do |e|
  	          r = {}
  	          sa = e.split("(")
                    if sa.size>1
                       j = 0
                       r['imageLocation'] = ""
                       while j < sa.size-1
                          r['imageLocation'] = r['imageLocation'] + sa[j]
                          j = j+1
                       end
                       l = sa[sa.size-1]
                       r['imageId'] = l[0,l.length-1]
                       r['rootDeviceType'] = root_device
                       if owner == "self"
                          #r[:aws_is_public]="Private"
                          if @ec2_main.settings.openstack_hp
                             r['rootDeviceType'] = "snapshot"
                          end
                       #else
                       #   r[:aws_is_public]="Public"
                       end
                       image_locs[i] = r
                       i = i+1
                    end
                 end
              end
             else
                i=0
                #ec2.describe_images_by_executable_by(executable).each do |r|
                @ec2_main.environment.images.find_by_executable(executable).each do |r|
				 if @ec2_main.settings.google
				   image_locs[i] = r
                   i = i+1
				 else
                  if r[:aws_is_public]
                   if search != nil and search != ""
                      loc = r['imageLocation'].downcase
                      if loc.index(search) != nil
                         if arch == nil or  arch == "" or arch == r['architecture']
                            if root_device == nil or  root_device == "" or root_device == r['rootDeviceType']
                               image_locs[i] = r
                               i = i+1
                            end
                         end
                      end
                   else
                       if arch == nil or  arch == "" or arch == r['architecture']
                         if root_device == nil or  root_device == "" or root_device == r['rootDeviceType'] or r['rootDeviceType'] == nil or r['rootDeviceType'] == ""
                            image_locs[i] = r
                            i = i+1
                         end
                      end
                   end
                  end
				 end
                end
              end
             end
          end
          return image_locs
  end

  def error_message
       @error_message
  end

  # Retrieve a list of images.
  #
  # Accepts a set of filters as the last parameter.
  #
  # Filters: architecture, block-device-mapping.delete-on-termination block-device-mapping.device-name,
  # block-device-mapping.snapshot-id, block-device-mapping.volume-size, description, image-id, image-type,
  # is-public, kernel-id, manifest-location, name, owner-alias, owner-id, platform, product-code,
  # ramdisk-id, root-device-name, root-device-type, state, state-reason-code, state-reason-message,
  # tag-key, tag-value, tag:key, virtualization-type
  #
  #  ec2.describe_images #=>
  #    [{:description=>"EBS backed Fedora core 8 i386",
  #      'architecture'=>"i386",
  #      'imageId'=>"ami-c2a3f5d4",
  #      :aws_image_type=>"machine",
  #      :root_device_name=>"/dev/sda1",
  #      :image_class=>"elastic",
  #      :aws_owner=>"937766719418",
  #      'imageLocation'=>"937766719418/EBS backed FC8 i386",
  #      :aws_state=>"available",
  #      :block_device_mappings=>
  #       [{:ebs_snapshot_id=>"snap-829a20eb",
  #         :ebs_delete_on_termination=>true,
  #         :device_name=>"/dev/sda1"}],
  #      :name=>"EBS backed FC8 i386",
  #      :aws_is_public=>true}, ... ]
  #
  #  ec2.describe_images(:filters => { 'image-type' => 'kernel', 'state' => 'available', 'tag:MyTag' => 'MyValue'})
  #
  def all(filter=nil)
    data = []
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          if @ec2_main.settings.openstack
             x = conn.images.all
             x.each do |y|
                data = hash_ops_image(y)
             end
		  elsif @ec2_main.settings.google
              data = google_self()
           elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
             x = conn.images.all(filters)
             x.each do |y|
	        data.push(hash_ops_image_aws(y))
             end
          else
             data = conn.describe_images(:filters => filter)
          end
       rescue
          puts "ERROR: getting all images #{$!}"
       end
    end
    return data
  end

  # Retrieve a list of images by image owner.
  #
  # Accepts an owner.
  #
  #   ec2.describe_images_by_owner('522821470517')
  #
  def find_by_owner(owner)
    puts "find_by_owner(#{owner})"
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          if @ec2_main.settings.openstack_rackspace
            if conn != nil
              response = conn.list_images_detail({:type => 'SNAPSHOT'})
              if response.status == 200 or data.status == 203
	      	 x = response.body['images']
	      	 x.each do |r|
	      	    data.push(hash_ops_image_rackspace(r,'snapshot'))
	      	 end
              end
            end
          elsif @ec2_main.settings.openstack
            if conn != nil
              x = conn.images.all
              x.each do |y|
                data.push(hash_ops_image(y))
              end
            end
          elsif @ec2_main.settings.google
		     if owner == "self"
               data = google_self(conn)
			else
               data = google_all(conn)
            end
          elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
             x = conn.describe_images('Owner' => owner)
 	     data = x.body['imagesSet']
          else
             data = conn.describe_images_by_owner(owner)
          end
       rescue
          puts "ERROR: getting images by executable #{$!}"
       end
    end
    return data
  end

  # Retrieve a list of images by image executable by.
  #
  # Accepts executable_by
  #
  #   ec2.describe_images_by_executable_by('522821470517')
  #   ec2.describe_images_by_executable_by('self')
  #   ec2.describe_images_by_executable_by('all', :filters => { 'architecture' => 'i386' })
  def find_by_executable(executable)
    puts "find_by_executable(#{executable})"
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          if @ec2_main.settings.openstack_rackspace
            if conn != nil and executable == "all"
              response = conn.list_images_detail({:type => 'BASE'})
              if response.status == 200 or data.status == 203
	      	     x = response.body['images']
	      	     x.each do |r|
	      	        data.push(hash_ops_image_rackspace(r,'base'))
	      	     end
              end
            end
          elsif  @ec2_main.settings.openstack
            #image_conn = @ec2_main.environment.image_connection
            if conn != nil
             if executable == "all"
              x = conn.images.all
              x.each do |y|
                data.push(hash_ops_image(y))
              end
             end
            end
		  elsif @ec2_main.settings.google
		     if conn != nil
          		if executable == "all"
                  data = google_all(conn)
				else
                  data = google_self(conn)
                end
             end
          elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
             x = conn.describe_images('ExecutableBy' => executable)
	         x = x.body['imagesSet']
             x.each do |y|
	            data.push(hash_ops_image_aws(y))
             end
          else
             data = conn.describe_images_by_executable_by(executable)
          end
       rescue
          data = []
          puts "ERROR: getting images by executable #{$!}"
       end
    end
    return data
  end

  def details
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          data = conn.images.details
       rescue
          puts "ERROR: getting images details #{$!}"
       end
    end
    return data
  end

  def find_by_id(id)
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          data = conn.images.find_by_id(id)
       rescue
          puts "ERROR: finding images by id #{id} #{$!}"
       end
    end
    return data
  end

  def public
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          data = conn.images.public
       rescue
          puts "ERROR: getting images public #{$!}"
       end
    end
    return data
  end

  def private
    data = Array.new
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          data = conn.images.private
       rescue
          puts "ERROR: getting images private #{$!}"
       end
    end
    return data
  end

  def destroy(id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.destroy(id)
     else
        raise "Connection Error"
     end
     return data
  end


  def get(image_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
          if  @ec2_main.settings.openstack
                y = conn.images.get(image_id)
                data = hash_ops_image(y)
          elsif @ec2_main.settings.google
		     # this needs testing
             data = conn.get_image(image_id)
           elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
             x = conn.describe_images({'ImageId' => image_id})
	     x = x.body['imagesSet']
             x.each do |y|
                data = hash_ops_image_aws(y)
             end
          else
             a = conn.describe_images([image_id])
             data = a[0]
          end
     else
        raise "Connection Error"
     end
     return data
  end

  def get_attribute(image_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
          if  @ec2_main.settings.openstack
          # openstack
		  elsif @ec2_main.settings.google
		  # google
          elsif conn.instance_of?(Fog::Compute)
          # no method is fog aws for this?
          else
             data = conn.describe_image_attribute(image_id)
          end
     else
        raise "Connection Error"
     end
     return data
  end

  def create_image(instance_id, options)
     data = ""
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           if  @ec2_main.settings.openstack_hp
              response = conn.create_image(instance_id.to_i,options[:name],options)
           else
              response = conn.create_image(instance_id,options[:name],options)
           end
           puts response
           if response.status == 202
	      #data = response.body['image']['id']
	      data  = options[:name]
	   else
	      raise "Error #{response.status} #{response.body['Message']}"
	   end
	     elsif @ec2_main.settings.google
		     # this needs testing
             data = conn.insert_image(options[:name], options)
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           response = conn.create_image(instance_id, options[:name], options[:description], options[:no_reboot])
           if response.status = 200
	      data = response.body['imageId']
	   else
	      raise "Error #{response.status} #{response.body['Message']}"
	   end
        else
           data = conn.create_image(instance_id, options)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # delete google and other images
  def  delete_image(image_id)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.delete_image(image_id)
        if data.status == 200
	   data = true
	else
	   data = false
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Insert a google image
  def  insert_image(image_name, options={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.insert_image(image_name, options)
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

 # Register new image at Amazon.
 # Options: :image_location, :name, :description, :architecture, :kernel_id, :ramdisk_id,
 #          :root_device_name, :block_device_mappings, :virtualizationt_type(hvm|paravirtual)
 #
 # Returns new image id.
 #
 #  # Register S3 image
 #  ec2.register_image('bucket_for_k_dzreyev/image_bundles/kd__CentOS_1_10_2009_10_21_13_30_43_MSD/image.manifest.xml') #=> 'ami-e444444d'
 #
 #  # or
 #  image_reg_params = {  :image_location => 'bucket_for_k_dzreyev/image_bundles/kd__CentOS_1_10_2009_10_21_13_30_43_MSD/image.manifest.xml',
 #                        :name => 'my-test-one-1',
 #                        :description => 'My first test image' }
 #  ec2.register_image(image_reg_params) #=> "ami-bca1f7aa"
 #
 #  # Register EBS image
 #  image_reg_params = { :name        => 'my-test-image',
 #                       :description => 'My first test image',
 #                       :root_device_name => "/dev/sda1",
 #                       :block_device_mappings => [ { :ebs_snapshot_id=>"snap-7360871a",
 #                                                     :ebs_delete_on_termination=>true,
 #                                                     :device_name=>"/dev/sda1"} ] }
 #  ec2.register_image(image_reg_params) #=> "ami-b2a1f7a4"
 #
 def register_image(options)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
          # openstack
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           bm = options[:block_device_mappings]
           bm_fog = {}
           bm_fog['SnapshotId'] = bm[:ebs_snapshot_id]
           bm_fog['DeviceName'] = bm[:device_name]
           bm_fog['DeleteOnTermation'] = bm[:ebs_delete_on_termination]
           opts_fog = {}
           opts_fog['KernelId'] = options[:kernel_id]
           opts_fog['RamdiskId'] = options[:ramdisk_id]
           opts_fog['Architecture'] = options[:architecture]
           response = conn.register_image(options[:name],  options[:description], options[:root_device_name], [bm_fog], opts_fog)
           if response.status = 200
	      data = response.body['imageId']
	   else
	      raise "Error #{response.status} #{response.body['Message']}"
	   end
        else
           data = conn.register_image(options)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Deregister image at Amazon. Returns +true+ or an exception.
  #
  #  ec2.deregister_image('ami-e444444d') #=> true
  #
  def deregister_image(image_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
          # openstack
         else
           data = conn.deregister_image(image_id)
          end
     else
        raise "Connection Error"
     end
     return data
  end


  def hash_ops_image_aws(r)
                 # r['imageId'] = r['imageId']
                 # r['imageLocation']  = r['imageLocation']
                 # r[:aws_state] = r['imageState']
                 # if r['isPublic'] == 'true'
                 #    r[:aws_is_public]  = "true"
                 # else
                 #    r[:aws_is_public]  = "false"
                #  end
                 # r['architecture'] = r['architecture']
                 #  r[:aws_owner] = r['imageOwnerId']
                 #  r['rootDeviceType'] = r['rootDeviceType']
                 # r[:root_device_name] = r['rootDeviceName']
                return r
  end

  def hash_gce_image(r,type="")
      r['imageId'] = r['id']
	  r['architecture'] = type
	  r['rootDeviceType'] =  r['sourceType']
	  r['imageLocation'] =  r['name']
      return r
  end

   def google_all(conn)
    puts "google_all"
                data = []
                response = conn.list_images('centos-cloud')
			    x = response.body['items']
			    if response.status == 200
	      	       x.each do |r|
	      	          data.push(hash_gce_image(r,'centos-cloud'))
	      	       end
			    end
                response = conn.list_images('debian-cloud')
			    x = response.body['items']
			    if response.status == 200
	      	       x.each do |r|
	      	          data.push(hash_gce_image(r,'debian-cloud'))
	      	       end
			    end
             return data
   end

    def google_self(conn)
	puts "google_self"
	            data = []
                response = conn.list_images
			    x = response.body['items']
			    if response.status == 200
	      	       x.each do |r|
	      	          data.push(hash_gce_image(r,'private'))
	      	       end
			    end
 			  return data
   end

  def hash_ops_image_rackspace(r,type)
      m = r[:metadata]
      if m != nil
         m.each do |k,v|
            r[k]=v
         end
      end
      r['imageId'] = r["id"]
      r[:created_at] = r["created"]
      r[:updated_at] = r["updated"]
      r[:min_disk] = r[":minDisk"]
      r[:min_ram] = r["minRam"]
      r['architecture'] = r["arch"]
      r[:user_id] = r["user_id"]   #  is this the metadata r["owner_id"] of hp???
      r[:tenant_id] = r["tenant_id"]
      l = r['links']
      l.each do |v|
         if v["rel"] == "self"
            r["href"] = v["href"]
         end
      end
      if r[:created_at] != nil and r[:created_at] != ""
         r[:description] = "Created #{r[:created_at]} Updated #{r[:updated_at]}"
      end
      r[:location]  = r["href"]
      r['imageLocation']  = r["name"]
      r[:aws_owner] = r["owner_id"]
      # figure out value to test
      if type == 'base'
         r[:aws_is_public]  = true
      else
         r[:aws_is_public]  = false
      end
      r[:aws_state] = r["image_state"]
      r[:aws_kernel_id] = r["kernel_id"]
      r[:aws_image_type] = type
      if r['imageversion'] != nil and r['imageversion'] != ""
         r[:state_reason_message] = "Image Version #{r['imageversion']}"
      end
      r[:aws_ramdisk_id] = r["ramdisk_id"]
      r['rootDeviceType'] = type
      r[:name] = r["name"]
      r[:ami_name] = r["name"]
      return r
  end

  def hash_ops_image(y)
                r = {}
                if @ec2_main.settings.openstack_hp
                   y.metadata.all.each do |m|
                     r[m.key]=m.value
                   end
                elsif @ec2_main.settings.openstack_rackspace
                   m = y.metadata
                   if m != nil
		      m.each do |k,v|
		        r[k]=v
                      end
                   end
                end
  	        r[:id] = y.id
  	        r['imageId'] = y.id.to_s
                  #r['imageLocation']  = y.imageLocation
                  #r[:aws_state] = y.status
                  #r[:name] = y.name
                  if @ec2_main.settings.openstack_rackspace
                     r[:created_at] = y.created
                     r[:updated_at] = y.updated
                  else
                     r[:created_at] = y.created_at
                     r[:updated_at] = y.updated_at
                     r[:server] = y.server
                  end
                  r[:progress] = y.progress
                  if @ec2_main.settings.openstack_hp
                     r[:min_disk] = y.min_disk
                     r[:min_ram] = y.min_ram
                     r['architecture'] = r["architecture"]
                  elsif @ec2_main.settings.openstack_rackspace
                      r[:min_disk] = y.minDisk
                      r[:min_ram] = y.minRam
                      r['architecture'] = r["arch"]
                      r[:user_id] = y.user_id   #  is this the metadata r["owner_id"] of hp???
                      r[:tenant_id] = y.tenant_id
                 else
		     r[:min_disk] = y.minDisk
                     r[:min_ram] = y.minRam
                  end
                  r[:metadata] = y.metadata
                  r[:links] = y.links
                  l = y.links
                  l.each do |v|
                    if v["rel"] == "self"
                       r["href"] = v["href"]
                    end
                  end
                   if r[:created_at] != nil and r[:created_at] != ""
                      r[:description] = "Created #{r[:created_at]} Updated #{r[:updated_at]}"
                   end
                  r[:location]  = r["href"]
                  r['imageLocation']  = y.name
                  r[:aws_owner] = r["owner_id"]
                  if @ec2_main.settings.get('AMAZON_ACCOUNT_ID') ==  r["owner_id"]
                     r[:aws_is_public]  = false
                     r["image_type"] = "snapshot"
                  else
                     r[:aws_is_public]  = true
                  end
                  r[:aws_state] = r["image_state"]
                  r[:aws_kernel_id] = r["kernel_id"]
                  r[:aws_image_type] = r["image_type"]
                  if r['imageversion'] != nil and r['imageversion'] != ""
                     r[:state_reason_message] = "Image Version #{r['imageversion']}"
                  end
                   r[:aws_ramdisk_id] = r["ramdisk_id"]
                  r['rootDeviceType'] = r["image_type"]
                  r[:name] = y.name
                  r[:ami_name] = r[:name]
      return r
  end

  # search options
  def viewing
     data = Array.new
     if  @ec2_main.settings.openstack or @ec2_main.settings.google
        data.push("Owned By Me")
        data.push("Public Images")
     else
        data.push("Owned By Me")
        data.push("Amazon Images")
        data.push("Public Images")
        data.push("Private Images")
        data.push("alestic")
        data.push("bitnami")
        data.push("Canonical")
        data.push("Elastic-Server")
        data.push("JumpBox")
        data.push("RBuilder")
        data.push("rightscale")
        data.push("windows")
     end
     return data
  end

   def platform
    data = Array.new
    if  @ec2_main.settings.openstack
         data.push("All Architectures")
	elsif @ec2_main.settings.google
       data.push("All Architectures")
     else
       data.push("All Architectures")
       data.push("Small(i386)")
       data.push("Large(x86_64)")
    end
    return data
  end

  def device
     data = Array.new
     if  @ec2_main.settings.openstack  or @ec2_main.settings.google
         data.push("all")
     else
        data.push("ebs")
        data.push("instance-store")
     end
     return data
  end

  def search_root
   data = "ebs"
   data = "all" if @ec2_main.settings.openstack or @ec2_main.settings.google
  end

end