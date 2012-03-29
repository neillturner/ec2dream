class EC2_List

def load_local_servers(sort_col,reload)
         loc = EC2_Properties.new
         if loc != nil 
                if reload == true
                   @data = Array.new
                   i = 0
                   loc.all("loc_server").each do |r|
                      @data[i] = r
                      i = i+1
                   end
                end 
                text = ""
                lists = create_lists(7)                
                i = 0
    		case sort_col  
    		   when 0 
                       @data = @data.sort_by {|r| r['server']}
                    when 1 
                       @data = @data.sort_by {|r| r['address'] || ""}
                    when 2 
                       @data = @data.sort_by {|r| r['chef_node']}
                end                    
                @data.each do |r|
      	 	   lists[0][i] = r['server']
         	   lists[1][i] = r['address']
        	   lists[2][i] = r['chef_node']
        	   lists[3][i] = r['ssh_user']
        	   lists[4][i] = r['ssh_password']
        	   lists[5][i] = r['ssh_key']
        	   lists[6][i] = r['putty_key']
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