require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/ELB_InstanceRegisterDialog'

include Fox

class ELB_InstancesDialog < FXDialogBox

  def initialize(owner, load_balancer)
    puts "ELBInstancesDialog.initialize"
    @ec2_main = owner
    @updated = false
    @set = false
    @lb_name = load_balancer
    @curr_instance = ""
    @curr_row = nil
    @instance_table = Array.new
    super(owner, "Assign Instances", :opts => DECOR_ALL, :width => 700, :height => 310)
    @frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "ELB Name" )
    @elb_name = FXTextField.new(@frame1, 80, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    @elb_name.text = @lb_name
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Instances")
    @elb_instances = FXTable.new(@frame1,:height => 200, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_READONLY  )
    @header1 = @elb_instances.columnHeader
    @header1.connect(SEL_COMMAND) do |sender, sel, which|
      # do nothing
    end
    @elb_instances.connect(SEL_COMMAND) do |sender, sel, which|
      @curr_row = which.row
      @elb_instances.selectRow(@curr_row)
      @curr_instance = @elb_instances.getItemText(@curr_row, 0)
    end
    page1a = FXHorizontalFrame.new(@frame1,LAYOUT_FILL_X, :padding => 0)
    FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    @refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @refresh = @ec2_main.makeIcon("arrow_refresh.png")
    @refresh.create
    @refresh_button.icon = @refresh
    @refresh_button.tipText = "  Refresh Instances  "
    @refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
      load_instances_table(@lb_name)   
    end
    @refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end   	
    @create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @add = @ec2_main.makeIcon("add.png")
    @add.create
    @create_button.icon = @add
    @create_button.tipText = "  Register Instance  "
    @create_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = ELB_InstanceRegisterDialog.new(@ec2_main,@instance_table)
      dialog.execute
      pn = dialog.selected
      if pn != nil and pn != ""
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Register","Confirm Register of Instance "+pn)
        if answer == MBOX_CLICKED_YES	   
          register_instances_with_load_balancer(@lb_name, pn)
        end   
      end                 
    end
    @create_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create
    @delete_button.icon = @delete
    @delete_button.tipText = "  Deregister Instance  "
    @delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @curr_row == nil
        error_message("No Instance selected","No Instance selected to deregister")
      else
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Deregister","Confirm Deregister of Instance "+@curr_instance)
        if answer == MBOX_CLICKED_YES           
          deregister_instances_from_load_balancer(@lb_name, @curr_instance)
        end   
      end 
    end
    @delete_button.connect(SEL_UPDATE) do |sender, sel, data|
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
    load_instances_table(@lb_name)
  end 
  def register_instances_with_load_balancer(load_balancer_name, instance)
    begin 
      r = @ec2_main.environment.elb.register_instances_with_load_balancer([instance],load_balancer_name)
      @updated = true
      load_instances_table(load_balancer_name)            
    rescue
      error_message("Register of Instance Failed",$!)
    end 
  end
  def deregister_instances_from_load_balancer(load_balancer_name, instance)
    begin 
      @ec2_main.environment.elb.deregister_instances_from_load_balancer([instance],load_balancer_name)
      @updated = true
      load_instances_table(load_balancer_name)
    rescue
      error_message("Deregister of Instance Failed",$!)
    end 
  end

  def load_instances_table(load_balancer_name)
    @instance_table.clear
    @elb_instances.clearItems
    data = @ec2_main.environment.elb.describe_load_balancers({'LoadBalancerNames' => [load_balancer_name]})
    if data.size>0 
      r = @ec2_main.environment.elb.describe_instance_health(load_balancer_name, nil)
      @elb_instances.rowHeaderWidth = 0	
      @elb_instances.setTableSize(r.size, 4)
      @elb_instances.setColumnText(0, "Instance Id")
      @elb_instances.setColumnText(1, "Description")
      @elb_instances.setColumnText(2, "State")
      @elb_instances.setColumnText(3, "Reason Code")
      @elb_instances.setColumnWidth(0,180)
      @elb_instances.setColumnWidth(1,140)
      @elb_instances.setColumnWidth(2,80)
      @elb_instances.setColumnWidth(3,80)
      i = 0
      r.each do |m|
        if m!= nil 
          @elb_instances.setItemText(i, 0, "#{m['InstanceId']}")
          @instance_table[i] = m['InstanceId']
          @elb_instances.setItemText(i, 1, "#{m['Description']}")
          @elb_instances.setItemText(i, 2, "#{m['State']}")
          @elb_instances.setItemText(i, 3, "#{m['ReasonCode']}")
          @elb_instances.setItemJustify(i, 0, FXTableItem::LEFT)
          @elb_instances.setItemJustify(i, 1, FXTableItem::LEFT)
          @elb_instances.setItemJustify(i, 2, FXTableItem::LEFT)
          @elb_instances.setItemJustify(i, 3, FXTableItem::LEFT)
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
