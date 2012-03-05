class EC2_List

  def load_ebs(sort_col,reload)
      ec2 = @ec2_main.environment.connection
      tzone = @ec2_main.settings.get_system('TIMEZONE')
      if ec2 != nil
         @create_button.tipText = "Create EBS Volume"
         @delete_button.tipText = "Delete EBS Volume"
         @link_button.tipText = "Attach EBS Volume"
         @link_break_button.tipText = "Detach EBS Volume"
         if reload == true
            @data = Array.new
            i = 0
            begin
             ec2.describe_volumes([],{:filters => @tags_filter[:volume]}).each do |r|
                t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil)
                n = t.nickname
                if n != "" and n != nil
                   r[:aws_id] = n +"/"+ r[:aws_id]
                end
                if r[:aws_attachment_status] != nil
                  gp =  @ec2_main.server.instance_group(r[:aws_instance_id])
                  r[:aws_instance_id] = gp+"/"+r[:aws_instance_id]
                end 
                r[:tags] = t
                @data[i] = r
                i = i+1
            end
           rescue
             error_message("EBS Listing Error",$!.to_s)
             @data = Array.new
           end
         end
         text = ""
         lists = create_lists(9)
         i = 0
         case sort_col  
  	    when  0 
               @data = @data.sort_by {|r| r[:aws_id].downcase}
            when 2 
               @data = @data.sort_by {|r| r[:aws_instance_id] || ""}
            when 3 
               @data = @data.sort_by {|r| r[:aws_created_at]}
            when 4 
               @data = @data.sort_by {|r| r[:zone]}
            when 5 
               @data = @data.sort_by {|r| r[:aws_status]}
            when 6 
               @data = @data.sort_by {|r| r[:aws_size]}
            when 7 
               @data = @data.sort_by {|r| r[:aws_device] || ""}
            when 8 
               @data = @data.sort_by {|r| r[:snapshot_id] || ""}
         end
         @data.each do |r|
            sz = r[:aws_size]
            s = sz.to_s
            s = s.rjust(7)
            lists[0][i] = r[:aws_id]
            lists[1][i] = r[:tags].show 
            lists[3][i] = convert_time(r[:aws_created_at]) 
            lists[4][i] = r[:zone]
            lists[6][i] = s+"GB"                  
            if r[:aws_attachment_status] != nil
               lists[2][i] = r[:aws_instance_id]                     
               lists[5][i] = r[:aws_status]+" "+r[:aws_attachment_status]
               lists[7][i] = r[:aws_device]
            else 
               lists[2][i] = " "                 
               lists[5][i] = r[:aws_status]
               lists[7][i] = " "
            end  
            if r[:snapshot_id] != nil
               lists[8][i] = r[:snapshot_id]
            else
               lists[8][i] = " "
            end
            i = i+1
         end
         i = lists[0].length
         @table.setTableSize(i, 9)
  	 set_table_titles(@type)
  	 set_table_data(lists,9)
         while i>0
            i = i-1
    	    @table.setItemJustify(i, 3, FXTableItem::RIGHT)
    	    @table.setItemJustify(i, 6, FXTableItem::RIGHT)
         end     
         @loaded = true
      end
  end
  
  def load_ebs_snapshot(sort_col,reload)
       ec2 = @ec2_main.environment.connection
       tzone = @ec2_main.settings.get_system('TIMEZONE')
       if ec2 != nil
                @create_button.tipText = "  Select EBS Snapshots  "
     	        @delete_button.tipText = "  Delete EBS Snapshot  "
     	        @link_button.tipText = ""
     	        @link_break_button.tipText = ""
      	        if reload == true
                     i = 0
                     @ebs_vols = {}
                     ec2.describe_volumes.each do |r|
                        @ebs_vols[r[:aws_id]] = r
                        i = i+1
                     end
                     @data = Array.new
                     i = 0
                     begin 
                        ec2.describe_snapshots({:owner => @snap_owner, :filters => @tags_filter[:snapshot]}).each do |r|
                          #if r[:aws_owner_alias]==@snap_owner
                           t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil)
                           n = t.nickname
                           if n != "" and n != nil
                              r[:aws_id] = n+"/"+ r[:aws_id]
                           end
                           r[:tags] = t
                           @data[i] = r
                           i = i+1
                         #end  
                        end
                    rescue 
                        error_message("Snapshots Listing Error",$!.to_s)
                        @data = Array.new
                    end 
                  end
                  text = ""
                  lists = create_lists(10)
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:aws_id].downcase}
                   when 2 
                     @data = @data.sort_by {|r| r[:aws_description]}  
                   when 3 
                     @data = @data.sort_by {|r| r[:aws_started_at]}
                   when 4 
                     @data = @data.sort_by {|r| r[:aws_volume_id].downcase}
                   when 5 
                     @data = @data.sort_by {|r| r[:aws_status]}
                   when 6 
                     @data = @data.sort_by {|r| r[:aws_progress] || ""}
                   when 7 
                     @data = @data.sort_by {|r| r[:aws_volume_size]}
                   when 8 
                     @data = @data.sort_by {|r| r[:aws_owner].to_i }
                   when 9 
                     @data = @data.sort_by {|r| r[:aws_owner_alias] || ""}                     
                  end                
                  @data.each do |r|               
                     rv = @ebs_vols[r[:aws_volume_id]]
                     lists[0][i] = r[:aws_id]
                     lists[1][i] = r[:tags].show 
                     lists[2][i] = r[:aws_description]
                     lists[3][i] = convert_time(r[:aws_started_at])
                     lists[4][i] = r[:aws_volume_id]
                     lists[5][i] = r[:aws_status]
                     if r[:aws_progress] != nil
                        lists[6][i] = r[:aws_progress]
                     else
                        lists[6][i] = " "
                     end
                     if r[:aws_volume_size] != nil
                        lists[7][i] = r[:aws_volume_size].to_s
                     else
                        lists[7][i] = " "
                     end
                     if r[:aws_owner] != nil
                        lists[8][i] = r[:aws_owner]
                     else
                        lists[8][i] = " "
                     end
                     if r[:aws_owner_alias] != nil
                        lists[9][i] = r[:aws_owner_alias]
                     else
                        lists[9][i] = " "
                     end                     
                     i = i+1
                  end
                  i = lists[0].length
                  @table.clearItems
                  @table.setTableSize(i, 10)
          	  set_table_titles(@type)
          	  set_table_data(lists,10)
                  #while i>0
                  #   i = i-1
  		  #   @table.setItemJustify(i, 1, FXTableItem::RIGHT)
                  #end     
                @loaded = true
       end         
  end 
  
  def load_elastic_ips(sort_col,reload)
         ec2 = @ec2_main.environment.connection
         tzone = @ec2_main.settings.get_system('TIMEZONE')
         if ec2 != nil
                @create_button.tipText = "Allocate Elastic IP"
     	        @delete_button.tipText = "Release Elastic IP"
     	        @link_button.tipText = "Associate Elastic IP"
     	        @link_break_button.tipText = "Disassociate Elastic IP"
                  i = 0
                  eip_array = Array.new
                  ec2.describe_addresses.each do |r|
                     if r[:instance_id] != nil
                        gp =  @ec2_main.server.instance_group(r[:instance_id])
                        r[:instance_id] = gp+"/"+r[:instance_id]
                     end  
  		     eip_array[i] = r
                     i = i+1                
                  end
                  lists = create_lists(2)
                  if sort_col == 0 
  		   eip_array = eip_array.sort_by {|r| r[:public_ip]}
                  end
                  if sort_col == 1 
  		   eip_array = eip_array.sort_by {|r| r[:instance_id].downcase}
                  end                  
                  i = 0
                  eip_array.each do |r|
                     lists[0][i] = r[:public_ip]
                     if r[:instance_id] != nil
                        lists[1][i] = r[:instance_id]                     
                     else
                        lists[1][i] = ""                 
                     end
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 2)
                  set_table_titles(@type)
                  set_table_data(lists,2)
                 @loaded = true
         end       
  end              
  
  def load_keypairs(sort_col,reload)
         ec2 = @ec2_main.environment.connection
         tzone = @ec2_main.settings.get_system('TIMEZONE')
         if ec2 != nil
                 @create_button.tipText = "Create Key Pair"
     	        @delete_button.tipText = "Create Key Pair"
     	        @link_button.tipText = ""
     	        @link_break_button.tipText = ""
                  i = 0
                  kp_array = Array.new
                  ec2.describe_key_pairs.each do |r|
  		   kp_array[i] = r
                     i = i+1                
                  end
                  case sort_col  
  		   when 0 
  		     kp_array = kp_array.sort_by {|r| r[:aws_key_name]}
                   when 1 
  		     kp_array = kp_array.sort_by {|r| r[:aws_fingerprint]}
                  end                
                  lists = create_lists(2)
                  i = 0
                  kp_array.each do |r|
                     lists[0][i] = r[:aws_key_name]
                     lists[1][i] = r[:aws_fingerprint]
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 2)
                  set_table_titles(@type)
                  set_table_data(lists,2)
                 @loaded = true
           end     
  end              
  
  def load_images(sort_col,reload)
       ec2 = @ec2_main.environment.connection
       tzone = @ec2_main.settings.get_system('TIMEZONE')
       if ec2 != nil
                @create_button.tipText = ""
     	        @delete_button.tipText = ""
     	        @link_button.tipText = "Register Image"
     	        @link_break_button.tipText = "De-Register Image"
     	        if reload == true
     	           puts "Reloading images...."
     	           image_get = EC2_Images_get.new(@ec2_main)
  		   @image_locs = image_get.get_images(@image_type, @image_platform, @image_root, @image_search, @tags_filter)
  		   if @image_locs.empty?
  		      image_error_message = image_get.error_message
  		      if image_error_message != nil and image_error_message != ""
  		         error_message("Error",image_error_message)    
  		      end
  		   end   
  		end
  		if @tags_filter[:image] == nil or  @tags_filter[:image].empty?
  		   if @image_type == "Public Images"  
                      @title.text = "Images (Cached)"
                   else    
                     if @image_type != "Private Images"
                        @title.text = "Images (Cached)"
                     end   
                  end  
                end 		
               	case sort_col  
     		  when 0 
     		   @image_locs = @image_locs.sort_by {|r| r[:aws_id]}
     		  when 1 
     		   @image_locs = @image_locs.sort_by {|r| r[:aws_location].downcase}  		   
     		  when 3 
     		   @image_locs = @image_locs.sort_by {|r| r[:aws_is_public]}
     		  when 4 
     		   @image_locs = @image_locs.sort_by {|r| r[:root_device_type]}   		   
     		end
     		if @image_locs.length > 0
                   @table.setTableSize(@image_locs.length, 6)
     		   set_table_titles(@type)
             	   if @curr_order == "" or @curr_order == "down" or sort_col >3
             	      i = 0
                        while i<@image_locs.length
                           @table.setItemText(i, 0,@image_locs[i][:aws_id])
			   @table.setItemJustify(i, 0, FXTableItem::LEFT)	
			   @table.setItemText(i, 1,@image_locs[i][:aws_location])	 
                           @table.setItemJustify(i, 1, FXTableItem::LEFT)
			   if @image_locs[i][:tags] != nil
			      #puts "image tags #{@image_locs[i][:tags]}"
			      #x = 
			      #puts "#{x}"
			      @table.setItemText(i, 2,@image_locs[i][:tags].show)
		           else
			      @table.setItemText(i, 2, "")
			   end
			   @table.setItemJustify(i, 2, FXTableItem::LEFT)
                           @table.setItemText(i, 3,@image_locs[i][:aws_is_public])
                           @table.setItemJustify(i, 3, FXTableItem::LEFT)
                           @table.setItemText(i, 4,@image_locs[i][:root_device_type])
                           @table.setItemJustify(i, 4, FXTableItem::LEFT)
                           profile = @image_locs[i][:aws_id]
                           fn = @ec2_main.settings.get_system('ENV_PATH')+"/image/"+profile+".properties"
                           if File.exists?(fn)
                            properties = {}
      			 File.open(fn, 'r') do |properties_file|
               	            properties_file.read.each_line do |line|
               	               line.strip!
               	               if (line[0] != ?# and line[0] != ?=)
               	                  m = line.index('=')
               	                  if (m)
               	                     properties[line[0..m - 1].strip] = line[m + 1..-1].strip
               	                  else
               	                     properties[line] = ''
               	                  end
               	               end
               	            end
               	         end
               	      	 @table.setItemText(i, 5, properties['Security_Group']) 
                          end
                          @table.setItemJustify(i, 5, FXTableItem::LEFT)
                          i = i+1                   
                       end
                    else
             	        i = @image_locs.length
             	        j = 0
                        while i>0
                           i = i-1
                           @table.setItemText(i, 0,@image_locs[j][:aws_id])
                           @table.setItemJustify(i, 0, FXTableItem::LEFT)
                           @table.setItemText(i, 1,@image_locs[j][:aws_location])
                           @table.setItemJustify(i, 1, FXTableItem::LEFT)
			   if @image_locs[i][:tags] != nil
			      @table.setItemText(i, 2,@image_locs[i][:tags].show)
		           else
			      @table.setItemText(i, 2, "")
			   end
			   @table.setItemJustify(i, 2, FXTableItem::LEFT)
                           @table.setItemText(i, 3,@image_locs[j][:aws_is_public])
                           @table.setItemJustify(i, 3, FXTableItem::LEFT)
                           @table.setItemText(i, 4,@image_locs[j][:root_device_type])
                           @table.setItemJustify(i, 4, FXTableItem::LEFT)                       
                           profile = @image_locs[j][:aws_id]
                           fn = @ec2_main.settings.get_system('ENV_PATH')+"/image/"+profile+".properties"
                           if File.exists?(fn)
                             properties = {}
      			     File.open(fn, 'r') do |properties_file|
               	              properties_file.read.each_line do |line|
               	               line.strip!
               	               if (line[0] != ?# and line[0] != ?=)
               	                  m = line.index('=')
               	                  if (m)
               	                     properties[line[0..m - 1].strip] = line[m + 1..-1].strip
               	                  else
               	                     properties[line] = ''
               	                  end
               	               end
               	            end
               	         end
               	      	 @table.setItemText(i, 5, properties['Security_Group']) 
                          end
                          @table.setItemJustify(i, 5, FXTableItem::LEFT)
                          j = j+1
                       end               
                    end
                    @loaded = true
           else
               @table.setTableSize(1, 6)
               set_table_titles(@type)
               @table.setItemText(0, 0,"** Not Found **")
               @table.setItemJustify(0, 0, FXTableItem::LEFT)
               @loaded = true
           end 
      end              
   end 

   
            
   
   def load_spot_requests(sort_col,reload)
       ec2 = @ec2_main.environment.connection
       if ec2 != nil 
                  if reload == true
                     @data = Array.new
                     i = 0
                     ec2.describe_spot_instance_requests([],:filters => @tags_filter[:spot_instances_request]).each do |r|
               		t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil)
                	n = t.nickname
                	if n != "" and n != nil
                   	   r[:spot_instance_request_id] = n +"/"+ r[:spot_instance_request_id]
                	end
                	r[:tags] = t
                        @data[i] = r
                        i = i+1
                     end
                  end   
                  text = ""
                  lists = create_lists(15)                
                  i = 0
  		case sort_col  
  		  when 0 
                     @data = @data.sort_by {|r| r[:spot_instance_request_id]}
                  when 2 
                     @data = @data.sort_by {|r| r[:spot_price] || ""}
                  when 3 
                     @data = @data.sort_by {|r| r[:image_id]}
                  when 4 
                     @data = @data.sort_by {|r| r[:instance_id]}
                  when 5 
                     @data = @data.sort_by {|r| r[:instance_type]}
                  when 6 
                     @data = @data.sort_by {|r| r[:state]}
                  when 7 
                     @data = @data.sort_by {|r| r[:request_type] || ""}
                  when 8 
                     @data = @data.sort_by {|r| r[:valid_from] || ""}
                  when 9 
                     @data = @data.sort_by {|r| r[:valid_until] || ""}
                  when 10 
                     @data = @data.sort_by {|r| r[:launch_group] || ""}
                  when 11 
                     @data = @data.sort_by {|r| r[:availability_zone] || ""}
                  when 12 
                     @data = @data.sort_by {|r| r[:availability_zone_group] || ""}
                  when 13 
                     @data = @data.sort_by {|r| r[:key_name] || ""}
                  when 14 
                     @data = @data.sort_by {|r| r[:groups] || ""}
                  end                    
                  @data.each do |r|
    	 	    gp = r[:groups]
    	 	    gp_list = ""
    	 	    fgp = ""
    	 	    gp.each do |g|
    	 	       if gp_list.length>0
    	 	          gp_list = gp_list+","+g[:group_name]
    	 	       else
    	 	          gp_list = g[:group_name]
    	 	          fgp = g[:group_name]
    	 	       end 
    	 	    end                  
                   lists[0][i] = r[:spot_instance_request_id]
                   lists[1][i] = r[:tags].show 
       	 	   lists[2][i] = r[:spot_price].to_s
      	 	   lists[3][i] = r[:image_id]
      	 	   if r[:instance_id] != nil and r[:instance_id] != ""
       	 	      lists[4][i] = fgp+"/"+r[:instance_id]
       	 	   else
       	 	      lists[4][i] = fgp
       	 	   end
      	 	   lists[5][i] = r[:instance_type]
      	 	   lists[6][i] = r[:state]
      	 	   lists[7][i] = r[:request_type]
      	 	   lists[8][i] = r[:valid_from]
      	 	   lists[9][i] = r[:valid_until]
     	 	   lists[10][i] = r[:launch_group]
      	 	   lists[11][i] = r[:availability_zone]
      	 	   lists[12][i] = r[:availability_zone_group]
     	 	   lists[13][i] = r[:key_name]
      	 	   lists[14][i] = gp_list
      	 	   #lists[14][i] = ""
                   i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 15)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,15)
                  while i>0
                      i = i-1
   		      @table.setItemJustify(i, 1, FXTableItem::LEFT)
                  end
                  
                @loaded = true
           end     
  end   
  
   def load_servers(sort_col,reload)
       ec2 = @ec2_main.environment.connection
       tzone = @ec2_main.settings.get_system('TIMEZONE')
       if ec2 != nil 
                  if reload == true
                     @data = Array.new
		     @tags = Array.new
                     i = 0
                     ec2.describe_instances([],@tags_filter[:instance]).each do |r|
	                t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil)
                        r[:tags] = t
                        @data[i] = r
                        fgp = r[:groups][0][:group_name]
  	    	   	r[:aws_instance_id] = fgp+"/"+r[:aws_instance_id]
                        i = i+1
                     end
                  end   
                  text = ""
                  lists = create_lists(10)                
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:aws_instance_id].downcase}
                  when 2 
                     @data = @data.sort_by {|r| r[:aws_image_id] || ""}
                  when 3 
                     @data = @data.sort_by {|r| r[:aws_launch_time]}
                  when 4 
                     @data = @data.sort_by {|r| r[:ssh_key_name].downcase}
                  when 5 
                     @data = @data.sort_by {|r| r[:dns_name]}
                  when 6 
                     @data = @data.sort_by {|r| r[:private_dns_name]}
                  when 7 
                     @data = @data.sort_by {|r| r[:aws_instance_type] || ""}
                  when 8 
                     @data = @data.sort_by {|r| r[:aws_availability_zone] || ""}
                  when 9 
                     @data = @data.sort_by {|r| r[:aws_state] || ""}
                  end                    
                  @data.each do |r|
                   lists[0][i] = r[:aws_instance_id]
       	 	   #@server['Security_Groups'].text = gp_list
		   lists[1][i] = r[:tags].show 
      	 	   lists[2][i] = r[:aws_image_id]
      	 	   lists[3][i] = convert_time(r[:aws_launch_time]) 
       	 	   lists[4][i] = r[:ssh_key_name]
      	 	   lists[5][i] = r[:dns_name]
      	 	   lists[6][i] = r[:private_dns_name]
      	 	   lists[7][i] = r[:aws_instance_type]
      	 	   lists[8][i] = r[:aws_availability_zone]
      	 	   lists[9][i] = r[:aws_state]
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 10)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,10)
                  while i>0
                      i = i-1
   		      @table.setItemJustify(i, 2, FXTableItem::RIGHT)
                  end     
                @loaded = true
           end     
  end              
  
 end