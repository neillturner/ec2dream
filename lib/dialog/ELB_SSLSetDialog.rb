
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class ELB_SSLSetDialog < FXDialogBox

  def initialize(owner, load_balancer, listener)
    @ec2_main = owner
    @lb_name = load_balancer
    @ssl_cert = listener['SSLCertificateId']
    @updated = false
    super(owner, "Set SSL Certificate - #{@lb_name}", :opts => DECOR_ALL, :width => 400, :height => 100)
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
    FXLabel.new(frame1, "Port Number" )
    ssl_certificate_id = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    if listener['SSLCertificateId'] != nil
      ssl_certificate_id.text = @ssl_cert
    end
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    update = FXButton.new(frame2, "   &Set   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data|
      set_load_balancer_listener_ssl_certificate(@lb_name, listener['LoadBalancerPort'], ssl_certificate_id.text)
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end

  def set_load_balancer_listener_ssl_certificate(lb_name, load_balancer_port, ssl_certificate_id)
    begin
      r = @ec2_main.environment.elb.set_load_balancer_policies_of_listener(load_balancer_name, load_balancer_port, ssl_certificate_id)
      @ssl_cert = ssl_certificate_id
      @updated = true
    rescue
      error_message("Setting SSL Certificate Id for Load Balancer Failed",$!)
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
    @ssl_cert
  end
end