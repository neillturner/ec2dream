require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_ServerDialog'

class EC2_Stacks

  def initialize(owner)
        puts "Stacks.initialize"
        @ec2_main = owner
	@stacks = {}
	@task = ""
        tab5 = FXTabItem.new(@ec2_main.tabBook, " Stacks ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook)
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@view = @ec2_main.makeIcon("application_view_icons.png")
	@view.create
	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
        @help = @ec2_main.makeIcon("help.png")
	@help.create
        @view_button = FXButton.new(page1a, "",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@view_button.icon = @view
	@view_button.tipText = ""
	@view_button.connect(SEL_COMMAND) do |sender, sel, data|
	end
        @edit_button = FXButton.new(page1a, "",:opts => BUTTON_NORMAL|LAYOUT_LEFT)	
	@edit_button.icon = @edit
	@edit_button.tipText = ""
	@edit_button.connect(SEL_COMMAND) do |sender, sel, data|
	end
	@help_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@help_button.icon = @help
	@help_button.tipText = ""
	@help_button.connect(SEL_COMMAND) do |sender, sel, data|
	end	
        frame1 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
        FXLabel.new(frame1,"")
        FXLabel.new(frame1,"")
        FXLabel.new(frame1,"")
        FXLabel.new(frame1,"")
        FXLabel.new(frame1,"Cloud Formation Stacks - ***This is still in development***")
        FXLabel.new(frame1,"")
        FXLabel.new(frame1,"")
	FXLabel.new(frame1,"")
        FXLabel.new(frame1,"")
  end 
  
  def browser(url)
        if @ec2_main.settings.get_system('EXTERNAL_BROWSER') != nil and @ec2_main.settings.get_system('EXTERNAL_BROWSER') != ""
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
              c = "cmd.exe /c \@start \"\" /b \""+@ec2_main.settings.get_system('EXTERNAL_BROWSER')+"\"  "+url
              puts c
              system(c)
           else
              c = @ec2_main.settings.get_system('EXTERNAL_BROWSER')+" "+url
              puts c
              system(c)
           end
        else
           error_message(@ec2_main,"Error","No External Browser in Settings")
        end
 end  
  
 def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
 end
  
end 
