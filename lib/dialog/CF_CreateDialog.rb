require 'rubygems'
require 'fox16'
require 'common/EC2_Properties'

include Fox

class CF_CreateDialog < FXDialogBox

  def initialize(owner)
    puts " CF_CreateDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Create Cloud Formation", :opts => DECOR_ALL, :width => 600, :height => 200)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Stack Name" )
    stack_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Template File" )
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    template_file = FXTextField.new(frame1a, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    template_file_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    template_file_button.icon = @magnifier
    template_file_button.tipText = "Browse..."
    template_file_button.connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(frame1a, "Select template file")
        dialog.patternList = [
           "Template Files (*.*)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
           template_file.text = dialog.filename
        end
    end
    template_file.text= ENV['EC2DREAM_HOME']+"/stacks/test.stack"
    @script_edit = @ec2_main.makeIcon("script_edit.png")
    @script_edit.create
    template_edit_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    template_edit_button.icon = @script_edit
    template_edit_button.tipText = "Edit Template..."
    template_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
       run = EC2_Run.new
       run.edit(template_file.text)
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Parameters" )
    parameters = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Disable Rollback" )
        disable_rollback = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Timeout in Minutes" )
        timeout_in_minutes = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if stack_name.text == nil or stack_name.text == ""
         error_message("Error","Stack Name not specified")
       else
         create_stack(stack_name.text,template_file.text,parameters.text,disable_rollback.text,timeout_in_minutes.text)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
  end 
  
  def create_stack(stack_name,template_file,parameters,disable_rollback,timeout_in_minutes)
     folder = "cf_templates"
     cf = EC2_Properties.new
     if cf != nil
      begin
        if cf.exists(folder, stack_name)
           error_message("Error","Local Stack Already Exists")
           return        
        end
        properties = {}
        properties['stack_name']=stack_name
        properties['template_file']=template_file
        properties['parameters']=parameters
        if disable_rollback != nil and disable_rollback != ""
           properties['disable_rollback'] = disable_rollback
        end 
        if timeout_in_minutes != nil and timeout_in_minutes != ""
           properties['timeout_in_minutes'] = timeout_in_minutes
        end           
        @saved = cf.save(folder, stack_name, properties)
        if @saved == false
           error_message("Error","Create Stack Failed")
        end   
      rescue
        error_message("Create Stack",$!.to_s)
        return
      end
     end
  end 

  def created
    @saved
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
