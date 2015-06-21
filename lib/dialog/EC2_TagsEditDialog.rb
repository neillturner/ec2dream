require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'

include Fox

class EC2_TagsEditDialog < FXDialogBox

  def initialize(owner, resource, resource_tags)
    puts "TagsEditDialog.initialize"
    @ec2_main = owner
    sa = (resource).split("/")
    @resource_id = resource 
    if sa.size>1
      @resource_id = sa[1].rstrip
    end    
    @saved = false
    @resouce_tags = nil
    @key = []
    @value = []
    super(owner, "Edit tags for #{@resource_id}", :opts => DECOR_ALL, :width => 450, :height => 350)
    frame1 = FXMatrix.new(self, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Key",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Value",:opts => LAYOUT_CENTER_X)
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

    if resource_tags != nil
      i=0
      curr_tags = resource_tags.get
      puts "curr_tags #{curr_tags}"
      if curr_tags != nil 
        curr_tags.each_pair do |k,v|
          @key[i].text=k
          @value[i].text=v
          i=i+1
        end   
      end
    else
      nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
      if nickname_tag != nil and nickname_tag != ""
        @key[0].text = nickname_tag
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
    nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
    if nickname_tag == nil
      nickname_tag = ""
    end   
    for i in 0..9 do
      if @key[i].text != nil and @key[i].text != ""
        if @key[i].text == nickname_tag
          @value[i].text = @value[i].text.gsub('/', '')
        end
        curr_tags["#{@key[i].text}"] = @value[i].text
      end
    end
    @resouce_tags = EC2_ResourceTags.new(@ec2_main,curr_tags,nil)
    @saved = true
  end   
  def resource_tags
    @resouce_tags
  end    

  def saved
    @saved
  end

  def success
    @saved
  end
end
