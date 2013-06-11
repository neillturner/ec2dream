require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'common/error_message'

include Fox

class AS_TagsAssignDialog < FXDialogBox

  def initialize(owner, resource, resource_type="auto-scaling-group",alt_resource=nil)
    puts "TagsAssignDialog.initialize"
    @ec2_main = owner
    resource = alt_resource if alt_resource != nil 
    @resource_id = resource 
    @nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
    if @nickname_tag == nil
       @nickname_tag = ""
    end 
    @prop = []
    resource_tags = get_tags(@resource_id,resource_type)
    @tags = {}
    @saved = false
    @deleted = false
    @accept= @ec2_main.makeIcon("accept.png")
    @accept.create
    @kill= @ec2_main.makeIcon("kill.png")
    @kill.create
    super(owner, "Assign Tags for #{@resource_id}", :opts => DECOR_ALL, :width => 550, :height => 350)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 5, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Value",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Propagate",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "",:opts => LAYOUT_RIGHT)
    FXLabel.new(frame1, "",:opts => LAYOUT_LEFT)
    @tags['key1'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value1'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['prop1'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop1'].numVisible = 2      
    @tags['prop1'].appendItem("true")	
    @tags['prop1'].appendItem("false")
    @tags['prop1'].setCurrentItem(1)		
    @tags['save1_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save1_button'].icon = @accept
    @tags['save1_button'].tipText = "Save Tag"
    @tags['save1_button'].connect(SEL_COMMAND) do
       if @tags['key1'].text == @nickname_tag
          @tags['value1'].text = @tags['value1'].text.gsub('/', '')
       end
       save_tag(@resource_id,@tags['key1'].text,@tags['value1'].text,@tags['prop1'])
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
    @tags['prop2'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop2'].numVisible = 2      
    @tags['prop2'].appendItem("true")	
    @tags['prop2'].appendItem("false")
    @tags['prop2'].setCurrentItem(1)    
    @tags['save2_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save2_button'].icon = @accept
    @tags['save2_button'].tipText = "Save Tag"
    @tags['save2_button'].connect(SEL_COMMAND) do
       if @tags['key2'].text == @nickname_tag
          @tags['value2'].text = @tags['value2'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key2'].text,@tags['value2'].text,@tags['prop2'])
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
    @tags['prop3'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop3'].numVisible = 2      
    @tags['prop3'].appendItem("true")	
    @tags['prop3'].appendItem("false")
    @tags['prop3'].setCurrentItem(1)        
    @tags['save3_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save3_button'].icon = @accept
    @tags['save3_button'].tipText = "Save Tag"
    @tags['save3_button'].connect(SEL_COMMAND) do
       if @tags['key3'].text == @nickname_tag
          @tags['value3'].text = @tags['value3'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key3'].text,@tags['value3'].text,@tags['prop3'])
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
    @tags['prop4'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop4'].numVisible = 2      
    @tags['prop4'].appendItem("true")	
    @tags['prop4'].appendItem("false")
    @tags['prop4'].setCurrentItem(1)        
    @tags['save4_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save4_button'].icon = @accept
    @tags['save4_button'].tipText = "Save Tag"
    @tags['save4_button'].connect(SEL_COMMAND) do
       if @tags['key4'].text == @nickname_tag
          @tags['value4'].text = @tags['value4'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key4'].text,@tags['value4'].text,@tags['prop4'])
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
    @tags['prop5'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop5'].numVisible = 2      
    @tags['prop5'].appendItem("true")	
    @tags['prop5'].appendItem("false")
    @tags['prop5'].setCurrentItem(1)        
    @tags['save5_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save5_button'].icon = @accept
    @tags['save5_button'].tipText = "Save Tag"
    @tags['save5_button'].connect(SEL_COMMAND) do
       if @tags['key5'].text == @nickname_tag
          @tags['value5'].text = @tags['value5'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key5'].text,@tags['value5'].text,@tags['prop5'])
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
    @tags['prop6'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop6'].numVisible = 2      
    @tags['prop6'].appendItem("true")	
    @tags['prop6'].appendItem("false")
    @tags['prop6'].setCurrentItem(1)        
    @tags['save6_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save6_button'].icon = @accept
    @tags['save6_button'].tipText = "Save Tag"
    @tags['save6_button'].connect(SEL_COMMAND) do
       if @tags['key6'].text == @nickname_tag
          @tags['value6'].text = @tags['value6'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key6'].text,@tags['value6'].text,@tags['prop6'])
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
    @tags['prop7'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop7'].numVisible = 2      
    @tags['prop7'].appendItem("true")	
    @tags['prop7'].appendItem("false")
    @tags['prop7'].setCurrentItem(1)        
    @tags['save7_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save7_button'].icon = @accept
    @tags['save7_button'].tipText = "Save Tag"
    @tags['save7_button'].connect(SEL_COMMAND) do
       if @tags['key7'].text == @nickname_tag
          @tags['value7'].text = @tags['value7'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key7'].text,@tags['value7'].text,@tags['prop7'])
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
    @tags['prop8'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop8'].numVisible = 2      
    @tags['prop8'].appendItem("true")	
    @tags['prop8'].appendItem("false")
    @tags['prop8'].setCurrentItem(1)        
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
        delete_tag(@resource_id,@tags['key8'].text,@tags['value8'].text,@tags['prop8'])
        if @deleted 
         @tags['key8'].text=""
         @tags['value8'].text=""
        end        
     end

    @tags['key9'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value9'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['prop9'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop9'].numVisible = 2      
    @tags['prop9'].appendItem("true")	
    @tags['prop9'].appendItem("false")
    @tags['prop9'].setCurrentItem(1)        
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
        delete_tag(@resource_id,@tags['key9'].text,@tags['value9'].text,@tags['prop9'])
        if @deleted 
         @tags['key9'].text=""
         @tags['value9'].text=""
        end        
     end

    @tags['key10'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['value10'] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @tags['prop10'] = FXComboBox.new(frame1, 10, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @tags['prop10'].numVisible = 2      
    @tags['prop10'].appendItem("true")	
    @tags['prop10'].appendItem("false")
    @tags['prop10'].setCurrentItem(1)        
    @tags['save10_button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @tags['save10_button'].icon = @accept
    @tags['save10_button'].tipText = "Save Tag"
    @tags['save10_button'].connect(SEL_COMMAND) do
       if @tags['key10'].text == @nickname_tag
          @tags['value10'].text = @tags['value10'].text.gsub('/', '')
       end    
       save_tag(@resource_id,@tags['key10'].text,@tags['value10'].text,@tags['prop10'])
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
    if curr_tags != nil 
       curr_tags.each_pair do |k,v|
          i=i+1
          @tags["key#{i}"].text=k
          @tags["value#{i}"].text=v
       end   
    end
    i=0
    if @prop != nil 
       @prop.each do |p|
          i=i+1
          @tags["prop#{i}"].setCurrentItem(0) if p == true
       end   
    end    
    
   end
   if @tags['key1'].text == nil or @tags['key1'].text == ""
       @tags['key1'].text = @nickname_tag
       @tags['value1'].text = ""
   end 
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    return_button = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    return_button.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end 
  
  def get_tags(resource_id, resource_type)
          data = all(resource_id,resource_type)
          ta = {}
          @prop = []
    	  if data != nil
    	     data.each do |r|
      	        ta[r['Key']] = r['Value']
    	        @prop.push(r['PropagateAtLaunch'])
    	     end
    	  end
      	  ta
  end
  
  def all(resource=nil,type=nil)
        data = []
        filter = {}
        filter['auto-scaling-group'] = resource if resource != nil 
        conn = @ec2_main.environment.as_connection
        if conn != nil
           begin 
             response = conn.describe_tags(filter)
             if response.status == 200
                data = response.body['DescribeTagsResult']['Tags']
             else 
                data = []
             end  
      	  rescue
              puts "ERROR: getting all autoscaling group tags  #{$!}"
           end
        end   
        return data
  end
  
  def save_tag(resource_id, key, value, prop)
    if key != nil and key != ""
     conn = @ec2_main.environment.as_connection
     if conn != nil
      begin 
       parm = {}
       parm['ResourceId'] = resource_id
       parm['ResourceType'] = "auto-scaling-group"
       parm['PropagateAtLaunch'] = false if prop.itemCurrent?(1)
       parm['PropagateAtLaunch'] = true if prop.itemCurrent?(0)
       parm['Key'] = key
       parm['Value'] = value
       r = conn.create_or_update_tags([parm])
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
     conn = @ec2_main.environment.as_connection
     if conn != nil
      begin 
       parm = {}
       parm['ResourceId'] = resource_id
       parm['ResourceType'] = "auto-scaling-group"
       parm['Key'] = key
       parm['Value'] = value      
       r = conn.delete_tags([parm])
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
  
  def item 
     curr_tags = []
     for i in 1..10
        if @tags["key#{i}"].text != nil and @tags["key#{i}"].text != ""
           h = {}
           h['Key'] = @tags["key#{i}"].text
           h['Value'] = @tags["value#{i}"].text
           h['PropagateAtLaunch'] = false if @tags["prop#{i}"].itemCurrent?(1)
           h['PropagateAtLaunch'] = true if @tags["prop#{i}"].itemCurrent?(0)
           curr_tags.push(h)
        end   
        i=i+1
     end  
     curr_tags
  end 
  
end
