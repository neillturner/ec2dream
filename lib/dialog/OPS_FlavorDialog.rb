require 'rubygems'
require 'fox16'
require 'fog'
require 'net/http'
require 'resolv'

include Fox

class OPS_FlavorDialog < FXDialogBox

  def initialize(owner)
    puts "flavorDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @flavors = Array.new
    super(owner, "Select Flavor", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    conn = @ec2_main.environment.connection
    if conn != nil
       conn.flavors.each do |r|
          @flavors[r.id] = r
       end
       @flavors.each do |f|
          if f != nil 
             itemlist.appendItem("#{f.name} (#{f.id}- Memory #{f.ram}MB Disk #{f.disk}GB)")
          end   
       end
    else
      puts "***Error on connection to Cloud - check your keys in ServerCache.refreshServerTree"
      error_message("Cloud Connection Error",$!.to_s+" - check your Cloud Access Settings")    
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          if item.selected?
             sa=(item.text).split('(')
             selected_item = sa[0].strip
          end
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "instance "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end