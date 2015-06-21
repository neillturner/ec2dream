require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class KIT_LogSelectDialog < FXDialogBox

  def initialize(owner)
    @curr_env = ""
    @ec2_main = owner
    logs = nil
    kit_repository = $ec2_main.settings.get('TEST_KITCHEN_PATH')
    d = "#{kit_repository}/.kitchen/logs"
    begin
      logs = Dir.entries(d)
    rescue
      error_message("Kitchen Log Location does not exist",$!)
    end
    super(owner, "Select Log", :opts => DECOR_ALL, :width => 400, :height => 200)
    loglist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    if logs != nil
      logs.each do |e|
        if e != "." and e != ".."
          loglist.appendItem(e)
        end
      end
    end
    loglist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      loglist.each do |item|
        selected_item = item.text if item.selected?
      end
      puts "item "+selected_item
      editor = @ec2_main.settings.get_system('EXTERNAL_EDITOR')
      c="\"#{editor}\" \"#{kit_repository}/.kitchen/logs/#{selected_item}\""
      puts c
      system(c)
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
end
