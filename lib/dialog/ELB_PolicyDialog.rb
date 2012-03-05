
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/ELB_PolicyCreateDialog'
require 'dialog/ELB_PolicySetDialog'

include Fox

class ELB_PolicyDialog < FXDialogBox

   def initialize(owner, load_balancer, a_item, l_item)
    	puts "ELBPolicyDialog.initialize"
    	@ec2_main = owner
    	@updated = false
    	@set = false
    	@lb_name = load_balancer
    	@policy_table = Array.new
    	@listener_table = Array.new
    	@a_table = a_item.split(/;/)
    	@a_table.each do |e|
    	   ea = e.split(/,/)
    	   el = {}
    	   ea.each_index do |i|
    	     case i 
    	      when 0
                 el[:policy_name] = ea[0]
              when 1
                 if ea[1] != nil
                    el[:cookie_name] = ea[1]
                 end   
              when 2   
                 if ea[1] != nil
                    el[:cookie_expiration_period] = ea[2]
                 end      
             end
           end  
    	   @policy_table.push(el)
    	end    	
    	@curr_row = nil
    	
    	@l_table = l_item.split(/;/)
    	@l_table.each do |e|
    	   ea = e.split(/,/)
    	   el = {}
    	   ea.each_index  do |i|
    	     case i 
    	      when 0
                el[:protocol] = ea[0]
              when 1  
                el[:load_balancer_port] = ea[1]
              when 2   
                el[:instance_port] = ea[2]
              else
                if ea[i] != nil 
                   el[:policy_names] = ea[i]
                end   
             end
           end  
    	   @listener_table.push(el)
    	end
    	@l_curr_row = nil
    	
    	super(owner, "Stickiness Policies for #{load_balancer}", :opts => DECOR_ALL, :width => 600, :height => 310)
    	@frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    	FXLabel.new(@frame1, "ELB Name" )
	@elb_name = FXTextField.new(@frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
	@elb_name.text = @lb_name
    	FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        
       
    	FXLabel.new(@frame1, "Policies")
    	@elb_policies = FXTable.new(@frame1, :height => 100, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_READONLY  )
        @header1 = @elb_policies.columnHeader
	@header1.connect(SEL_COMMAND) do |sender, sel, which|
	# do nothing
	end    	
    	@elb_policies.connect(SEL_COMMAND) do |sender, sel, which|
    	   @curr_row = which.row
    	   @elb_policies.selectRow(@curr_row)
    	end
    	page1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    	@create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
	@create = @ec2_main.makeIcon("add.png")
	@create.create
	@create_button.icon = @create
	@create_button.tipText = "  Add Policy  "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	      editdialog = ELB_PolicyCreateDialog.new(@ec2_main,@lb_name)
              editdialog.execute
              if editdialog.created 
                el = editdialog.result
                @policy_table.push(el)
                load_policy_table
              end              
        end
        @create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "" )
        FXLabel.new(@frame1, "Listeners")
    	@elb_listeners = FXTable.new(@frame1,:height => 100, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_READONLY  )
	@header2 = @elb_listeners.columnHeader
	@header2.connect(SEL_COMMAND) do |sender, sel, which|
	# do nothing
	end    	
    	@elb_listeners.connect(SEL_COMMAND) do |sender, sel, which|
    	   @l_curr_row = which.row
    	   @elb_listeners.selectRow(@l_curr_row)

    	end
    	page1b = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(page1b, " ",:opts => LAYOUT_LEFT )
        @lp_create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
	@lp_create_button.icon = @edit
	@lp_create_button.tipText = "  Set Policy for Listener"
	@lp_create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @l_curr_row == nil
	       error_message("No Listener selected","No Listener selected to set policy")
           else	
	      dialog = EC2_PolicySetDialog.new(@ec2_main,@policy_table)
	      dialog.execute
	      pn = dialog.selected
	      if pn != nil and pn != ""
	         lbp = @listener_table[@l_curr_row][:load_balancer_port]
	         @set = false
	         set_load_balancer_policies_of_listener(@lb_name, lbp, pn)
	         if @set
	            @updated = true
	            @listener_table[@l_curr_row][:policy_names] = pn
	            load_listener_table
	         end   
	      end                 
	   end   	
        end
        @lp_create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	# doesn't work - validation error
	#@lp_delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
	#@delete = @ec2_main.makeIcon("kill.png")
	#@delete.create
	#@lp_delete_button.icon = @delete
	#@lp_delete_button.tipText = "  Clear Policy for Listener  "
	#@lp_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	#   if @l_curr_row == nil
	#       error_message("No Listener selected","No Listener selected to delete policy")
        #   else
	#      lbp = @listener_table[@l_curr_row][:load_balancer_port]
	#      @set = false
	#      set_load_balancer_policies_of_listener(@lb_name, lbp, "")
	#      if @set
	#         @listener_table[@l_curr_row][:policy_names] = nil
	#         load_listener_table
	#      end   
	#   end 
	#end
	#@lp_delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	#       sender.enabled = true
	#end   	
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "" )
	FXLabel.new(@frame1, "" )	
	
        FXLabel.new(@frame1, "" )
        exit_button = FXButton.new(@frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(@frame1, "" )
        exit_button.connect(SEL_COMMAND) do |sender, sel, data|
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
        load_policy_table
        load_listener_table
   end 
  
   def load_policy_table
             @elb_policies.clearItems
             @elb_policies.rowHeaderWidth = 0	
             @elb_policies.setTableSize(@policy_table.size, 3)
     
             @elb_policies.setColumnText(0, "Policy Name")
             @elb_policies.setColumnText(1, "App Cookie Name")
             @elb_policies.setColumnText(2, "LB Cookie Expiration Period") 
             @elb_policies.setColumnWidth(1,150)
             @elb_policies.setColumnWidth(2,150)
             i = 0
             @policy_table.each do |m|
               if m!= nil 
                  @elb_policies.setItemText(i, 0, "#{m[:policy_name]}")
                  @elb_policies.setItemText(i, 1, "#{m[:cookie_name]}")
                  @elb_policies.setItemText(i, 2, "#{m[:cookie_expiration_period]}")
                  @elb_policies.setItemJustify(i, 0, FXTableItem::LEFT)
                  @elb_policies.setItemJustify(i, 1, FXTableItem::LEFT)
                  @elb_policies.setItemJustify(i, 2, FXTableItem::LEFT)
                  i = i+1
       	       end 
             end   
   end
  
   def load_listener_table
           @elb_listeners.clearItems
           @elb_listeners.rowHeaderWidth = 0	
           @elb_listeners.setTableSize(@listener_table.size, 4)
           @elb_listeners.setColumnText(0, "Protocol")
           @elb_listeners.setColumnText(1, "Load Balancer Port")
           @elb_listeners.setColumnText(2, "Instance Port")
           @elb_listeners.setColumnText(3, "Policy Names")
           @elb_listeners.setColumnWidth(0,80)
           @elb_listeners.setColumnWidth(1,110)
           @elb_listeners.setColumnWidth(2,80)
           @elb_listeners.setColumnWidth(3,150)
           i = 0
           @listener_table.each do |m|
             if m!= nil 
                @elb_listeners.setItemText(i, 0, "#{m[:protocol]}")
                @elb_listeners.setItemText(i, 1, "#{m[:load_balancer_port]}")
                @elb_listeners.setItemText(i, 2, "#{m[:instance_port]}")
                @elb_listeners.setItemText(i, 3, "#{m[:policy_names]}")
                @elb_listeners.setItemJustify(i, 0, FXTableItem::LEFT)
                @elb_listeners.setItemJustify(i, 1, FXTableItem::LEFT)
                @elb_listeners.setItemJustify(i, 2, FXTableItem::LEFT)
                @elb_listeners.setItemJustify(i, 3, FXTableItem::LEFT)
                i = i+1
     	     end 
           end   
   end
   
   def set_load_balancer_policies_of_listener(load_balancer_name, load_balancer_port,policy_name)
      elb = @ec2_main.environment.elb_connection
      if elb != nil
         begin 
            r = elb.set_load_balancer_policies_of_listener(load_balancer_name, load_balancer_port, policy_name)
            @updated = true
            @set = true
         rescue
            error_message("Setting Policy for Lstener Failed",$!.to_s)
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
