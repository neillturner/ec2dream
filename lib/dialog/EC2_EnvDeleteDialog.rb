
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fileutils'
 

include Fox

class EC2_EnvDeleteDialog < FXDialogBox

  def initialize(owner)
    @ec2_main = owner
    @envs = Dir.entries(@ec2_main.settings.get_system('REPOSITORY_LOCATION'))
    @delete_env = ""
    super(owner, "Select Environment to Delete", :opts => DECOR_ALL, :width => 400, :height => 200)
    cancel = FXButton.new(self, "   &CANCEL   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    @envlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    auto = "false" 
    @envs.each do |e|
     if e != "." and e != ".."
      @envlist.appendItem(e)
     end 
    end
    
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
     
    @envlist.connect(SEL_COMMAND) do
       selected_item = ""
       @envlist.each do |item|
        selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @delete_env = selected_item
       if @delete_env != nil and @delete_env != ""
         delete
       end  
     end
  end
  
  def delete
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of environment "+@delete_env)
     if answer == MBOX_CLICKED_YES
        d = @ec2_main.settings.get_system('REPOSITORY_LOCATION')+"/"+@delete_env
        puts "deleting "+d
        begin 
           FileUtils.rm_r d
        rescue 
           error_message("Delete Environment Failed","Delete Environment Failed. Quit EC2Dream and try again")
           return
        end         
        if File.exists?(d)
           error_message("Delete Environment Failed","Delete Environment Failed. Quit EC2Dream and try again")
        end   
        @envlist.clearItems
        @envs = Dir.entries(@ec2_main.settings.get_system('REPOSITORY_LOCATION'))
        @envs.each do |e|
	     if e != "." and e != ".."
	      @envlist.appendItem(e)
	     end 
        end
        # if deleted current environment reset system properties
        settings = @ec2_main.settings
        #settings.load_system
	curr_env = settings.get_system("ENVIRONMENT")
	if curr_env == @delete_env
	   settings.put_system("ENVIRONMENT","")
	   settings.put_system("AUTO","false")
	   settings.save_system
	end
     end    
  end  
 
  def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end