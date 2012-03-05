
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

class EC2_Notes

  def initialize(owner)
        @ec2_main = owner
        @loaded = false
        tab1 = FXTabItem.new(@ec2_main.tabBook, "Notes")
  	page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
  	page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@save_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @save = @ec2_main.makeIcon("disk.png")
	@save.create
	@save_button.icon = @save
	@save_button.tipText = "  Save  "
        @save_button.connect(SEL_COMMAND) do |sender, sel, data|
            save
        end
        @save_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end 
	end
        @text_area = FXText.new(page1, :opts => TEXT_WORDWRAP|LAYOUT_FILL)
  end
  
def clear
    @text_area.text = ""
    @loaded = false
end
  
def load
   fn = @ec2_main.settings.get_system('ENV_PATH')+"/notes.txt"        
   if File.exists?(fn) == false
      File.new(fn, "w")
   end
   f = File.open(fn, "r")
   @text_area.text = f.read
   f.close
   @loaded = true
end        
  
def save
   puts "Notes.save"
   textOutput = @text_area.text
   fn = @ec2_main.settings.get_system('ENV_PATH')+"/notes.txt"
   File.open(fn, 'w') do |f|  
      f.write(textOutput)
      f.close
   end
end  
    
  def error_message(title,message)
     FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end


end 
