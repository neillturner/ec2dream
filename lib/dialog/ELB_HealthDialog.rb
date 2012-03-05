
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class ELB_HeathDialog < FXDialogBox

  def initialize(owner,load_balancer)
    @ec2_main = owner
    super(owner, "ELB Health - #{load_balancer}", :opts => DECOR_ALL, :width => 500, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Target" )
    target = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Timeout" )
    timeout = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Interval" )
    interval = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Healthy Threshold" )
    healthy_threshold = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Unhealthy Threshold" )
    unhealthy_threshold = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    update = FXButton.new(frame2, "   &Update   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data|
       elb = @ec2_main.environment.elb_connection
       if elb != nil
          h = {}
          h[:target] = target.text
          h[:timeout] = timeout.text.to_i
          h[:interval] = interval.text.to_i
          h[:healthy_threshold] = healthy_threshold.text.to_i
          h[:unhealthy_threshold] = unhealthy_threshold.text.to_i
          puts h
	  begin 
             elb.configure_health_check(load_balancer, h)
          rescue
             error_message("Configure Health Check failed",$!.to_s)
             return
          end             
          @updated = true
       end
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    elb = @ec2_main.environment.elb_connection
    if elb != nil
       elb.describe_load_balancers(load_balancer).each do |r|
          target.text = r[:health_check][:target]
	  timeout.text = r[:health_check][:timeout].to_s
	  interval.text = r[:health_check][:interval].to_s
	  healthy_threshold.text = r[:health_check][:healthy_threshold].to_s
          unhealthy_threshold.text = r[:health_check][:unhealthy_threshold].to_s
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