
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/ELB_Dialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/AS_LaunchConfigurationDialog'

include Fox

class AS_GroupEditDialog < FXDialogBox

  def initialize(owner, item=nil)
    	puts "ASGroupCreateDialog.initialize"
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
    	super(owner, @title, :opts => DECOR_ALL, :width => 600, :height => 250)
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

    	FXLabel.new(frame1, "Min Size" )
    	min_size = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	min_size.text = "1" 
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Max Size" )
    	max_size = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	max_size.text = "1" 
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Cooldown" )
    	cooldown = FXTextField.new(frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
      cooldown.text = "0" 
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
              options={}
              if min_size.text != nil and min_size.text != ""
                 options[:min_size] = min_size.text 
       	      end
	      if max_size.text != nil and max_size.text != ""
                 options[:max_size] = max_size.text 
       	      end
	      if cooldown.text != nil and cooldown.text != ""
                 options[:cooldown] = cooldown.text 
       	      end
       	      options[:load_balancer_names] = @elb_table
              create_or_update_as(auto_scaling_group_name.text, launch_configuration_name.text, @az_table , options)
              if @saved == true
                 self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
              end  
           end  
       end
       if @result != ""
          as = @ec2_main.environment.as_connection
          if as != nil 
             as.describe_auto_scaling_groups(@result).each do |r|
        		auto_scaling_group_name.text = r[:auto_scaling_group_name]
        		launch_configuration_name.text = r[:launch_configuration_name]
                  @az_table = r[:availability_zones]
			min_size.text = r[:min_size].to_s
			max_size.text = r[:max_size].to_s
			cooldown.text = r[:cooldown].to_s
			@elb_table = r[:load_balancer_names]
               end
          end
       end
       load_elb_table
       load_az_table
  end 
  
  def create_or_update_as(auto_scaling_group_name, launch_configuration_name, az_table , options)
     as = @ec2_main.environment.as_connection
     if as != nil
        if @result != ""
          begin
            options[:availability_zones]= az_table 
            options[:launch_configuration_name] = launch_configuration_name 
            r = as.update_auto_scaling_group(auto_scaling_group_name, options)
            @saved = true
          rescue
            error_message("Update Auto Scaling Group Failed",$!.to_s)
          end
        else 
          begin 
            r = as.create_auto_scaling_group(auto_scaling_group_name, launch_configuration_name, az_table , options)
            @saved = true
          rescue
            error_message("Create Auto Scaling Group Failed",$!.to_s)
          end
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
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
