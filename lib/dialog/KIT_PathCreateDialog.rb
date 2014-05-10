require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class KIT_PathCreateDialog < FXDialogBox

  def initialize(owner)
    puts "KIT_PathCreateDialog.initialize"
    @saved = false
    @ec2_main = owner
    path = @ec2_main.settings.get("TEST_KITCHEN_PATH")
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(@ec2_main, "Configure Test Kitchen Path", :opts => DECOR_ALL, :width => 650, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
	FXLabel.new(frame1, "TEST_KITCHEN_PATH" )
 	test_kitchen_path = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	test_kitchen_path_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	test_kitchen_path_button.icon = @magnifier
	test_kitchen_path_button.tipText = "Browse..."
	test_kitchen_path_button.connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Test Kitchen Path Directory")
	   if test_kitchen_path.text==nil or test_kitchen_path.text==""
              dialog.directory = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver"
           else
              dialog.directory =test_kitchen_path.text
           end
	   if dialog.execute != 0
	      test_kitchen_path.text = dialog.directory
           end
	end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
        @ec2_main.settings.put("TEST_KITCHEN_PATH",test_kitchen_path.text)
        @ec2_main.settings.save
        @saved = true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    test_kitchen_path.text = path if path != nil
  end

  def saved
    @saved
  end

  def success
     @saved
  end


end
