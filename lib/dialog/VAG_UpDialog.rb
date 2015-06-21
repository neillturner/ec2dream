require 'rubygems'
require 'fox16'

include Fox

class VAG_UpDialog < FXDialogBox

  def initialize(owner, curr_item)
    @success = vargant(curr_item, "up")
  end

  def vargant(server, command)
    answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm vagant #{command}","Confirm vagrant #{command} for server #{server}")
    if answer == MBOX_CLICKED_YES
      folder = "#{$ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{server}"
      if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
        folder = folder.gsub('/','\\')
        c = "cmd.exe /c \@start \"#{server} - vagrant #{command} \" \"#{ENV['EC2DREAM_HOME']}/vagrant/vagrant_cmd.bat\" #{folder} #{command}"
        puts c
        system(c)
      else
        c = "#{ENV['EC2DREAM_HOME']}/vagrant/vagrant_cmd.sh\" #{folder} #{command}"
        puts c
        system(c)
      end
      true
    end
    false
  end

  def success
    @success
  end
end