require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_TagsFilterDialog < FXDialogBox

  def initialize(owner, resource, tags={})
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
       tags.each do |t , t2|
         @key[i].text = t
         if t2.instance_of? Array
            t3 = ""
            t2.each do |a|
              if t3 != "" 
                 t3 = "#{t3},#{a}" 
              else 
	   	 t3 = a
	      end 
	    end  
	    @value[i].text = t3
          end
          i=i+1
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
    @tag_filter = {}
    for i in 0..9 do
      if @key[i].text != nil and @key[i].text != ""
        t=@key[i].text
        if @value[i].text != nil and @value[i].text != ""
           t2 = @value[i].text.split(",")
        else
           t2 = [""]
        end
        @tag_filter[t] = t2
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

  def success
     @saved
  end
  
end
