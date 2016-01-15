require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/ELB_PolicyCreateDialog'
require 'dialog/ELB_PolicyDeleteDialog'
require 'dialog/ELB_PolicySetDialog'
require 'dialog/ELB_SSLSetDialog'
require 'dialog/ELB_ListenerEditDialog'

include Fox

class ELB_PolicyDialog < FXDialogBox

  def initialize(owner, load_balancer)
    puts "ELBPolicyDialog.initialize  #{load_balancer}"
    @ec2_main = owner
    @updated = false
    @lb_name = load_balancer
    @policy_table = Array.new
    @listener_table = Array.new
    @curr_row = nil
    @l_curr_row = nil
    @policy = @ec2_main.makeIcon("script.png")
    @policy.create
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @ssl = @ec2_main.makeIcon("lock.png")
    @ssl.create
    @create = @ec2_main.makeIcon("add.png")
    @create.create
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create	
    super(owner, "Edit Policies and Listeners", :opts => DECOR_ALL, :width => 600, :height => 310)
    @frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "Load Balancer" )
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
    @policy_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @policy_button.icon = @create
    @policy_button.tipText = "  Add Policy  "
    @policy_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = ELB_PolicyCreateDialog.new(@ec2_main,@lb_name)
      dialog.execute
      if dialog.created 
        load_load_balancer
      end              
    end
    @policy_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @policy_delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @policy_delete_button.icon = @delete
    @policy_delete_button.tipText = "  Delete Policy  "
    @policy_delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @curr_row == nil
        error_message("No Policy selected","No Policy selected to delete")
      else
        lbp = @policy_table[@curr_row]['PolicyName']
        dialog = ELB_PolicyDeleteDialog.new(@ec2_main,@lb_name,lbp)
        if dialog.deleted 
          load_load_balancer
        end
      end   
    end
    @policy_button.connect(SEL_UPDATE) do |sender, sel, data|
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
    @create_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    @create_button.icon = @create
    @create_button.tipText = "  Create Listener  "
    @create_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = ELB_ListenerEditDialog.new(@ec2_main, @lb_name,nil)
      dialog.execute
      if dialog.saved 
        el = dialog.result
        create_load_balancer_listeners(@lb_name, [el])
      end 
    end	
    @create_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end        
    @delete_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    @delete_button.icon = @delete
    @delete_button.tipText = "  Delete Listener  "
    @delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @l_curr_row == nil
        error_message("No Listener selected","No Listener selected to delete")
      else
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Listener on port #{@listener_table[@l_curr_row]['LoadBalancerPort']}")
        if answer == MBOX_CLICKED_YES
          begin 
            @ec2_main.environment.elb.delete_load_balancer_listeners(@lb_name, [@listener_table[@l_curr_row]['LoadBalancerPort']])
            @updated = true 
            load_load_balancer
          rescue
            error_message("Delete Listener Failed",$!.to_s)
          end 
        end   
      end  
    end
    @delete_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end		    	
    @lp_policy_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    @lp_policy_button.icon = @policy
    @lp_policy_button.tipText = "  Set Policy for Listener"
    @lp_policy_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @l_curr_row == nil
        error_message("No Listener selected","No Listener selected to set policy")
      else	
        dialog = ELB_PolicySetDialog.new(@ec2_main, @lb_name, @listener_table[@l_curr_row], @policy_table)
        dialog.execute
        if dialog.saved
          @updated = true
          load_load_balancer
        end                 
      end   	
    end
    @lp_policy_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @ssl_button = FXButton.new(page1b, " ",:opts => BUTTON_TOOLBAR)
    @ssl_button.icon = @ssl
    @ssl_button.tipText = "  Set SSL for Listener"
    @ssl_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @l_curr_row == nil
        error_message("No Listener selected","No Listener selected to set SSL Certificate Id")
      elsif @listener_table[@l_curr_row]['Protocol'] != "HTTPS"
        error_message("Protocol not HTTPS","Listener Protocol is not HTTPS")
      else
        dialog = ELB_SSLSetDialog.new(@ec2_main, @lb_name, @listener_table[@l_curr_row])
        dialog.execute
        if dialog.saved
          @updated = true
          load_load_balancer
        end                 
      end   	
    end
    @ssl_button.connect(SEL_UPDATE) do |sender, sel, data|
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
    load_load_balancer
  end 
  def create_load_balancer_listeners(lb_name, listeners)
    begin 
      r = @ec2_main.environment.elb.create_load_balancer_listeners(lb_name, listeners)
      @updated = true
      load_load_balancer
    rescue
      error_message("Create Listener Failed",$!)
    end 
  end   
  def load_load_balancer
    data = @ec2_main.environment.elb.describe_load_balancers({'LoadBalancerNames' => [@lb_name]})
    if data.size>0 
      r = data[0]
      @policy_table = Array.new
      r['Policies']['AppCookieStickinessPolicies'].each do |m|
        @policy_table.push(m)
      end
      r['Policies']['LBCookieStickinessPolicies'].each do |m|
        @policy_table.push(m)
      end 
      policy_names = Array.new
      @listener_table = Array.new
      r['ListenerDescriptions'].each do |ld|
        ld['PolicyNames'].each do |p|
          policy_names.push(p)
        end             
        @listener_table.push(ld['Listener'])
      end   
      @elb_policies.clearItems
      @elb_policies.rowHeaderWidth = 0	
      @elb_policies.setTableSize(@policy_table.size, 3)
      @elb_policies.setColumnText(0, "Policy Name")
      @elb_policies.setColumnText(1, "App Cookie Name")
      @elb_policies.setColumnText(2, "LB Cookie Expiration Period")
      @elb_policies.setColumnWidth(0,150)
      @elb_policies.setColumnWidth(1,150)
      @elb_policies.setColumnWidth(2,150)
      i = 0
      @policy_table.each do |m|
        if m!= nil 
          @elb_policies.setItemText(i, 0, "#{m['PolicyName']}")
          @elb_policies.setItemText(i, 1, "#{m['CookieName']}")
          @elb_policies.setItemText(i, 2, "#{m['CookieExpirationPeriod']}")
          @elb_policies.setItemJustify(i, 0, FXTableItem::LEFT)
          @elb_policies.setItemJustify(i, 1, FXTableItem::LEFT)
          @elb_policies.setItemJustify(i, 2, FXTableItem::LEFT)
          i = i+1
        end 
      end
      @elb_listeners.clearItems
      @elb_listeners.rowHeaderWidth = 0	
      @elb_listeners.setTableSize(@listener_table.size, 6)
      @elb_listeners.setColumnText(0, "Protocol")
      @elb_listeners.setColumnText(1, "Load Balancer Port")
      @elb_listeners.setColumnText(2, "Instance Port")
      @elb_listeners.setColumnText(3, "InstanceProtocol")
      @elb_listeners.setColumnText(4, "SSLCertificateId")
      @elb_listeners.setColumnText(5, "Policy Names")
      @elb_listeners.setColumnWidth(0,80)
      @elb_listeners.setColumnWidth(1,110)
      @elb_listeners.setColumnWidth(2,80)
      @elb_listeners.setColumnWidth(3,80)
      @elb_listeners.setColumnWidth(4,150)
      @elb_listeners.setColumnWidth(5,150)
      i = 0
      @listener_table.each do |m|
        if m!= nil
          @elb_listeners.setItemText(i, 0, "#{m['Protocol']}")
          @elb_listeners.setItemText(i, 1, "#{m['LoadBalancerPort']}")
          @elb_listeners.setItemText(i, 2, "#{m['InstancePort']}")
          @elb_listeners.setItemText(i, 3, "#{m['InstanceProtocol']}")
          @elb_listeners.setItemText(i, 4, "#{m['SSLCertificateId']}")
          @elb_listeners.setItemText(i, 5, "#{policy_names.first}")
          policy_names.delete_at(0)
          @elb_listeners.setItemJustify(i, 0, FXTableItem::LEFT)
          @elb_listeners.setItemJustify(i, 1, FXTableItem::LEFT)
          @elb_listeners.setItemJustify(i, 2, FXTableItem::LEFT)
          @elb_listeners.setItemJustify(i, 3, FXTableItem::LEFT)
          @elb_listeners.setItemJustify(i, 4, FXTableItem::LEFT)
          @elb_listeners.setItemJustify(i, 5, FXTableItem::LEFT)
          i = i+1
        end 
      end   
    end
  end
  def saved
    @updated
  end
  def updated
    @updated
  end

  def success
    @updated
  end
end
