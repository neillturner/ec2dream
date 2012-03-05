class EC2_List 
  
  def load_launch_configurations(sort_col,reload)
                  @title.text = "Launch Configurations"
                  if reload == true
                     @data = Array.new
                     as = @ec2_main.environment.as_connection
                     if as != nil 
                        i = 0
                        as.describe_launch_configurations.each do |r|
                           @data[i] = r
                           i = i+1
                        end
                     end
                  end   
                  text = ""
                  lists = create_lists(7)
                  i = 0
  		  case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:launch_configuration_name]}
                  when 1 
                     @data = @data.sort_by {|r| r[:created_time]}
                  when 2 
                     @data = @data.sort_by {|r| r[:instance_type]}
                  when 3 
                     @data = @data.sort_by {|r| r[:key_name]}
                  when 4 
                     @data = @data.sort_by {|r| r[:image_id]}
                  when 5 
                     @data = @data.sort_by {|r| r[:user_data]}
                  end 
                  @data.each do |r|
                   lists[0][i] = r[:launch_configuration_name]
       	 	   lists[1][i] = convert_time(r[:created_time])
      	 	   lists[2][i] = r[:instance_type]
      	 	   lists[3][i] = r[:key_name]
      	 	   lists[4][i] = r[:image_id]
      	 	   lists[5][i] = r[:user_data]
      	 	   lists[6][i] = ''
		   r[:security_groups].each do |x|
             	      if lists[6][i] == ''
			lists[6][i] = x
             	      else
	        	lists[6][i] = lists[6][i] + "," + x
             	      end
          	   end
                   i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 7)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,7)
                  @loaded = true
  end
  
  def load_auto_scaling_groups(sort_col,reload)
                  @title.text = "Auto Scaling Groups"
                  if reload == true
                     @data = Array.new
                     as = @ec2_main.environment.as_connection
                     if as != nil 
                        i = 0
                         as.describe_auto_scaling_groups.each do |r|
                            @data[i] = r
                           i = i+1
                        end
                     end
                  end   
                  text = ""
                  lists = create_lists(10)                
                  i = 0
  		  case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:auto_scaling_group_name]}
                  when 1 
                     @data = @data.sort_by {|r| r[:launch_configuration_name]}
                  when 2 
                     @data = @data.sort_by {|r| r[:created_time]}
                  when 3 
                     @data = @data.sort_by {|r| r[:min_size]}
                  when 4 
                     @data = @data.sort_by {|r| r[:max_size]}
                  when 5 
                     @data = @data.sort_by {|r| r[:desired_capacity] || ""}
                  when 6 
                     @data = @data.sort_by {|r| r[:cooldown] || ""}
                  end                
                  @data.each do |r|
                     lists[0][i] = r[:auto_scaling_group_name]
      	 	     lists[1][i] = r[:launch_configuration_name]
       	 	     lists[2][i] = convert_time(r[:created_time])
      	 	     lists[3][i] = r[:min_size].to_s
      	 	     lists[4][i] = r[:max_size].to_s
      	 	     lists[5][i] = r[:desired_capacity].to_s
      	 	     lists[6][i] = r[:cooldown].to_s
      	 	     lists[7][i] = ''
      	 	     lists[8][i] = ''
      	 	     lists[9][i] = ''
 		     r[:instances].each do |x|
             	        if lists[7][i] == ''
			   lists[7][i] = "#{x[:instance_id]}"
             	        else
	        	   lists[7][i] = lists[7][i] +",#{x[:instance_id]}"
             	        end
          	     end      	 	   
		     r[:availability_zones].each do |x|
             	        if lists[8][i] == ''
			   lists[8][i] = x
             	        else
	        	   lists[8][i] = lists[8][i] + "," + x
             	        end
          	     end
 		     r[:load_balancer_names].each do |x|
             	        if lists[9][i] == ''
			   lists[9][i] = x
             	        else
	        	   lists[9][i] = lists[9][i] + "," + x
             	        end
          	     end         	   
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 10)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,10)
                  #while i>0
                  #   i = i-1
  		  #   @table.setItemJustify(i, 2, FXTableItem::RIGHT)
                  #end     
                  @loaded = true
  end 

  def load_scaling_activities(sort_col,reload)
                @title.text = "Scaling Activities - "+@as_group
                  if reload == true
                     @data = Array.new
                     as = @ec2_main.environment.as_connection
                     if as != nil 
                        i = 0
                        result = as.describe_scaling_activities(@as_group)
                         result.each do |r|
                           @data[i] = r
                           i = i+1
                        end
                     end
                  end   
                  text = ""
                  lists = create_lists(7)
                  i = 0
  		  case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:activity_id]}
                   when 1 
                     @data = @data.sort_by {|r| r[:start_time]}
                   when 2 
                     @data = @data.sort_by {|r| r[:end_time]}
                   when 3 
                     @data = @data.sort_by {|r| r[:progress]}
                   when 4 
                     @data = @data.sort_by {|r| r[:status_code]}
                   when 5 
                     @data = @data.sort_by {|r| r[:cause]}
                   when 6 
                     @data = @data.sort_by {|r| r[:description]}
                  end 
                  @data.each do |r|
                   lists[0][i] = r[:activity_id]
       	 	   lists[1][i] = convert_time(r[:start_time])
      	 	   lists[2][i] = convert_time(r[:end_time])
      	 	   lists[3][i] = r[:progress].to_s
      	 	   lists[4][i] = r[:status_code]
      	 	   lists[5][i] = r[:cause]
      	 	   lists[6][i] = r[:description]
                   i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 7)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,7)
                  @loaded = true
  end  

  def load_triggers(sort_col,reload)
                @title.text = "Triggers - "+@as_group
                if reload == true
                   @data = Array.new
                   as = @ec2_main.environment.as_connection
                   if as != nil 
                      i = 0
                      as.describe_triggers(@as_group).each do |r|
                        @data[i] = r
                        i = i+1
                      end
                   end
                end   
                text = ""
                lists = create_lists(13)                
                i = 0
  		case sort_col
                  when 0 
                     @data = @data.sort_by {|r| r[:trigger_name] || ""}  
                  when 1 
                     @data = @data.sort_by {|r| r[:created_time]}
                  when 2 
                     @data = @data.sort_by {|r| r[:status] || ""}                     
  		  when 3 
                     @data = @data.sort_by {|r| r[:measure_name]}                     
                  when 4 
                     @data = @data.sort_by {|r| r[:statistic] || ""}
                  when 5 
                     @data = @data.sort_by {|r| r[:period] || ""}
                  when 6 
                     @data = @data.sort_by {|r| r[:lower_threshold] || ""}                           
                  when 7 
                     @data = @data.sort_by {|r| r[:lower_breach_scale_increment] || ""}
                  when 8 
                     @data = @data.sort_by {|r| r[:upper_threshold]}               
                  when 9 
                     @data = @data.sort_by {|r| r[:upper_breach_scale_increment]}
                  when 10 
                     @data = @data.sort_by {|r| r[:breach_duration]}
                  when 11 
                     @data = @data.sort_by {|r| r[:unit] || ""}
                end                
                @data.each do |r|
                     lists[0][i] = r[:trigger_name]
                     lists[1][i] = convert_time(r[:created_time])
      	 	     lists[2][i] = r[:status]
      	 	     lists[3][i] = r[:measure_name]
      	 	     lists[4][i] = r[:statistic]
      	 	     lists[5][i] = r[:period].to_s
      	 	     lists[6][i] = r[:lower_threshold].to_s
       	 	     lists[7][i] = r[:lower_breach_scale_increment].to_s
      	 	     lists[8][i] = r[:upper_threshold].to_s
      	 	     lists[9][i] = r[:upper_breach_scale_increment].to_s
       	 	     lists[10][i] = r[:breach_duration].to_s
 		     lists[11][i] = r[:unit]
		     lists[12][i] = ""
		     d = ""
		     if r[:dimensions] != nil
		        r[:dimensions].each_pair do |k,v|
		           if d == ""
		              d="#{k}=#{v}"
		           else
		              d = "#{d},#{k}=#{v}"
		           end
		        end  
		        lists[12][i] = d
		     end   
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 13)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,13)
                  @loaded = true
  end           

end  
  