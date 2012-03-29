
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_ImageRegisterDialog < FXDialogBox

  def initialize(owner)
    puts "ImageRegisterDialog.initialize"
    @ec2_main = owner
    @created = false    
    super(owner, "Register Image", :opts => DECOR_ALL, :width => 600, :height => 120)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "AMI Manifest Path:" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "http://s3.amazonaws.com:80/" )
    path = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Register   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if path.text == nil or path.text == ""
         error_message("Error","AMI Manifest Path not specified")
       else
         register_image(path.text)
         if @created == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
    today = DateTime.now
    d = today.strftime("%Y%m%d")
    path.text = "<bucket>/<server>-#{d}/image.manifest.xml"
  end 
  
  def register_image(p)
     ec2 = @ec2_main.environment.connection
     sa = (p).split("/")
     sel_image = p 
     if sa.size>1
        sel_image = sa[1].rstrip
     end  
     if ec2 != nil
      begin 
       r = ec2.register_image(sel_image)
       @created = true
       FXMessageBox.information(@ec2_main,MBOX_OK,"Image Registered","Image \""+r+"\" sucessfully registered")
      rescue
        error_message("Register Image Failed",$!.to_s)
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
