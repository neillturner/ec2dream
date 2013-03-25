
require 'rubygems'
require 'fox16'
require 'common/EC2_Properties'
require 'common/error_message'
require 'common/edit'

include Fox

class CF_EditDialog < FXDialogBox

  def initialize(owner, curr_item=nil)
    puts "CF_EditDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Create or Update Stack", :opts => DECOR_ALL, :width => 600, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
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
    @script_edit = @ec2_main.makeIcon("script_edit.png")
    @script_edit.create
    template_edit_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    template_edit_button.icon = @script_edit
    template_edit_button.tipText = "Edit Template..."
    template_edit_button.connect(SEL_COMMAND) do |sender, sel, data|
       edit(template_file.text)
    end
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Parameters" )
    parameters = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
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
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    save = FXButton.new(frame2, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    save.connect(SEL_COMMAND) do |sender, sel, data|
       if stack_name.text == nil or stack_name.text == ""
         error_message("Error","Stack Name not specified")
       else
         save_stack(stack_name.text,template_file.text,parameters.text,disable_rollback.text,timeout_in_minutes.text)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
    create = FXButton.new(frame2, "   &Create Stack   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if stack_name.text == nil or stack_name.text == ""
         error_message("Error","Stack Name not specified")
       else
         save_stack(stack_name.text,template_file.text,parameters.text,disable_rollback.text,timeout_in_minutes.text)
         if @saved == true
            answer = FXMessageBox.question(@ec2_main,MBOX_YES_NO,"Confirm Stack Create","Confirm Create of Stack #{stack_name}")
            if answer == MBOX_CLICKED_YES         
               doc = File.open(template_file.text, 'rb') { |file| file.read }
               options = {}
               options['TemplateBody'] = doc
               if parameters.text != nil and parameters.text != ""
                  begin
                     h = {}
		     (parameters.text).split(",").each do |x| 
		        k,v = x.split('=')
		        h[k] = v
                     end
                     options['Parameters'] = h
                  rescue
                     puts "ERROR: bad parameters on Create stack ignored"
                  end
               end 
               if disable_rollback.text != nil and disable_rollback.text != ""
                 options['DisableRollback'] =  true if (disable_rollback.text).downcase == "true"
                 options['DisableRollback'] =  false if (disable_rollback.text).downcase == "false"
               end
	       if timeout_in_minutes.text != nil and timeout_in_minutes.text != ""
                 options['TimeoutInMinutes'] = (timeout_in_minutes.text).to_i
               end               
               cf = @ec2_main.environment.cf_connection
               if cf != nil
	          begin
	             puts "Create Stack #{stack_name.text} parameters #{options['Parameters']} disable_rollback #{options['DisableRollback']} timeout_in_minutes #{options['TimeoutInMinutes']}"
                     response = cf.create_stack(stack_name.text, options)
                     @saved = true
                     self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
                  rescue
                     error_message("Stack Update failed",$!)
	          end   
               end   
            end
         end
       end           
    end
    update = FXButton.new(frame2, "   &Update Stack   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    update.connect(SEL_COMMAND) do |sender, sel, data| 
       if stack_name.text == nil or stack_name.text == ""
         error_message("Error","Stack Name not specified")
       else
         save_stack(stack_name.text,template_file.text,parameters.text,disable_rollback.text,timeout_in_minutes.text)
         if @saved == true    
	    answer = FXMessageBox.question(@ec2_main,MBOX_YES_NO,"Confirm Stack Update","Confirm Update of Stack #{stack_name}")
            if answer == MBOX_CLICKED_YES
	       doc = File.open(template_file.text, 'rb') { |file| file.read }
               options = {}
               options['TemplateBody'] = doc
               if parameters.text != nil and parameters.text != ""
                  begin
                     h = {}
		     (parameters.text).split(",").each do |x| 
		        k,v = x.split('=')
		        h[k] = v
                     end
                     options['Parameters'] = h
                  rescue
                     puts "ERROR: bad parameters on Create stack ignored"
                  end
               end
               if disable_rollback.text != nil and disable_rollback.text != ""
                 options['DisableRollback'] =  true if (disable_rollback.text).downcase == "true"
                 options['DisableRollback'] =  false if (disable_rollback.text).downcase == "false"
               end
	       if timeout_in_minutes.text != nil and timeout_in_minutes.text != ""
                 options['TimeoutInMinutes'] = (timeout_in_minutes.text).to_i
               end                         
               cf = @ec2_main.environment.cf_connection
               if cf != nil
	          begin
	             puts "Update Stack #{stack_name.text} parameters #{options['Parameters']} disable_rollback #{options['DisableRollback']} timeout_in_minutes #{options['TimeoutInMinutes']}"
                     response = cf.update_stack(stack_name.text, options)
                     @saved = true
                     self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
                  rescue
                     error_message("Stack Creation failed",$!)
	          end   
               end            
            end
          end  
        end        
     end    
    
    if curr_item != nil and curr_item != ""
       r = get_stack(curr_item)
       if r['stack_name'] != nil and r['stack_name'] != ""
          stack_name.text = r['stack_name']
          template_file.text = r['template_file']
          parameters.text = r['parameters']
          if r['disable_rollback'] != nil and r['disable_rollback'] != ""
             disable_rollback.text = r['disable_rollback']
          else
             disable_rollback.text = ""
          end 
          if r['timeout_in_minutes'] != nil and r['timeout_in_minutes'] != ""
             timeout_in_minutes.text = r['timeout_in_minutes']
          else
             timeout_in_minutes.text = ""
          end   
       end   
    end
  end 
  
  def get_stack(stack_name)
       folder = "cf_templates"
       properties = {}
       loc = EC2_Properties.new
       if loc != nil
          properties = loc.get(folder, stack_name)
       end
       return properties
  end 
  
  def save_stack(stack_name,template_file,parameters,disable_rollback,timeout_in_minutes)
     folder = "cf_templates"
     loc = EC2_Properties.new
     if loc != nil
      begin 
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
        @saved = loc.save(folder, stack_name, properties)
        if @saved == false
           error_message("Update Stack Failed","Update Stack Failed")
           return
        end   
      rescue
        error_message("Update Stack Failed",$!)
        return
      end
     end
  end 

  def saved
    @saved
  end
  
  def success
     @saved
  end

end
