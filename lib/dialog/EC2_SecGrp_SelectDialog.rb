require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_SecGrp_SelectDialog < FXDialogBox

  def initialize(owner, type)
    puts "SecGrp_SelectDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @selected = false
    @type = type
    title = "Select Security Group"
    if @type == "rds"
       title = "Select DB Security Group"
    end 
    super(owner, title, :opts => DECOR_ALL, :width => 300, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    instances = Array.new
    i=0
    if @type == "ec2"
        begin
          ec2 = @ec2_main.environment.connection
          ec2.describe_security_groups.each do |r|
             instances[i] = r[:aws_group_name]
             i = i+1
          end
       rescue 
	 puts "***Error on connection to EC2 - check your keys in EC2_SecGrp_SelectDialog"
         @ec2_main.environment.set_connection_failed
         return
       end 
    elsif @type == "ops"
       @ec2_main.serverCache.ops_secgrp.all.each do |r|
          instances[i] = r
          i = i+1
       end
    else 
       @type = "database"
       rds = @ec2_main.environment.rds_connection
       if rds != nil
          i=0
          begin
             rds.describe_db_security_groups.each do |r|
                instances[i] = r[:name]
                i = i+1
             end
          rescue 
   	   puts "***Error on connection to RDS - check your keys in EC2_SecGrp_SelectDialog"
           return
          end 
       end      
    end
    @instances = instances.sort 
    instances.each do |inst|
       itemlist.appendItem(inst)
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          if item.selected?
              selected_item = item.text
          end
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "SecGrp "+@curr_item
       @selected = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
      return @selected
  end
    
  def type 
      return @type
  end 
    
  def sec_grp 
     return  @curr_item
  end 
  
  
end