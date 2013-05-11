require 'rubygems'
require 'fox16'
include Fox

class CF_ValidateDialog < FXDialogBox

  def initialize(owner,item,template_file)
     puts "CF_ValidateDialog.initialize"
     @ec2_main = owner
     doc = File.open(template_file, 'rb') { |file| file.read }
     options = {}
     options['TemplateBody'] = doc
     cf = @ec2_main.environment.cf_connection
     if cf != nil
	begin
           response = cf.validate_template(options)
           if response.status == 200
               FXMessageBox.warning(@ec2_main,MBOX_OK,"Template validated successfully","Template validated successfully.")
           else
               FXMessageBox.warning(@ec2_main,MBOX_OK,"Template Validation Error","#{response.body}")
           end    
        rescue 
	   error_message("Template Validation Error",$!)
        end        
     end   
  end
  
  def success
    @false
  end
  
end  