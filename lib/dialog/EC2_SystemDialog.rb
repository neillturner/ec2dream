require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SystemDialog < FXDialogBox

  def initialize(owner)
    puts "SystemDialog.initialize"
    @ec2_main = owner
    @valid_loc = false
    @settings = @ec2_main.settings
    @loc = ""
    @remloc = ""
    local_repository = "#{ENV['EC2DREAM_HOME']}/env"
    if !File.directory? local_repository
       puts "creating....#{local_repository}"
       Dir.mkdir(local_repository)
       @settings.put_system("REPOSITORY_LOCATION","")
       defaults
       @settings.save_system()	   
    elsif File.exists?(ENV['EC2DREAM_HOME']+"/env/system.properties")
       @loc = @settings.get_system("REPOSITORY_LOCATION")
       @remloc = @settings.get_system("REPOSITORY_REMOTE")
       if @loc ==  ENV['EC2DREAM_HOME']+"/env"
         @loc = ""
       end  
    end
    super(owner, "Environment Repository", :opts => DECOR_ALL, :width => 600, :height => 250, :x => 300, :y => 200 )
	page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1a = FXMatrix.new(page1, 1, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(frame1a, "The Environment Repository is where configuration is stored." )
    FXLabel.new(frame1a, "Checking Local Environment Repository stores the information inside the ruby directory structure." ) 
 	FXLabel.new(frame1a, "For production use a repository location and create backups." ) 
    FXLabel.new(frame1a, "NOTE: You must first create the directory using Windows Explorer or the command line" )
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )   	
    local_check = FXCheckButton.new(frame1,"Local Environment Repository", :opts => ICON_BEFORE_TEXT|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Repository Location" )
    location = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    location_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    magnifier = @ec2_main.makeIcon("magnifier.png")
    magnifier.create
    location_button.icon = magnifier
    location_button.tipText = "Browse..."
    location_button.connect(SEL_COMMAND) do
       if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
          location.text = FXDirDialog.getOpenDirectory(frame1, "Select Repository Location", "C:/")
       else
	  location.text = FXDirDialog.getOpenDirectory(frame1, "Select Repository Location", "/")
       end 
    end
    if @loc != nil and @loc != ""
       @local = false
       location.text = @loc
       local_check.setCheck(false)
       location.enable
       location_button.enable
    else
       @local = true
       location.text = ""
       local_check.setCheck(true)
       location.disable
       location_button.disable
    end        
    
    local_check.connect(SEL_COMMAND) do
       if @local == false
          @local = true
          location.text = ""
          location.disable
          location_button.disable
       else
          @local = false
          if @remloc != nil and @remloc.length>0
             location.text= @remloc
          else   
             location.text = ""
          end               
          location.enable
          location_button.enable
       end
    end
    
    FXLabel.new(frame1, "" )
    ok = FXButton.new(frame1, "   &OK   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )

    ok.connect(SEL_COMMAND) do |sender, sel, data|
      @valid_loc = true
      if @local == false
         envs = nil
         begin
            envs = Dir.entries(location.text)
         rescue
            @valid_loc = false
            error_message("Repository Location does not exist",$!)
         end
      end
      if @valid_loc == true
         if @local == false
            @settings.put_system("REPOSITORY_LOCATION",location.text)
            @settings.put_system("REPOSITORY_REMOTE",location.text)
         else 
            @settings.put_system("REPOSITORY_LOCATION","")
         end
         defaults
         @settings.put_system('ENVIRONMENT','')
         @settings.put_system('AUTO','false') 
         @settings.save_system()
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end   
    end
  end
  
  def selected
     return @valid_loc
  end 

  def defaults
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
       @settings.put_system('EXTERNAL_EDITOR',"notepad")  # default to notepad
       @settings.put_system('EXTERNAL_BROWSER',"C:\\Program Files\\Internet Explorer\\iexplore.exe")  
     else
       if RUBY_PLATFORM.index("linux") != nil
          @settings.put_system('EXTERNAL_EDITOR',"gedit")  # default to vi
          @settings.put_system('EXTERNAL_BROWSER',"/usr/bin/firefox")
       else
          @settings.put_system('EXTERNAL_EDITOR',"xterm -e /Applications/TextEdit.app/Contents/MacOS/TextEdit")  
          @settings.put_system('EXTERNAL_BROWSER',"open")
       end   
     end
     @settings.put_system('TIMEZONE',"UTC")
  end

end
