require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'

include Fox

class EC2_SnapDialog < FXDialogBox

  def initialize(owner)
    puts "SnapDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
       @ec2_main.environment.snapshots.all.each do |r|
            if r[:tags] != nil
               t = EC2_ResourceTags.new(@ec2_main,r[:tags])
               n = t.nickname()
               if n != "" and n  != nil
	            r[:aws_id] = n +"/"+ r[:aws_id]
               end
            end
          @item_name.push(r[:aws_id])
       end
       @item_name = @item_name.sort
       super(owner, "Select Snapshot", :opts => DECOR_ALL, :width => 200, :height => 200)
       itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       @item_name.each do |e|
          itemlist.appendItem(e)
       end
       itemlist.connect(SEL_COMMAND) do |sender, sel, data|
          selected_item = ""
          itemlist.each do |item|
             selected_item = item.text if item.selected?
          end
          puts "item "+selected_item
          @curr_item = selected_item
          puts "Snap "+@curr_item
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end
  end

  def selected
    return @curr_item
  end

  def success
    true
  end

end


