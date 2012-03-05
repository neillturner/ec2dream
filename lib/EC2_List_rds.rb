class EC2_List  
  
  def load_db_parameter_groups(sort_col,reload)
                  if reload == true
                     @data = Array.new
                     rds = @ec2_main.environment.rds_connection
                     if rds != nil 
                        i = 0
                        rds.describe_db_parameter_groups.each do |r|
                            @data[i] = r
                           i = i+1
                        end
                     end
                  end
                  lists = create_lists(3)
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:name]}
                  when 1 
                     @data = @data.sort_by {|r| r[:description]}
                  when 2 
                     @data = @data.sort_by {|r| r[:db_parameter_group_family]}
                  end
                  @data.each do |r|
                     lists[0][i] = r[:name]
       	 	   lists[1][i] = r[:description]
       	 	   lists[2][i] = r[:db_parameter_group_family]     	 	   
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 3)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,3)
                @loaded = true
  end              
  
  def load_db_parameters(sort_col,reload)
                  @title.text = "DB Parameters - "+@db_parm_grp
                  if reload == true
                     @data = Array.new
                     rds = @ec2_main.environment.rds_connection
                     if rds != nil 
                        i = 0
                        rds.describe_db_parameters([@db_parm_grp]).each do |r|
                           @data[i] = r
                           i = i+1
                        end   
                     end
                  end   
                  text = ""
                  lists = create_lists(9)                
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:name]}
                  when 1 
                     @data = @data.sort_by {|r| r[:value] || ""}
                  when 2 
                     @data = @data.sort_by {|r| r[:source]}
                  when 3 
                     @data = @data.sort_by {|r| r[:apply_type]}
                  when 4 
                     @data = @data.sort_by {|r| r[:data_type]}
                  when 5 
                     @data = @data.sort_by {|r| r[:allowed_values] || ""}
                  when 6 
                     @data = @data.sort_by {|r| r[:is_modifiable] || ""}
                  when 7 
                     @data = @data.sort_by {|r| r[:minimum_version] || ""}                     
                  when 8 
                     @data = @data.sort_by {|r| r[:description]}
                  end                
                  @data.each do |r|
                     lists[0][i] = r[:name]
      	 	     lists[1][i] = r[:value]
       	 	     lists[2][i] = r[:source]
      	 	     lists[3][i] = r[:apply_type]
      	 	     lists[4][i] = r[:data_type]
      	 	     lists[5][i] = r[:allowed_values]
      	 	     lists[6][i] = r[:is_modifiable].to_s 
     	 	     lists[7][i] = r[:minimum_version]      	 	   
      	 	     lists[8][i] = r[:description]    	 	   
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 9)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,9)
                  while i>0
                     i = i-1
  		     @table.setItemJustify(i, 2, FXTableItem::RIGHT)
                  end     
                @loaded = true
  end              
  
  def load_db_snapshots(sort_col,reload)
                @create_button.tipText = "Create DB Snapshot"
     	        @delete_button.tipText = "Delete DB Snapshot"
     	        @launch_button.tipText = "Restore DB Instance from DB Snapshot"
                  if reload == true
                     @data = Array.new
                     rds = @ec2_main.environment.rds_connection
                     if rds != nil 
                        i = 0
                           rds.describe_db_snapshots.each do |r|
                              @data[i] = r
                              i = i+1
                           end
                     end
                  end   
                  text = ""
                  lists = create_lists(11)
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:aws_id]}
                  when 1 
                     @data = @data.sort_by {|r| r[:instance_aws_id]}
                  when 2 
                     @data = @data.sort_by {|r| r[:create_time]}
                  when 3 
                     @data = @data.sort_by {|r| r[:engine]}
                  when 4 
                     @data = @data.sort_by {|r| r[:engine_version]}                     
                  when 5 
                     @data = @data.sort_by {|r| r[:allocated_storage]}
                  when 6 
                     @data = @data.sort_by {|r| r[:status]}
                  when 7 
                     @data = @data.sort_by {|r| r[:endpoint_port]}
                  when 8 
                     @data = @data.sort_by {|r| r[:availability_zone]}
                  when 9 
                     @data = @data.sort_by {|r| r[:instance_create_time] }
                  when 10 
                     @data = @data.sort_by {|r| r[:master_username]}
                  end 
                  @data.each do |r|
                     lists[0][i] = r[:aws_id]
       	 	   lists[1][i] = r[:instance_aws_id]
       	 	   lists[2][i] = convert_time(r[:create_time])
      	 	   lists[3][i] = r[:engine]
      	 	   lists[4][i] = r[:engine_version]
      	 	   lists[5][i] = r[:allocated_storage].to_s
      	 	   lists[6][i] = r[:status]
      	 	   lists[7][i] = r[:endpoint_port].to_s
      	 	   lists[8][i] = r[:availability_zone]
      	 	   lists[9][i] = convert_time(r[:instance_create_time])
      	 	   lists[10][i] = r[:master_username]
                     i = i+1
                  end
                  i = lists[0].length
                  @table.setTableSize(i, 11)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,11)
                 @loaded = true
  end              
  
  def load_db_events(sort_col,reload)
                  if reload == true
                     @data = Array.new
                     rds = @ec2_main.environment.rds_connection
                     if rds != nil 
                        i = 0
                        rds.describe_events.each do |r|
                           @data[i] = r
                           i = i+1
                        end
                     end
                  end
                  text = ""
                  lists = create_lists(4)
                  i = 0
  		case sort_col  
  		   when 0 
                     @data = @data.sort_by {|r| r[:aws_id]}
                  when 1 
                     @data = @data.sort_by {|r| r[:source_type]}
                  when 2 
                     @data = @data.sort_by {|r| r[:date]}
                  when 3 
                     @data = @data.sort_by {|r| r[:message]}
                  end
                  @data.each do |r|
                     lists[0][i] = r[:aws_id]
       	 	   lists[1][i] = r[:source_type]
       	 	   lists[2][i] = convert_time(r[:date])
      	 	   lists[3][i] = r[:message]
                     i = i+1
                  end   
                  i = lists[0].length
                  @table.setTableSize(i, 4)
  	    	  set_table_titles(@type)
  	    	  set_table_data(lists,4)
                 @loaded = true
  end 

end  
  