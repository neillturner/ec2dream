  require 'fox16'
  
  def error_message(title, message)
           #puts "Message Class #{message.class}"
           if message.class.to_s.start_with?("Excon::Errors::")
            message = message.response[:body].to_s
           elsif message.class.to_s.end_with?("::ServiceError")
            message = message.response_data.to_s
           elsif message.class.to_s.end_with?("::BadRequest")
            message = message.response_data.to_s 
           elsif message.class.to_s.end_with?("::InternalServerError")
            message = message.response_data.to_s             
         end 
         puts "ERROR: #{title} #{message}"
         FXMessageBox.warning($ec2_main,MBOX_OK,title,"#{message}")
  end
  
