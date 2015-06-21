require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class ELB_PolicySetDialog < FXDialogBox

  def initialize(owner, load_balancer, listener, policy_table)
    puts "PolicySetDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @lb_name = load_balancer
    @item_name = policy_table
    super(owner, "Set Policy", :opts => DECOR_ALL, :width => 400, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Load Balancer" )
    @elb_name = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    @elb_name.text = @lb_name
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Port Number" )
    port_number = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    port_number.text = listener['LoadBalancerPort'].to_s
    FXLabel.new(frame1, "Policy Name" )
    itemlist = FXList.new(frame1, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem(e['PolicyName'])
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        selected_item = item.text if item.selected?
      end
      @curr_item = selected_item
      puts "PolicySet "+@curr_item
    end
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    update = FXButton.new(frame2, "   &Set   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data|
      set_load_balancer_policies_of_listener(@lb_name, listener['LoadBalancerPort'], @curr_item)
      if @updated
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end

  def set_load_balancer_policies_of_listener(load_balancer_name, load_balancer_port,policy_name)
    begin
      r = @ec2_main.environment.elb.set_load_balancer_policies_of_listener(load_balancer_name, load_balancer_port, [policy_name])
      @updated = true
    rescue
      error_message("Setting Policy for Load Balancer Failed",$!)
    end
  end
  def updated
    @updated
  end
  def saved
    @updated
  end
  def success
    @updated
  end
  def selected
    return @curr_item
  end
end