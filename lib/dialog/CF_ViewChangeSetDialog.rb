require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class CF_ViewChangeSetDialog < FXDialogBox

  def initialize(owner, stack_name, change_set_name)
    #puts "ViewChangeSetDialog.initialize #{stack_name} #{change_set_name}"
    @ec2_main = owner
    changes = ""
    cf = @ec2_main.environment.cf_connection
    if cf != nil
      begin
        puts "Describe change set change_set_name #{change_set_name} stack_name #{stack_name} "
        response = cf.describe_change_set(change_set_name,{'StackName' => stack_name})
        puts "response #{response.body['Changes']}"
        changes = "#{response.body['Changes']}"
        changes = changes.tr(",","\n")
        puts "changes #{changes}"
      rescue
      end
    end
    super(owner, "ChangeSet - "+change_set_name, :opts => DECOR_ALL, :width => 700, :height => 375)
    frame1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    @text_area = FXText.new(frame1, :opts => TEXT_WORDWRAP|LAYOUT_FILL)
    @text_area.text = changes
    cancel = FXButton.new(frame1, "   &Cancel   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end


end
