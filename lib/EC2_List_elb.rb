class EC2_List

def load_elb(sort_col,reload)
         elb = @ec2_main.environment.elb_connection
         if elb != nil 
                if reload == true
                   @data = Array.new
                   i = 0
                   elb.describe_load_balancers.each do |r|
                      @data[i] = r
                      i = i+1
                   end
                end   
                text = ""
                lists = create_lists(7)                
                i = 0
    		case sort_col  
    		   when 0 
                       @data = @data.sort_by {|r| r[:load_balancer_name]}
                    when 1 
                       @data = @data.sort_by {|r| r[:dns_name] || ""}
                    when 2 
                       @data = @data.sort_by {|r| r[:created_time]}
                end                    
                @data.each do |r|
      	 	   lists[0][i] = r[:load_balancer_name]
         	   lists[1][i] = r[:dns_name]
        	   lists[2][i] = convert_time(r[:created_time])
        	   r[:instances].each do |l|
        	      if lists[3][i].nil?
        	         lists[3][i] = "#{l}" 
        	      else
        	         lists[3][i] = "#{lists[3][i]},#{l}"
        	      end   
        	   end   
        	   r[:listeners].each do |l|
        	      if lists[4][i].nil?
        	         lists[4][i] = "#{l[:protocol]},#{l[:load_balancer_port]},#{l[:instance_port]},#{l[:policy_names]}"
        	      else
        	         lists[4][i] = "#{lists[4][i]};#{l[:protocol]},#{l[:load_balancer_port]},#{l[:policy_names]}"
        	      end   
        	   end
		   r[:app_cookie_stickiness_policies].each do |l|
        	      if lists[5][i].nil?
        	         lists[5][i] = "#{l[:policy_name]},#{l[:cookie_name]},#{l[:cookie_expiration_period]}"
        	      else
        	         lists[5][i] = "#{lists[5][i]};#{l[:policy_name]},#{l[:cookie_name]},#{l[:cookie_expiration_period]}"
        	      end   
        	   end
  		   r[:lb_cookie_stickiness_policies].each do |l|
        	      if lists[5][i].nil?
        	         lists[5][i] = "#{l[:policy_name]},#{l[:cookie_name]},#{l[:cookie_expiration_period]}"
        	      else
        	         lists[5][i] = "#{lists[5][i]};#{l[:policy_name]},#{l[:cookie_name]},#{l[:cookie_expiration_period]}"
        	      end   
        	   end      	   
        	   r[:availability_zones].each do |l|
        	      if lists[6][i].nil?
        	         lists[6][i] = "#{l}"
        	      else
         	         lists[6][i] = "#{lists[6][i]},#{l}" 
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
  end

end