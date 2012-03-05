
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/ELB_ListenerEditDialog'
require 'dialog/EC2_AvailZoneDialog'

include Fox

class ELB_CreateDialog < FXDialogBox

  def initialize(owner)
    	puts "ELBCreateDialog.initialize"
    	@ec2_main = owner
    	sel_instance = ""
    	@created = false
    	@listener_table = Array.new
    	el = {}
        el[:protocol] = "HTTP"
        el[:load_balancer_port] = "80"
        el[:instance_port] = "80"    	
    	@listener_table.push(el)
    	@curr_row = nil
    	@az_table = Array.new
    	@az_curr_row = nil
    	super(owner, "Create Elastic Load Balancer", :opts => DECOR_ALL, :width => 600, :height => 200)
    	@frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "ELB Name" )
    	@elb_name = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "Listeners")
    	@elb_listeners = FXTable.new(@frame1,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_READONLY  )
        @header1 = @elb_listeners.columnHeader
	@header1.connect(SEL_COMMAND) do |sender, sel, which|
	# do nothing
	end    	
    	@elb_listeners.connect(SEL_COMMAND) do |sender, sel, which|
    	   @curr_row = which.row
    	   @elb_listeners.selectRow(@curr_row)
    	end
    	page1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    	@create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@create = @ec2_main.makeIcon("add.png")
	@create.create
	@create_button.icon = @create
	@create_button.tipText = "  Add Listener  "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	      editdialog = ELB_ListenerEditDialog.new(@ec2_main,nil)
              editdialog.execute
              if editdialog.saved 
                el = editdialog.result
                @listener_table.push(el)
                load_listener_table
              end   
        end
        @create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
        @edit_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
	@edit_button.icon = @edit
	@edit_button.tipText = "  Edit Listener  "
	@edit_button.connect(SEL_COMMAND) do |sender, sel, data|
	      if @curr_row == nil
		 error_message("No Listener Selected","No listener selected to edit")
              else
  	         editdialog = ELB_ListenerEditDialog.new(@ec2_main,@listener_table[@curr_row])
                 editdialog.execute
                 if editdialog.saved 
                    el = editdialog.result
                    @listener_table[@curr_row] = el
                    load_listener_table                   
                 end
              end   
        end	
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@delete_button.icon = @delete
	@delete_button.tipText = "  Delete Listener  "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
		if @curr_row == nil
		   error_message("No Listener selected","No Listener selected to delete")
                else
                   m = @listener_table[@curr_row]
                   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of listener #{m[:protocol]};#{m[:load_balancer_port]};#{m[:instance_port]}")
                   if answer == MBOX_CLICKED_YES 
                      @listener_table.delete_at(@curr_row)
                      puts @listener_table
                      load_listener_table
                   end   
	        end  
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	end	    
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
    	FXLabel.new(@frame1, "Availability Zones")
    	@avail_zones = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
    	@az_create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
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

        FXLabel.new(@frame1, "" )
        create = FXButton.new(@frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(@frame1, "" )
        create.connect(SEL_COMMAND) do |sender, sel, data|
           if @elb_name.text == nil or @elb_name.text == ""
              error_message("Error","No Elastic Load Balancer Name specified")
           else
              create_elb
              if @created == true
                 self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
              end  
           end  
       end
       load_listener_table
       load_az_table
  end 
  
  def create_elb
     elb = @ec2_main.environment.elb_connection
     if elb != nil
      begin 
       r = elb.create_load_balancer(@elb_name,  @az_table, @listener_table)
       @created = true
      rescue
        error_message("Create Elastic Load Balancer Failed",$!.to_s)
      end 
     end
  end 
  
  def load_listener_table
         @elb_listeners.clearItems
         @elb_listeners.rowHeaderWidth = 0	
         @elb_listeners.setTableSize(@listener_table.size, 3)
         @elb_listeners.setColumnText(0, "Protocol")
         @elb_listeners.setColumnText(1, "Load Balancer Port")
         @elb_listeners.setColumnText(2, "Instance Port") 
         @elb_listeners.setColumnWidth(1,150)
         i = 0
         @listener_table.each do |m|
           if m!= nil 
              @elb_listeners.setItemText(i, 0, "#{m[:protocol]}")
              @elb_listeners.setItemText(i, 1, "#{m[:load_balancer_port]}")
              @elb_listeners.setItemText(i, 2, "#{m[:instance_port]}")
              @elb_listeners.setItemJustify(i, 0, FXTableItem::LEFT)
              @elb_listeners.setItemJustify(i, 1, FXTableItem::LEFT)
              @elb_listeners.setItemJustify(i, 2, FXTableItem::LEFT)
              i = i+1
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


  def created
    @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
