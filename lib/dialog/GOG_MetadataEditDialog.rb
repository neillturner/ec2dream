require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/GOG_Metadata'

include Fox

class GOG_MetadataEditDialog < FXDialogBox

  def initialize(owner, metadata, metadata_tags)
    puts "GOG_MetadataEditDialog.initialize"
    @ec2_main = owner
    @metadata_id = metadata 
    @saved = false
    @metadata_tags = nil
    @key = []
    @value = []
    super(owner, "Edit Metadata for #{@metadata_id}", :opts => DECOR_ALL, :width => 800, :height => 450)
    frame1 = FXMatrix.new(self, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Value",:opts => LAYOUT_CENTER_X)
 
    @key[0] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[0] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[1] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[1] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[2] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[2] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[3] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[3] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[4] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[4] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)

    @key[5] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[5] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[6] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[6] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[7] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[7] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[8] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[8] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[9] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @value[9] = FXTextField.new(frame1, 100, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)

    if metadata_tags != nil
       i=0
       curr_tags = metadata_tags.get
       puts "curr_tags #{curr_tags}"
       if curr_tags != nil 
          curr_tags.each_pair do |k,v|
             @key[i].text=k
             @value[i].text=v
             i=i+1
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
    curr_tags = {}
    for i in 0..9 do
      if @key[i].text != nil and @key[i].text != ""
         curr_tags["#{@key[i].text}"] = @value[i].text
      end
    end
    @metadata_tags = GOG_Metadata.new(@ec2_main,curr_tags)
    @saved = true
  end   
  
  def metadata_tags
     @metadata_tags
  end    

  def saved
     @saved
  end

  def success
     @saved
  end
  
end
