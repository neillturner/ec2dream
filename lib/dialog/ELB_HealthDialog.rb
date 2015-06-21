require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class ELB_HealthDialog < FXDialogBox

  def initialize(owner,load_balancer)
    @ec2_main = owner
    super(owner, "Configure ELB Health Checks - #{load_balancer}", :opts => DECOR_ALL, :width => 750, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Target (protocol:port)" )
    target = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "Protocol is either TCP, HTTP, HTTPS, or SSL. Port is 1 through 65535" )
    FXLabel.new(frame1, "Timeout (secs)" )
    timeout = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Interval (secs)" )
    interval = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "Time between health checks" )
    FXLabel.new(frame1, "Healthy Threshold" )
    healthy_threshold = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "Number of Consecutive health successes before instance healthy" )
    FXLabel.new(frame1, "Unhealthy Threshold" )
    unhealthy_threshold = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_INTEGER)
    FXLabel.new(frame1, "Number of Consecutive health failures  before instance unhealthy" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    update = FXButton.new(frame2, "   &Configure   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data|
      h = {}
      h['Target'] = target.text
      h['Timeout'] = timeout.text.to_i
      h['Interval'] = interval.text.to_i
      h['HealthyThreshold'] = healthy_threshold.text.to_i
      h['UnhealthyThreshold'] = unhealthy_threshold.text.to_i
      begin
        @ec2_main.environment.elb.configure_health_check(load_balancer, h)
        @updated = true
      rescue
        error_message("Configure Health Check failed",$!)
      end
      if @updated
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
    @ec2_main.environment.elb.describe_load_balancers({'LoadBalancerNames' => [load_balancer]}).each do |r|
      target.text = r['HealthCheck']['Target']
      timeout.text = r['HealthCheck']['Timeout'].to_s
      interval.text = r['HealthCheck']['Interval'].to_s
      healthy_threshold.text = r['HealthCheck']['HealthyThreshold'].to_s
      unhealthy_threshold.text = r['HealthCheck']['UnhealthyThreshold'].to_s
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