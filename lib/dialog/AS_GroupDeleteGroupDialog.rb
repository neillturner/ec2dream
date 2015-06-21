
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_GroupDeleteGroupDialog < FXDialogBox

  def initialize(owner, curr_item)
    puts "AS_GroupDeleteGroupDialog.initialize"
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    @force = false
    super(owner, "Confirm Delete of AutoScaling Group", :opts => DECOR_ALL, :width => 400, :height => 140)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Auto Scaling Group" )
    as_group_name = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_READONLY)
    as_group_name.text = @delete_item
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    force_check = FXCheckButton.new(frame1,"Force Delete", :opts => ICON_BEFORE_TEXT|JUSTIFY_CENTER_X)
    force_check.connect(SEL_COMMAND) do
      if @force == false
        @force = true
      else
        @force = false
      end
    end
        FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame2, "" )
    delete = FXButton.new(frame2, "   &Delete   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X|BUTTON_INITIAL)
    FXLabel.new(frame1, "" )
    delete.connect(SEL_COMMAND) do |sender, sel, data|
      begin
        options = {}
        if @force
          options['ForceDelete'] = true
        end
        @ec2_main.environment.auto_scaling_groups.delete_auto_scaling_group(@delete_item,options)
        @deleted = true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      rescue
        error_message("Auto Scaling Group Deletion failed",$!)
      end
    end
  end
  def deleted
    @deleted
  end
  def success
    @deleted
  end
end