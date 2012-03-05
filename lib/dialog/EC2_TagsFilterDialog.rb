
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_TagsFilterDialog < FXDialogBox

  def initialize(owner, resource, tags=[])
    puts "TagsFilterDialog.initialize"
    @ec2_main = owner
    @resource_id = resource 
    @saved = false
    @tag_filter = {}
    @key = []
    @value = []
    super(owner, "Filter tags for #{@resource_id}", :opts => DECOR_ALL, :width => 450, :height => 350)
    frame1 = FXMatrix.new(self, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Values (Comma Separated)",:opts => LAYOUT_CENTER_X)
 
    @key[0] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[0] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[1] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[1] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[2] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[2] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[3] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[3] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[4] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[4] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)

    @key[5] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[5] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[6] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[6] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[7] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[7] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[8] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[8] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[9] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[9] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)

    i = 0
    puts tags
    if tags != nil
       tags.each do |t|
          #puts "t #{t}" 
          t.each do |t2|
             #puts "t2 #{t2}  #{t2.class}"
               if t2.instance_of? Array
                  t2.each do |a|
                     #puts "a #{a}  #{a.class}"
                     if a.instance_of? String 
                        if a.length>4 and a[0..3]=="tag:"
                           @key[i].text = "#{a[4..-1]}"
                        else
                           if @value[i].text != "" 
                              @value[i].text = "#{@value[i].text},#{a}" 
                           else 
	   	              @value[i].text = a
	   	           end                          
                        end
                     end  
                  end
               end
          end
       end    
    end
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    save_button = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    save_button.connect(SEL_COMMAND) do |sender, sel, data|
       save_tags
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    exit_button = FXButton.new(frame1, "   &Exit   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    exit_button.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end

  end 
  
  def save_tags
    @tag_filter = []
    for i in 0..9 do
      if @key[i].text != nil and @key[i].text != ""
        t = []
        t.push(["tag:#{@key[i].text}"])
        if @value[i].text != nil and @value[i].text != ""
           t2 = @value[i].text.split(",")
           t.push(t2) 
        else
           t.push([""])
        end
        @tag_filter.push(t)
      end
    end
    puts "save_tags #{@tag_filter}"
    @saved = true
  end   
  
  def tag_filter
     @tag_filter
  end    

  def saved
     @saved
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
