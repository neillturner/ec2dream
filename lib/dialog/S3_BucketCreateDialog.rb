
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class S3_BucketCreateDialog < FXDialogBox

  def initialize(owner)
    puts "S3Bucket_CreateDialog.initialize"
    @ec2_main = owner
    @curr_s3_bucket = ""
    @created = false
    super(owner, "Create S3 Bucket", :opts => DECOR_ALL, :width => 450, :height => 75)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    FXLabel.new(frame1, "Bucket Name" )
    new_s3_bucket = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    ok = FXButton.new(frame1, "   &OK   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    ok.connect(SEL_COMMAND) do |sender, sel, data|
      @s3_bucket = new_s3_bucket.text
      puts @s3_bucket
      if @s3_bucket == nil or @s3_bucket == ""
          error_message("Error","Bucket not specified")
       else
          if @s3_bucket.match(/[^0-9A-Za-z-]/)
             error_message("Error","Bucket Name must contain A-Z, 0-9 or - characters")    
          else
             begin
              @created = create_s3_bucket(@s3_bucket)
              if @created == true
                  @curr_s3_bucket = @s3_bucket
	          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
              end
             rescue
              error_message("Invalid Bucket Name",$!.to_s)
             end 
          end   
      end  
    end
  end 
  
 
  def create_s3_bucket(b)
     s3 = @ec2_main.environment.s3_connection
     if s3 != nil
         s3_bucket = RightAws::S3::Bucket.create(s3, b)
         if s3_bucket != nil 
          error_message("Error","Bucket Already exists")
          return false
         else 
          s3_bucket = RightAws::S3::Bucket.create(s3, b, true)
          return true
         end
     end
  end 
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
  def created
       @created
  end
  
  def selected
      return @curr_s3_bucket
  end
 
end
