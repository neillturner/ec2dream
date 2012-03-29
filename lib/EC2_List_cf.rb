class EC2_List

def load_cloud_formation_templates(sort_col,reload)
         cf = EC2_Properties.new
         if cf != nil 
                if reload == true
                   @data = Array.new
                   i = 0
                   cf.all("cf_templates").each do |r|
                      @data[i] = r
                      i = i+1
                   end
                end 
                text = ""
                lists = create_lists(5)                
                i = 0
    		case sort_col  
    		   when 0 
                       @data = @data.sort_by {|r| r['stack_name']}
                    when 1 
                       @data = @data.sort_by {|r| r['template_file']}
                end                    
                @data.each do |r|
      	 	   lists[0][i] = r['stack_name']
         	   lists[1][i] = r['template_file']
        	   lists[2][i] = r['parameters']
        	   if r['disable_rollback'] != nil and r['disable_rollback'] != ""
        	      lists[3][i] = r['disable_rollback']
        	   end 
        	   if r['timeout_in_minutes'] != nil and r['timeout_in_minutes'] != ""
        	      lists[4][i] = r['timeout_in_minutes']
        	   end   
                   i = i+1
               end
               i = lists[0].length
               @table.setTableSize(i, 5)
    	       set_table_titles(@type)
    	       set_table_data(lists,5)
               @loaded = true
        end     
  end
  
  def load_cloud_formation_stacks(sort_col,reload)
           cf = @ec2_main.environment.cf_connection
           if cf != nil 
                  if reload == true
                     @data = Array.new
                     i = 0
                     options = {}
                     options['StackName'] = @stack_name
                     begin 
                        response = cf.describe_stacks(options)
                        @data = response.body['Stacks']
                     rescue Excon::Errors::BadRequest => e
	                puts "Cloud Formation Error: #{e.response.body}"
        	     end    
                  end 
                  text = ""
                  lists = create_lists(5)                
                  i = 0
      		  case sort_col  
      		   when 0 
                         @data = @data.sort_by {|r| r['StackName']}
                   when 1 
                         @data = @data.sort_by {|r| r['StackId']}
                   when 2 
                         @data = @data.sort_by {|r| r['StackStatus']}      
                  end                    
                  @data.each do |r|
        	   lists[0][i] = r['StackName']
           	   lists[1][i] = r['StackId']
          	   lists[2][i] = r['StackStatus']
          	   lists[3][i] = r['CreationTime'].to_s
          	   lists[4][i] = r['DisableRollback'].to_s
                   i = i+1
                 end
                 i = lists[0].length
                 @table.setTableSize(i, 5)
      	         set_table_titles(@type)
      	         set_table_data(lists,5)
                 @loaded = true
          end     
  end
  
  def load_cloud_formation_events(sort_col,reload)
             cf = @ec2_main.environment.cf_connection
             if cf != nil 
                    if reload == true
                       @data = Array.new
                       i = 0
                       begin 
                          response = cf.describe_stack_events(@stack_name)
                          @data = response.body['StackEvents']
                       rescue Excon::Errors::BadRequest => e
  	                  puts "Cloud Formation Error: #{e.response.body}"
          	       end    
                    end 
                    text = ""
                    lists = create_lists(8)                
                    i = 0
        		  case sort_col  
        		   when 0 
                           @data = @data.sort_by {|r| r['EventId']}
                     when 1 
                           @data = @data.sort_by {|r| r['StackId']}
                    end                    
                    @data.each do |r|
          	        lists[0][i] = r['EventId']
             	        lists[1][i] = r['StackId']
            	        lists[2][i] = r['LogicalResourceId']
            	        lists[3][i] = r['PhysicalResourceId']
            	        lists[4][i] = r['ResourceType']
            	        lists[5][i] = r['Timestamp'].to_s
            	        lists[6][i] = r['ResourceStatus']
            	        lists[7][i] = r['ResourceStatusReason']
                        i = i+1
                    end
                    i = lists[0].length
                    @table.setTableSize(i, 8)
        	    set_table_titles(@type)
        	    set_table_data(lists,8)
                    @loaded = true
            end     
  end
  
  
  def cf_validate(template_file) 
     doc = File.open(template_file, 'rb') { |file| file.read }
     options = {}
     options['TemplateBody'] = doc
     cf = @ec2_main.environment.cf_connection
     if cf != nil
	begin
           response = cf.validate_template(options)
        rescue Excon::Errors::BadRequest => e
	   FXMessageBox.warning(@ec2_main,MBOX_OK,"Template Validation Error",e.response.body)
        else
           FXMessageBox.warning(@ec2_main,MBOX_OK,"Template validated successfully","Template validated successfully.")
        end        
     end   
  end 
  
  def cf_create_stack(stack_name, template_file, parameters )
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stack Create","Confirm Creation of Stack #{stack_name}")
     if answer == MBOX_CLICKED_YES
        doc = File.open(template_file, 'rb') { |file| file.read }
        options = {}
        options['TemplateBody'] = doc
        if parameters != nil and parameters != ""
           options['Parameters'] = parameters
        end   
        cf = @ec2_main.environment.cf_connection
        if cf != nil
	   begin
              response = cf.create_stack(stack_name, options)
           rescue Excon::Errors::BadRequest => e
	      FXMessageBox.warning(@ec2_main,MBOX_OK,"Stack Creation Error",e.response.body)
           else
              @stack_name = stack_name
              load("Cloud Formation Stacks")
           end   
        end        
     end   
  end 
  
   def cf_delete_stack(stack_name)
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stack Delete","Confirm Delete of Stack #{stack_name}")
     if answer == MBOX_CLICKED_YES   
       cf = @ec2_main.environment.cf_connection
       if cf != nil
  	   begin
             response = cf.delete_stack(stack_name)
           rescue Excon::Errors::BadRequest => e
  	     FXMessageBox.warning(@ec2_main,MBOX_OK,"Stack deletion Error",e.response.body)
          end        
       end
     end  
  end 
  
end