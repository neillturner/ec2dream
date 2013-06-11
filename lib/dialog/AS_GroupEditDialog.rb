require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

require 'dialog/ELB_Dialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/AS_LaunchConfigurationDialog'
require 'dialog/AS_TagsAssignDialog'
require 'common/error_message'

include Fox

class AS_GroupEditDialog < FXDialogBox

  def initialize(owner, item=nil)
    	puts "ASGroupEditDialog.initialize"
    	@ec2_main = owner
      @title = ""
      if item == nil 
         @result = ""
         @title = "Create Auto Scaling Group"
      else
         @result = item
         @title = "Update Auto Scaling Group"
      end
    	sel_instance = ""
    	@saved = false
    	@elb_table = Array.new
    	@az_table = Array.new
	@kill = @ec2_main.makeIcon("kill.png")
	@kill.create
	@add = @ec2_main.makeIcon("add.png")
	@add.create
        @magnifier = @ec2_main.makeIcon("magnifier.png")
        @magnifier.create
        @edit = @ec2_main.makeIcon("application_edit.png")
        @edit.create
    	super(owner, @title, :opts => DECOR_ALL, :width => 650, :height => 450)
    	frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    	FXLabel.new(frame1, "" )
    	FXLabel.new(frame1, "" )
    	FXLabel.new(frame1, "" )
    	FXLabel.new(frame1, "Group Name" )
    	auto_scaling_group_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(frame1, "" )
    	FXLabel.new(frame1, "Launch Configuration")
    	launch_configuration_name = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    	lc_select_button = FXButton.new(frame1, " ",:opts => BUTTON_TOOLBAR)
	lc_select_button.icon = @magnifier
	lc_select_button.tipText = "  Select Launch Configuration  "
	lc_select_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = AS_LaunchConfigurationDialog.new(@ec2_main)
	   dialog.execute
	   lc = dialog.selected
	   if lc != nil and lc != ""
	      launch_configuration_name.text = lc
	   end   	
      end
      lc_select_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end

    	FXLabel.new(frame1, "Availability Zones")
    	@avail_zones = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    	az_create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	az_create_button.icon = @add
	az_create_button.tipText = "  Add Availability Zone "
	az_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      @az_table.push(az)
              load_az_table
	   end   	
        end
        az_create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	az_delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	az_delete_button.icon = @kill
	az_delete_button.tipText = "  Delete Availability Zone  "
	az_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      @az_table.delete(az)
              load_az_table
	   end 
	end
	az_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end
        FXLabel.new(frame1, "Tags")
    	tags = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1t = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1t, " ",:opts => LAYOUT_LEFT )
    	tags_button = FXButton.new(page1t, " ",:opts => BUTTON_TOOLBAR)
	tags_button.icon = @edit
	tags_button.tipText = "  Edit Tags "
	tags_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = AS_TagsAssignDialog.new(@ec2_main,auto_scaling_group_name.text)
	   dialog.execute
	   if dialog.saved
	       item = dialog.item
               tags.text = ""
               item.each do |y|
                  tags.text = tags.text + "#{y['Key']}=#{y['Value']}"
                  tags.text = tags.text + "(Propagate) " if y['PropagateAtLaunch'] = true
                  tags.text = tags.text + " " if y['PropagateAtLaunch'] = false
               end	       
	   end   	
        end
    	FXLabel.new(frame1, "Min Size" )
    	min_size = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	min_size.text = "1" 
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Max Size" )
    	max_size = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	max_size.text = "2" 
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Cooldown (secs)" )
    	cooldown = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
        cooldown.text = ""
        FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Desired Capacity" )
    	desired_capacity = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
        desired_capacity.text = ""         
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Health Grace Period (secs)" )
    	health_check_grace_period = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Health Check Type (EC2 or ELB)" )
    	health_check_type = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(frame1, "" )	
    	FXLabel.new(frame1, "Load Balancers")
    	@load_balancer_names = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1b = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
    	elb_create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	elb_create_button.icon = @add
	elb_create_button.tipText = "  Add Load Balancer"
	elb_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = ELB_Dialog.new(@ec2_main)
	   dialog.execute
	   elb = dialog.selected
	   if elb != nil and elb != ""
	      @elb_table.push(elb)
              load_elb_table
	   end   	
        end
        elb_create_button.connect(SEL_UPDATE) do |sender, sel, data|
         if @title == "Create Auto Scaling Group"
  	      sender.enabled = true
         else
		sender.enabled = false
         end
	end
	elb_delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	elb_delete_button.icon = @kill 
	elb_delete_button.tipText = "  Delete Availability Zone  "
	elb_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = ELB_Dialog.new(@ec2_main)
	   dialog.execute
	   elb = dialog.selected
	   if elb != nil and elb != ""
	      @elb_table.delete(elb)
              load_elb_table
	   end 
	end
	elb_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end
    	
    	FXLabel.new(frame1, "Placement Group")
    	placement_group = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    	FXLabel.new(frame1, "" )
    	
    	FXLabel.new(frame1, "VPC Zone_Identifier")
    	vpc_zone_identifier = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    	FXLabel.new(frame1, "" ) 
 
    	FXLabel.new(frame1, "Enabled Metrics")
    	enabled_metrics = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    	FXLabel.new(frame1, "" )

    	FXLabel.new(frame1, "Suspended Processes")
    	suspended_processes = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    	FXLabel.new(frame1, "" )
    	
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "" )

        FXLabel.new(frame1, "" )
        create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(frame1, "" )
        create.connect(SEL_COMMAND) do |sender, sel, data|
           if auto_scaling_group_name.text == nil or auto_scaling_group_name.text == ""
              error_message("Error","No Auto Scaling Group Name specified")
           else
              # test deleting an option
              options={}
	      if cooldown.text != nil and cooldown.text != ""
                 options['DefaultCooldown'] = cooldown.text 
       	      end
	      if desired_capacity.text != nil and desired_capacity.text != ""
                 options['DesiredCapacity'] = desired_capacity.text 
       	      end 
	      if health_check_grace_period.text != nil and health_check_grace_period.text != ""
                 options['HealthCheckGracePeriod'] = health_check_grace_period.text 
       	      end 
	      if health_check_type.text != nil and health_check_type.text != ""
                 options['HealthCheckType'] = health_check_type.text 
       	      end       	      
	      if placement_group.text != nil and placement_group.text != ""
                 options['PlacementGroup'] = placement_group.text 
       	      end 
	      if vpc_zone_identifier.text != nil and vpc_zone_identifier.text != ""
                 options['VPCZoneIdentifier'] = vpc_zone_identifier.text 
       	      end        	      
       	      options['LoadBalancerNames'] = @elb_table
              create_or_update_as(auto_scaling_group_name.text, launch_configuration_name.text, @az_table ,max_size.text, min_size.text, options)
              if @saved == true
                 self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
              end  
           end  
       end
       if @result != ""
             #as.describe_auto_scaling_groups(@result).each do |r|
             r = @ec2_main.environment.auto_scaling_groups.get(@result)
        		auto_scaling_group_name.text = r[:auto_scaling_group_name]
        		launch_configuration_name.text = r[:launch_configuration_name]
                        @az_table = r[:availability_zones]
                        tags.text = ""
                        r[:tags].each do |y|
                           tags.text = tags.text + "#{y['Key']}=#{y['Value']}"
                           tags.text = tags.text + "(Propagate) " if y['PropagateAtLaunch'] = true
                           tags.text = tags.text + " " if y['PropagateAtLaunch'] = false
                        end   
			min_size.text = r[:min_size].to_s
			max_size.text = r[:max_size].to_s
			cooldown.text = r[:cooldown].to_s
			@elb_table = r[:load_balancer_names]
                        #desired_capacity.text = r[:desired_capacity].to_s 
 		        health_check_grace_period.text = r[:health_check_grace_period].to_s
 		        health_check_type.text = r[:health_check_type]
                        placement_group.text = r[:placement_group]
                        vpc_zone_identifier.text = r[:vpc_zone_identifier].to_s	
	                enabled_metrics.text = r[:enabled_metrics].to_s
	                suspended_processes.text = r[:suspended_processes].to_s
       else
          health_check_type.text = "EC2"
          
       end
       load_elb_table
       load_az_table
  end 
  
  def create_or_update_as(auto_scaling_group_name, launch_configuration_name, az_table, max_size, min_size, options)
        if @result != ""
          begin
            options['AvailabilityZones']= az_table 
            options['LaunchConfigurationName'] = launch_configuration_name
            options['MaxSize'] = max_size
            options['MinSize'] = min_size
            r = @ec2_main.environment.auto_scaling_groups.update_auto_scaling_group(auto_scaling_group_name, options)
            @saved = true
            @result = auto_scaling_group_name
          rescue
            error_message("Update Auto Scaling Group Failed",$!)
          end
        else 
          begin 
            r =  @ec2_main.environment.auto_scaling_groups.create_auto_scaling_group(auto_scaling_group_name, az_table, launch_configuration_name, max_size, min_size,  options)
            @saved = true
          rescue
            error_message("Create Auto Scaling Group Failed",$!)
          end
        end 
  end 
  
  def load_az_table
         @avail_zones.text = ""
         i = 0
         @az_table.each do |m|
           if m!= nil
              if @avail_zones.text != ""
                 @avail_zones.text = @avail_zones.text + "," + m
              else
                 @avail_zones.text = m
              end
              i = i+1
   	   end 
         end   
   end

  def load_elb_table
         @load_balancer_names.text = ""
         i = 0
         @elb_table.each do |m|
           if m!= nil
              if @load_balancer_names.text != ""
                 @load_balancer_names.text = @load_balancer_names.text + "," + m
              else
                 @load_balancer_names.text = m
              end
              i = i+1
   	   end 
         end   
   end

  def saved
    @saved
  end
  
  def success
     @saved
  end

end
