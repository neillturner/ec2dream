
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/GOG_FirewallMappingEditDialog'
require 'common/GOG_Firewall_Mapping'
require 'common/error_message'

include Fox

class GOG_FirewallCreateDialog < FXDialogBox

  def initialize(owner)
    puts "GOG_FirewallCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    @firewall_mapping = GOG_Firewall_Mapping.new
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @create = @ec2_main.makeIcon("new.png")
    @create.create
    @delete = @ec2_main.makeIcon("kill.png")
    @delete.create		
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    super(owner, "Create Firewall", :opts => DECOR_ALL, :width => 700, :height => 300)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Name" )
    name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Source Tags" )
    source_tags = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    source_tags.text = ""
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Source IP Range (CIDR)" )
    source_range = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    source_range.text = ""
    FXLabel.new(frame1, "" )	 
    FXLabel.new(frame1, "Rules")
    @rules_table = FXTable.new(frame1,:height => 60, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
    @rules_table.rowHeaderWidth = 0
    @rules_table.connect(SEL_COMMAND) do |sender, sel, which|
      @firewall_mapping.set_curr_row(which.row)
      @rules_table.selectRow(@firewall_mapping.curr_row)
    end
    page1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
    @create_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @create_button.icon = @create
    @create_button.tipText = "  Add Rule  "
    @create_button.connect(SEL_COMMAND) do |sender, sel, data|
      dialog = GOG_FirewallMappingEditDialog.new(@ec2_main,nil)
      dialog.execute
      if dialog.saved 
        r = dialog.firewall_mapping
        @firewall_mapping.push(r)
        @firewall_mapping.load_table(@rules_table)
      end
    end
    @create_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @edit_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)
    @edit_button.icon = @edit
    @edit_button.tipText = "  Edit Rules  "
    @edit_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @rule_table.curr_row == nil
        error_message("No Firewall Rule selected","No Firewall Rule selected to edit")
      else	
        dialog = GOG_FirewallMappingEditDialog.new(@ec2_main,@firewall_mapping.get)
        dialog.execute
        if dialog.saved 
          r = dialog.firewall_mapping
          @firewall_mapping.update(r)
          @firewall_mapping.load_table(@rule_table)
        end
      end   
    end	
    @delete_button = FXButton.new(page1a, " ",:opts => BUTTON_TOOLBAR)

    @delete_button.icon = @delete
    @delete_button.tipText = "  Delete Firewall Rule  "
    @delete_button.connect(SEL_COMMAND) do |sender, sel, data|
      if @firewall_mapping.curr_row == nil
        error_message("No Firewall Rule selected","No Firewall Rule selected to delete")
      else
        m = @firewall_mapping.get
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Firewall Rule for  #{m['IPProtocol']}")
        if answer == MBOX_CLICKED_YES
          @firewall_mapping.delete
          @firewall_mapping.load_table(@rules_table)                   
        end   
      end  
    end
    @delete_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end		
    FXLabel.new(frame1, "Network" )
    network = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    network.text = "default"
    network_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    network_button.icon = @magnifier
    network_button.tipText = "Select..."
    network_button.connect(SEL_COMMAND) do
      dialog = EC2_VpcDialog.new(@ec2_main)
      dialog.execute
      item = dialog.selected
      if item != nil and item != ""
        network.text = item
      end	    
    end            
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      @created = false
      allowed = [] 
      sr = (source_range.text).split(',')
      st = (source_tags.text).split(',')
      fm = @firewall_mapping.array
      fm.each do |m|
        a = {}
        a['IPProtocol'] = m['IPProtocol']
        a['ports'] = m['ports'].split(',')
        allowed.push(a)
      end	 
      create_firewall(name.text, allowed, sr, st, network.text)
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end 
  def create_firewall(name, allowed, source_range, source_tags,  network=nil)
    begin 
      r = @ec2_main.environment.security_group.insert_firewall(name, allowed, source_range, source_tags, network)
      @created = true
    rescue
      error_message("Insert Firewall Failed",$!)
    end
  end 
  def saved
    @created
  end
  def created
    @created
  end
  def success
    @created
  end

end
