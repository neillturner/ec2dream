
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/ELB_Dialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/AS_LaunchConfigurationDialog'

include Fox

class AS_GroupCreateDialog < FXDialogBox

  def initialize(owner)
    	puts "ASGroupCreateDialog.initialize"
    	@ec2_main = owner
    	sel_instance = ""
    	@created = false
    	@elb_table = Array.new
    	@elb_curr_row = nil
    	@az_table = Array.new
    	@az_curr_row = nil
    	super(owner, "Create Auto Scaling Group", :opts => DECOR_ALL, :width => 600, :height => 200)
    	@frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "Group Name" )
    	@auto_scaling_group_name = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(@frame1, "" )

    	FXLabel.new(@frame1, "Launch Configuration")
    	@launch_configuration_name = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
    	@lc_select_button = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
	@lc_select_button.icon = @create
	@lc_select_button.tipText = "  Select Launch Configuration  "
	@lc_select_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = AS_LaunchConfigurationDialog.new(@ec2_main)
	   dialog.execute
	   lc = dialog.selected
	   if lc != nil and lc != ""
	      @launch_configuration_name = lc
	   end   	
      end
      @lc_select_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end

    	FXLabel.new(@frame1, "Availability Zones")
    	@availability__zones = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    	@az_create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@az_create_button.icon = @create
	@az_create_button.tipText = "  Add Availability Zone "
	@az_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      @az_table.push(az)
              load_az_table
	   end   	
        end
        @az_create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@az_delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	@az_delete_button.icon = @delete
	@az_delete_button.tipText = "  Delete Availability Zone  "
	@az_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      @az_table.delete(az)
              load_az_table
	   end 
	end
	@az_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end

    	FXLabel.new(@frame1, "Min Size" )
    	@min_size = FXTextField.new(@frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	@min_size.text = "1" 
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Max Size" )
    	@max_size = FXTextField.new(@frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
	@max_size.text = "1" 
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "Cooldown" )
    	@cooldown = FXTextField.new(@frame1, 15, nil, 0, :opts => FRAME_SUNKEN)
      @cooldown.text = "0" 
	FXLabel.new(@frame1, "" )

    	FXLabel.new(@frame1, "Load Balancers")
    	@load_balancer_names = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
    	@elb_create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	@elb_create_button.icon = @create
	@elb_create_button.tipText = "  Add Load Balancer"
	@elb_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = ELB_Dialog.new(@ec2_main)
	   dialog.execute
	   elb = dialog.selected
	   if elb != nil and elb != ""
	      @elb_table.push(elb)
              load_elb_table
	   end   	
        end
        @elb_create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@elb_delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	@elb_delete_button.icon = @delete
	@elb_delete_button.tipText = "  Delete Availability Zone  "
	@elb_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = ELB_Dialog.new(@ec2_main)
	   dialog.execute
	   elb = dialog.selected
	   if elb != nil and elb != ""
	      @elb_table.delete(elb)
              load_elb_table
	   end 
	end
	@elb_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )

        FXLabel.new(@frame1, "" )
        create = FXButton.new(@frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(@frame1, "" )
        create.connect(SEL_COMMAND) do |sender, sel, data|
           if @auto_scaling_group_name.text == nil or @auto_scaling_group_name.text == ""
              error_message("Error","No Auto Scaling Group Name specified")
           else
              create_as
              if @created == true
                 self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
              end  
           end  
       end
       load_elb_table
       load_az_table
  end 
  
  def create_as
     as = @ec2_main.environment.as_connection
     if as != nil
      begin 
       options={}
       if @min_size.text != nil and @min_size.text != ""
          options[:min_size] = @min_size.text 
       end
	 if @max_size.text != nil and @max_size.text != ""
          options[:max_size] = @max_size.text 
       end
	 if @cooldown.text != nil and @cooldown.text != ""
          options[:cooldown] = @cooldown.text 
       end      
       r = as.create_auto_scaling_group(@auto_scaling_group_name, @launch_configuration_name, @availability_zones, options)
       @created = true
      rescue
        error_message("Create Auto Scaling Group Failed",$!.to_s)
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


  def created
    @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
