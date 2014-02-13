require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_ImageDialog < FXDialogBox

  def initialize(owner,search_type="Owned By Me",search_platform="All Platforms",search_root=nil,search_search="")
       puts "ImageDialog.initialize"
       @ec2_main = owner
       @curr_img = ""
       @curr_name = ""
       @viewing =  @ec2_main.environment.images.viewing
       @platform =  @ec2_main.environment.images.platform
       @device =  @ec2_main.environment.images.device
	   search_root =  @ec2_main.environment.images.search_root if search_root == nil 
       image_type = search_type
       image_platform = search_platform
       image_root_device = search_root
       image_seach = search_search
       super(owner, "Select Image", :opts => DECOR_ALL, :width => 800, :height => 450)
       page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
       frame1 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       FXLabel.new(frame1, "Viewing:" )
       type = FXComboBox.new(frame1, 55,
  	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       type.numVisible = 14
       @viewing.each do |e|
          type.appendItem(e)
       end         
       type.connect(SEL_COMMAND) do |sender, sel, data|
          image_type = data
	  sa = (image_type).split"("
	  if sa.size>1
	     @curr_img = sa[1].chomp(")")
	     self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
	  end          
       end
       i = @viewing.index(search_type)
       if i != nil
          type.setCurrentItem(i)
       end       
       platform = FXComboBox.new(frame1, 13,
  	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       platform.numVisible = 3
       @platform.each do |e|
          platform.appendItem(e)
       end 
       platform.connect(SEL_COMMAND) do |sender, sel, data|
          image_platform = data
       end
       i = @platform.index(search_platform)
       if i != nil
          platform.setCurrentItem(i)
       end          
       root_device = FXComboBox.new(frame1, 12, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       root_device.numVisible = 2
       @device.each do |e|
          root_device.appendItem(e)
       end
       root_device.connect(SEL_COMMAND) do |sender, sel, data|
          image_root_device = data
       end
       i = @device.index(search_platform)
       if i != nil
          root_device.setCurrentItem(i)
       end        
       search = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
       frame1a = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       FXLabel.new(frame1a, "   " )
       search_button = FXButton.new(frame1a, "   &Search   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
       search_button.connect(SEL_COMMAND) do |sender, sel, data|
          if image_type != "Owned By Me" and image_type != "Amazon Images" and image_type != "Public Images" and image_type != "Private Images" and image_type != "EBS Images"and image_type != "Instance-Store Images"
             search.text = ""
          end
          populate_images(image_type, image_platform, image_root_device, search.text)
       end
       FXLabel.new(frame1a, "   " )
       frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       @imglist = FXList.new(frame2, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       @imglist.setNumVisible(20)
       @imglist.connect(SEL_COMMAND) do |sender, sel, data|
         selected_item = ""
         @imglist.each do |item|
           selected_item = item.text if item.selected?
         end
         puts "item "+selected_item
         if selected_item != "***Loading***" and selected_item != "***No Images Found***"
            puts image_type 
            sa = (selected_item).split"("
	    if sa.size>1
	       @curr_img = sa[1].chomp(")")
	       @curr_name = sa[0].rstrip
	    else
	       @curr_img =""
	       @curr_name =""
	    end
            puts "image "+@curr_img
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end   
       end
       populate_images(image_type, image_platform, image_root_device, search.text)
  end
  
  
  def populate_images(type, platform, root, search)
       	 image_locs = @ec2_main.environment.images.get_images(type, platform, root, search, {})
    	 if image_locs.empty?
    	     image_error_message = @ec2_main.environment.images.error_message
    	     if image_error_message != nil and image_error_message != ""
    	         error_message("Error",image_error_message)    
    	      end
  	 end
  	 image_locs = image_locs.sort_by {|r| r['imageLocation'].downcase}
         @imglist.clearItems
         if image_locs != nil 
            image_locs.each do |r|
               @imglist.appendItem("#{r['imageLocation']}  (#{r['imageId']})")
            end
            if image_locs.size == 0
               status = @ec2_main.imageCache.status
               if status == "loading"
                  @imglist.appendItem("***Loading***")
               else   
                  @imglist.appendItem("***No Images Found***")
               end   
            end
         else
            status = @ec2_main.imageCache.status
            if status == "loading"
               @imglist.appendItem("***Loading***")
            else   
               @imglist.appendItem("***No Images Found***")
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
  
 def name
    return @curr_name
  end  

end


            
