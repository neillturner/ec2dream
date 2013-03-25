require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class ELB_PolicyCreateDialog < FXDialogBox

  def initialize(owner,item)
    puts "ELBPolicyCreateDialog.initialize"
    @ec2_main = owner
    @lb_name = item
    @created = false
    @result = {}
    super(owner, "Add Policy for #{@lb_name}" , :opts => DECOR_ALL, :width => 400, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Policy Name")
    policy_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "App Cookie Name")
    cookie_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "LB Cookie Expiration Period (Secs)")
    cookie_expiration_period = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if cookie_name.text != nil and cookie_name.text != ""  and cookie_expiration_period.text != nil and cookie_expiration_period.text != "" 
          error_message("Error","Specify either App Cookie Name or LB Cookie Expiration Period")
       elsif cookie_name.text != nil and cookie_name.text != "" 
          create_app_policy(@lb_name, policy_name.text, cookie_name.text)
          if @created == true
             @result['PolicyName'] = policy_name.text
             @result['CookieName'] = cookie_name.text
             self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
          end
       else 
          if cookie_expiration_period.text != nil and cookie_expiration_period.text != "" 
             create_lb_policy(@lb_name, policy_name.text, cookie_expiration_period.text)
             if @created == true
                @result['PolicyName'] = policy_name.text
                @result['CookieExpirationPeriod'] = cookie_expiration_period.text
                self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
             end   
          end
       end
    end
  end
  
  def create_app_policy(load_balancer_name, policy_name, cookie_name)
      begin 
       r = @ec2_main.environment.elb.create_app_cookie_stickiness_policy(load_balancer_name, policy_name, cookie_name)
       @created = true
      rescue
        error_message("Create App Cookie Stickiness Policy Failed",$!)
      end 
  end
  
  def create_lb_policy(load_balancer_name, policy_name, cookie_expiration_period)
        begin 
         r = @ec2_main.environment.elb.create_lb_cookie_stickiness_policy(load_balancer_name, policy_name, cookie_expiration_period.to_i)
         @created = true
        rescue
          error_message("Create LB Cookie Stickiness Policy Failed",$!)
        end 
  end

  def saved
     @created
  end
  
  def created
    @created
  end
  
  def success
     @created
  end
  
  def result
    @result
  end   

end
