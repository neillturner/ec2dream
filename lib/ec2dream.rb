#!/usr/bin/ruby
$LOAD_PATH << ENV['EC2DREAM_HOME'] 
puts $LOAD_PATH

require 'EC2_Main'

class Ec2dream
  def initialize()
    application = FXApp.new("EC2_Main", "")
    application.setBackColor(FXRGB(255, 255, 255))
    if RUBY_PLATFORM.index("linux") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
      application.setBaseColor(FXRGB(240, 240, 240))
    else
      #if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
      #   application.setBaseColor(FXRGB(220, 220, 220))
      #end   
    end
    application.setSleepTime(0)
    FXToolTip.new(application)
    EC2_Main.new(application,"EC2Dream")
    application.create
    application.run
    FXApp::ID_QUIT
  end   

end

