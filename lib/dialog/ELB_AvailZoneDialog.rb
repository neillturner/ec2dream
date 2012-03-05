
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/EC2_AvailZoneDialog'

include Fox

class ELB_AvailZoneDialog < FXDialogBox

  def initialize(owner, load_balancer, item)
    	puts "ELBAvailZoneDialog.initialize"
    	@ec2_main = owner
    	@updated = false
    	puts "az #{item}"
    	@az_table = item.split(/,/)
    	@az_curr_row = nil
    	super(owner, "Stickiness Policies for #{load_balancer}", :opts => DECOR_ALL, :width => 600, :height => 100)
    	@frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "Availability Zones")
    	@avail_zones = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	@avail_zones.text = item
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
    	@az_create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    	@create = @ec2_main.makeIcon("add.png")
	@create.create
	@az_create_button.icon = @create
	@az_create_button.tipText = "  Add Availability Zone "
	@az_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      if !@az_table.include?(az)
	         enable_az(load_balancer, az)
                 load_az_table
	      end                 
	   end   	
        end
        @az_create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@az_delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@az_delete_button.icon = @delete
	@az_delete_button.tipText = "  Delete Availability Zone  "
	@az_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   dialog.execute
	   az = dialog.selected
	   if az != nil and az != ""
	      if @az_table.include?(az)
	         disable_az(load_balancer, az)
                 load_az_table
	      end	              
	   end 
	end
	@az_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        exit_button = FXButton.new(@frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(@frame1, "" )
        exit_button.connect(SEL_COMMAND) do |sender, sel, data|
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
  end 
  
  def enable_az(load_balancer, item)
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Enable","Confirm enable of availability zone "+item)
     if answer == MBOX_CLICKED_YES
        elb = @ec2_main.environment.elb_connection
        if elb != nil
           begin 
              r = elb.enable_availability_zones_for_load_balancer(load_balancer, item)
              @az_table.push(item)
              @updated = true
           rescue
              error_message("Enable Availability Zones Failed",$!.to_s)
           end
        end   
     end
  end 
  
  def disable_az(load_balancer, item)
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Disable","Confirm disable of availability zone "+item)
     if answer == MBOX_CLICKED_YES
        elb = @ec2_main.environment.elb_connection
        if elb != nil
           begin 
              r = elb.disable_availability_zones_for_load_balancer(load_balancer, item)
              @az_table.delete(item)
              @updated = true
           rescue
              error_message("Enable Availability Zones Failed",$!.to_s)
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


  def updated
    @updated
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
