require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_KeypairCreateDialog < FXDialogBox

  def initialize(owner)
    puts "KeypairCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    super(owner, "Create Keypair", :opts => DECOR_ALL, :width => 700, :height => 250)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Key Pair Name" )
    name = FXTextField.new(frame1, 90, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "Key Pair Value" )
    @text_area = FXText.new(frame1, :opts => TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY)
    @text_area.setVisibleRows(10)
    @text_area.setText("")
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if name.text == nil or name.text == ""
         error_message("Error","Key Pair Name not specified")
       else
         create_keypair(name.text)
       end  
    end
    cancel = FXButton.new(frame2, "   &Cancel   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
  end 
  
  def create_keypair(name)
      begin 
       r = @ec2_main.environment.keypairs.create(name)
       if r[:aws_material] != nil
          @text_area.setText(r[:aws_material])
       else
          @text_area.setText("#{r['private_key']}")
       end
       @created = true
      rescue
        error_message("Create Key Pair Failed",$!)
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

end
