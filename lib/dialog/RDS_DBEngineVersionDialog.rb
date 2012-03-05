
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_DBEngineVersionDialog < FXDialogBox

  def initialize(owner)
    puts "RDS_DBEngineVersionDialog.initialize"
    @ec2_main = owner
    @curr_item = nil
    @item_name = Array.new
    @engine = Array.new
    @engine_version = Array.new
    rds = @ec2_main.environment.rds_connection
    if rds != nil
       i=0
       begin
          rds.describe_db_engine_versions.each do |r|
             puts r
             @engine[i] = r[:engine]
             @engine_version[i] = r[:engine_version]
             @item_name[i] = "#{r[:engine]} #{r[:engine_version]} (Family: #{r[:db_parameter_group_family]} "
             i = i+1
          end
       rescue
       end
       super(owner, "Select Engine and Version", :opts => DECOR_ALL, :width => 400, :height => 200)
       itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       @item_name.each do |e|
          itemlist.appendItem(e)
       end 
       itemlist.connect(SEL_COMMAND) do |sender, sel, data|
          i = 0
          itemlist.each do |item|
             @curr_item = i if item.selected?
             i = i+1
          end
          puts "DBEngine #{@curr_item}"
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end
    end
  end

  def engine
   if @curr_item != nil   
      return @engine[@curr_item]
   else
      return ""
   end  
  end 

  def engine_version
   if @curr_item != nil   
      return @engine_version[@curr_item]
   else
      return ""
   end  
  end 

  def selected
    if @curr_item != nil    
       return true 
    else
       return false
    end
  end  
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end