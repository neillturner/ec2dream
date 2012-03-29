require 'rubygems'
require 'fox16'
require 'fog'
require 'net/http'
require 'resolv'


include Fox

class OPS_ImageDialog < FXDialogBox

  def initialize(owner)
       puts "ImageDialog.initialize"
       @ec2_main = owner
       @curr_img = ""
       @img_cache = {}
       super(owner, "Select Image", :opts => DECOR_ALL, :width => 600, :height => 400)
       page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
       frame2 = FXVerticalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       @imglist = FXList.new(frame2, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       @imglist.setNumVisible(12)
       frame3 = FXMatrix.new(page1, 4, MATRIX_BY_COLUMNS|LAYOUT_FILL)
       FXLabel.new(frame3, "Id" )
       image_id = FXTextField.new(frame3, 10, nil, 0, :opts => TEXTFIELD_READONLY)
       FXLabel.new(frame3, "Progress" )
       image_progress = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)  
       FXLabel.new(frame3, "Name" )
       image_name = FXTextField.new(frame3, 40, nil, 0, :opts => TEXTFIELD_READONLY)
       FXLabel.new(frame3, "Status" )
       image_status = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
       FXLabel.new(frame3, "Created" )
       image_minDisk = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)
       FXLabel.new(frame3, "Min Disk" )
       image_created_at = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)       
       FXLabel.new(frame3, "Updated" )
       image_updated_at = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)    
       FXLabel.new(frame3, "Min Ram" )
       image_minRam = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)     
       FXLabel.new(frame3, "Server" )
       image_server = FXTextField.new(frame3, 25, nil, 0, :opts => TEXTFIELD_READONLY)       
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       frame4 = FXVerticalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       select = FXButton.new(frame4, "   &Select   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
       select.connect(SEL_COMMAND) do |sender, sel, data|
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end 
       @imglist.connect(SEL_COMMAND) do |sender, sel, data|
         selected_item = ""
         @imglist.each do |item|
           selected_item = item.text if item.selected?
         end
         puts "item "+selected_item
         if selected_item != "***Loading***" and selected_item != "***No Images Found***"
            sa = (selected_item).split"("
	    if sa.size>1
	       @curr_name = sa[0]
	       @curr_img = sa[1].chomp(")")
	    else
	       @curr_img =""
	       @curr_name = ""
	    end
            puts "image "+@curr_img
            r = @img_cache[@curr_img]
            if r != nil and r.id != nil 
               image_id.text = r.id
               image_name.text = r.name
               image_created_at.text = r.created_at
               image_updated_at.text = r.updated_at
               image_progress.text = r.progress.to_s
               image_status.text = r.status
               image_minDisk.text = r.minDisk
               image_minRam.text = r.minRam
               image_server.text = r.server
            end   
         end   
       end
       populate_images()
  end
  
  
  def populate_images()
    @imglist.clearItems
    conn = @ec2_main.environment.connection
    if conn != nil
       conn.images.each do |r|
          @imglist.appendItem("#{r.name}  (#{r.id})")
          @img_cache[r.id] = r
       end
    end 
 end
  
   
  def selected
     sa = (@curr_img).split("/")
     sel_image = @curr_img 
     if sa.size>1
        sel_image = sa[1].rstrip
     end 
    return sel_image
  end 
  
  def img_name
    return @curr_name 
  end 
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end


            
