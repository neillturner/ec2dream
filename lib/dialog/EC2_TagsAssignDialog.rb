require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'common/error_message'

include Fox

class EC2_TagsAssignDialog < FXDialogBox

  def initialize(owner, resource)
    puts "TagsAssignDialog.initialize"
    @ec2_main = owner
    sa = (resource).split("/")
    @resource_id = resource 
    if sa.size>1
	@resource_id = sa[1].rstrip
    end
    @nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
    if @nickname_tag == nil
       @nickname_tag = ""
    end  
    resource_tags = get_tags(@resource_id)
    @tags = {}
    @saved = false
    @deleted = false
    @accept= @ec2_main.makeIcon("accept.png")
    @accept.create
    @kill= @ec2_main.makeIcon("kill.png")
    @kill.create
    super(owner, "Assign Tags for #{@resource_id}", :opts => DECOR_ALL, :width => 500, :height => 350)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 4, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Value",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "")
    FXLabel.new(frame1, "")
    @tags['key1'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value1'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save1_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save1_button'].icon = @accept
    @tags['save1_button'].tipText = "Save Tag"
    @tags['save1_button'].connect(SEL_COMMAND) do
       if @tags['key1'].text == @nickname_tag
          @tags['value1'].text = @tags['value1'].text.gsub('/', '')
       end
       save_tag(@resource_id,@tags['key1'].text,@tags['value1'].text)
     end
    @tags['delete1_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete1_button'].icon = @kill
    @tags['delete1_button'].tipText = "Delete Tag"
    @tags['delete1_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key1'].text,@tags['value1'].text)
        if @deleted 
         @tags['key1'].text=""
         @tags['value1'].text=""
        end 
     end

    @tags['key2'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value2'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save2_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save2_button'].icon = @accept
    @tags['save2_button'].tipText = "Save Tag"
    @tags['save2_button'].connect(SEL_COMMAND) do
       if @tags['key2'].text == @nickname_tag
          @tags['value2'].text = @tags['value2'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key2'].text,@tags['value2'].text)
     end
    @tags['delete2_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete2_button'].icon = @kill
    @tags['delete2_button'].tipText = "Delete Tag"
    @tags['delete2_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key2'].text,@tags['value2'].text)
        if @deleted 
         @tags['key2'].text=""
         @tags['value2'].text=""
        end        
     end

    @tags['key3'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value3'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save3_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save3_button'].icon = @accept
    @tags['save3_button'].tipText = "Save Tag"
    @tags['save3_button'].connect(SEL_COMMAND) do
       if @tags['key3'].text == @nickname_tag
          @tags['value3'].text = @tags['value3'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key3'].text,@tags['value3'].text)
     end
    @tags['delete3_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete3_button'].icon = @kill
    @tags['delete3_button'].tipText = "Delete Tag"
    @tags['delete3_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key3'].text,@tags['value3'].text)
        if @deleted 
         @tags['key3'].text=""
         @tags['value3'].text=""
        end        
     end

    @tags['key4'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value4'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save4_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save4_button'].icon = @accept
    @tags['save4_button'].tipText = "Save Tag"
    @tags['save4_button'].connect(SEL_COMMAND) do
       if @tags['key4'].text == @nickname_tag
          @tags['value4'].text = @tags['value4'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key4'].text,@tags['value4'].text)
     end
    @tags['delete4_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete4_button'].icon = @kill
    @tags['delete4_button'].tipText = "Delete Tag"
    @tags['delete4_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key4'].text,@tags['value4'].text)
        if @deleted 
         @tags['key4'].text=""
         @tags['value4'].text=""
        end        
     end

    @tags['key5'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value5'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save5_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save5_button'].icon = @accept
    @tags['save5_button'].tipText = "Save Tag"
    @tags['save5_button'].connect(SEL_COMMAND) do
       if @tags['key5'].text == @nickname_tag
          @tags['value5'].text = @tags['value5'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key5'].text,@tags['value5'].text)
     end
    @tags['delete5_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete5_button'].icon = @kill
    @tags['delete5_button'].tipText = "Delete Tag"
    @tags['delete5_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key5'].text,@tags['value5'].text)
        if @deleted 
         @tags['key5'].text=""
         @tags['value5'].text=""
        end        
     end

    @tags['key6'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value6'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save6_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save6_button'].icon = @accept
    @tags['save6_button'].tipText = "Save Tag"
    @tags['save6_button'].connect(SEL_COMMAND) do
       if @tags['key6'].text == @nickname_tag
          @tags['value6'].text = @tags['value6'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key6'].text,@tags['value6'].text)
     end
    @tags['delete6_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete6_button'].icon = @kill
    @tags['delete6_button'].tipText = "Delete Tag"
    @tags['delete6_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key6'].text,@tags['value6'].text)
        if @deleted 
         @tags['key6'].text=""
         @tags['value6'].text=""
        end        
     end

    @tags['key7'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value7'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save7_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save7_button'].icon = @accept
    @tags['save7_button'].tipText = "Save Tag"
    @tags['save7_button'].connect(SEL_COMMAND) do
       if @tags['key7'].text == @nickname_tag
          @tags['value7'].text = @tags['value7'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key7'].text,@tags['value7'].text)
     end
    @tags['delete7_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete7_button'].icon = @kill
    @tags['delete7_button'].tipText = "Delete Tag"
    @tags['delete7_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key7'].text,@tags['value7'].text)
        if @deleted 
         @tags['key7'].text=""
         @tags['value7'].text=""
        end        
     end

    @tags['key8'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value8'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save8_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save8_button'].icon = @accept
    @tags['save8_button'].tipText = "Save Tag"
    @tags['save8_button'].connect(SEL_COMMAND) do
       if @tags['key8'].text == @nickname_tag
          @tags['value8'].text = @tags['value8'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key8'].text,@tags['value8'].text)
     end
    @tags['delete8_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete8_button'].icon = @kill
    @tags['delete8_button'].tipText = "Delete Tag"
    @tags['delete8_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key8'].text,@tags['value8'].text)
        if @deleted 
         @tags['key8'].text=""
         @tags['value8'].text=""
        end        
     end

    @tags['key9'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value9'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save9_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save9_button'].icon = @accept
    @tags['save9_button'].tipText = "Save Tag"
    @tags['save9_button'].connect(SEL_COMMAND) do
       if @tags['key9'].text == @nickname_tag
          @tags['value9'].text = @tags['value9'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key9'].text,@tags['value9'].text)
     end
    @tags['delete9_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete9_button'].icon = @kill
    @tags['delete9_button'].tipText = "Delete Tag"
    @tags['delete9_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key9'].text,@tags['value9'].text)
        if @deleted 
         @tags['key9'].text=""
         @tags['value9'].text=""
        end        
     end

    @tags['key10'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value10'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['save10_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save10_button'].icon = @accept
    @tags['save10_button'].tipText = "Save Tag"
    @tags['save10_button'].connect(SEL_COMMAND) do
       if @tags['key10'].text == @nickname_tag
          @tags['value10'].text = @tags['value10'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key10'].text,@tags['value10'].text)
     end
    @tags['delete10_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['delete10_button'].icon = @kill
    @tags['delete10_button'].tipText = "Delete Tag"
    @tags['delete10_button'].connect(SEL_COMMAND) do
        delete_tag(@resource_id,@tags['key10'].text,@tags['value10'].text)
        if @deleted 
         @tags['key10'].text=""
         @tags['value10'].text=""
        end        
    end
   if resource_tags != nil
    i=0
    curr_tags = resource_tags
    puts "curr_tags #{curr_tags}"
    if curr_tags != nil 
       curr_tags.each_pair do |k,v|
          i=i+1
          @tags["key#{i}"].text=k
          @tags["value#{i}"].text=v
       end   
    end
   end 
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    return_button = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    return_button.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 
  
  def get_tags(resource_id)
          data = @ec2_main.environment.tags.all(resource_id)
          ta = {}
    	  if data != nil
    	     data.each do |aws_tag|
    	        ta[aws_tag['key']] = aws_tag['value']
    	     end
    	  end
    	  ta
  end
  
  def save_tag(resource_id, key, value)
    if key != nil and key != ""
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
      begin 
       r = ec2.create_tags(resource_id, {key => value})
       @saved = true
      rescue
        error_message("Create Tags Failed",$!)
      end 
     end
    end 
  end 
  
  def delete_tag(resource_id, key, value)
    @deleted = false
    if key != nil and value != "" 
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
      begin 
       r = ec2.delete_tags(resource_id,  {key => value})
       @deleted = true
       @saved = true
      rescue
        error_message("Delete Tags Failed",$!)
      end 
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
