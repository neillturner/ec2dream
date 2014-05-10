require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_SecGrp_AuthorizeDialog'
require 'dialog/EC2_SecGrp_RevokeDialog'
require 'dialog/EC2_SecGrp_SelectDialog'
require 'dialog/EC2_SecGrp_CreateDialog'
require 'dialog/EC2_TagsAssignDialog'
require 'common/EC2_ResourceTags'
require 'common/error_message'

class EC2_SecGrp

  def initialize(owner)
        @ec2_main = owner
        @secgrp_loaded = false
        @type = ""
        @curr_item = ""
        @curr_item_1 = ""
        @curr_item_2 = ""
        @curr_item_3 = ""
        @curr_row = 0
        @secgrp = {}
    	@secgrp_tags = nil
    	@secgrp_tags_text =""
    	@rule_ids = []
    	@sec_group_ids = {}
	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@create = @ec2_main.makeIcon("new.png")
	@create.create
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@kill = @ec2_main.makeIcon("kill.png")
	@kill.create
	@link = @ec2_main.makeIcon("link.png")
	@link.create
	@link_break = @ec2_main.makeIcon("link_break.png")
	@link_break.create
        @tag_red = @ec2_main.makeIcon("tag_red.png")
	@tag_red.create
        tab = FXTabItem.new(@ec2_main.tabBook, " SecGrp ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Refresh Security Group"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	    puts "server.refresh.connect"
	    if @secgrp_loaded == true
	       if @type == "ec2"
	          @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'],@secgrp['vpc_id'])
	          load(@secgrp['Security_Group'],@secgrp['vpc_id'])
	       end
	    end
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	@create_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create_button.icon = @create
	@create_button.tipText = "  Create Security Group "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	    create_type = 'linux'
	    dialog = EC2_SecGrp_CreateDialog.new(owner,create_type)
	    dialog.execute
	    if  dialog.created
	       type = dialog.type
	       created_secgrp = dialog.sec_grp
	       created_vpc = dialog.vpc
               load(created_secgrp,created_vpc)
	    end
	end
	@create_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @ec2_main.settings.openstack_rackspace
	      sender.enabled = false
	   else
	    enable_if_env_set(sender)
	   end
	end
	@select_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@select_button.icon = @magnifier
	@select_button.tipText = "  Select Security Group  "
	@select_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_SecGrp_SelectDialog.new(owner,@type)
	   dialog.execute
	   if dialog.selected
	      type = dialog.type
	      selected_secgrp = dialog.sec_grp
	      selected_vpc = dialog.vpc
              load(selected_secgrp,selected_vpc)
	   end
	end
	@select_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@delete_button.icon = @kill
	@delete_button.tipText = " Delete Security Group "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	    delete
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_secgrp_loaded(sender)
	end
	@link_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link_button.icon = @link
        @link_button.tipText = "Make Authorisation"
	@link_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type == "ec2"
	      dialog = EC2_SecGrp_AuthorizeDialog.new(@ec2_main,@secgrp['Security_Group'],@secgrp['vpc_id'] )
	      dialog.execute
	      if dialog.created
	         @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'],@secgrp['vpc_id'])
                 load(@secgrp['Security_Group'],@secgrp['vpc_id'])
              end
           end
 	end
	@link_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @secgrp_loaded == true and !@ec2_main.settings.openstack_rackspace
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end
	end
	@link_break_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link_break_button.icon = @link_break
        @link_break_button.tipText = "Revoke Authorisation"
	@link_break_button.connect(SEL_COMMAND) do |sender, sel, data|
           if @type == "ec2"
	     if (@curr_item == nil or @curr_item == "") and (@curr_item_1 == nil or @curr_item_1 == "") and (@curr_item_2 == nil or @curr_item_2 == "") and (@curr_item_3 == nil or @curr_item_3 == "")
                error_message("No Authorization selected","No Authorization selected to revoke")
             else
                rule_id = 0
                if  @ec2_main.settings.openstack
                   rule_id = @rule_ids[@curr_row]
                end
 	        dialog = EC2_SecGrp_RevokeDialog.new(@ec2_main,@secgrp['Security_Group'],@curr_item, @curr_item_1, @curr_item_2, @curr_item_3, rule_id, @secgrp['group_id'], @sec_group_ids[@curr_item_3]  )
	        if dialog.deleted
	           @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'],@secgrp['vpc_id'])
	           load(@secgrp['Security_Group'],@secgrp['vpc_id'])
	        end
	        @curr_item = ""
	        @curr_item_1 = ""
	        @curr_item_2 = ""
	        @curr_item_3 = ""
	     end
           end
	end
	@link_break_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @secgrp_loaded == true and !@ec2_main.settings.openstack_rackspace
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end
	end
        @tag_button = FXButton.new(page1a, "", :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @tag_button.icon = @tag_red
        @tag_button.tipText = "Edit Tags"
        @tag_button.connect(SEL_COMMAND) do
            dialog = EC2_TagsAssignDialog.new(@ec2_main,@secgrp['group_id'],'security-group')
            dialog.execute
            if dialog.saved
               @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'],@secgrp['vpc_id'])
               load(@secgrp['Security_Group'],@secgrp['vpc_id'])
	    end
        end
	@tag_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @secgrp_loaded == true and @type == "ec2" and @ec2_main.settings.get("EC2_PLATFORM") == "amazon"
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end
	end
	contents = FXVerticalFrame.new(page1, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y,
	       :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0,
	       :hSpacing => 0, :vSpacing => 0)
	@top = FXTable.new(contents, :opts => LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY, :height => 110  )
	@top.columnHeaderHeight = 0
	@top.rowHeaderWidth = 0
	@table = FXTable.new(contents, :opts => LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@table.rowHeaderWidth = 0
	# Make header control
	@body1 = @table.columnHeader
	@table.connect(SEL_COMMAND) do |sender, sel, which|
	      @curr_item = @table.getItemText(which.row,0).to_s
	      @curr_item_1 = @table.getItemText(which.row,1).to_s
	      @curr_item_2 = @table.getItemText(which.row,2).to_s
	      if @type == "ec2"
	         @curr_item_3 = @table.getItemText(which.row,3).to_s
	      else
	         @curr_item_3 = ""
	      end
	      @curr_row = which.row
	      @table.selectRow(which.row)
	end
  end

  def secgrpPanel(item)
      puts "secgrp.secgrpPanel"
      load(item.text)
  end

  def load(sg,vpc=nil)
    puts "SecGrp.load #{sg} #{vpc}"
    @type = "ec2"
    if  @ec2_main.settings.openstack or   @ec2_main.settings.google
       load_ops(sg)
    else
       @secgrp['Security_Group'] = sg
       @top.clearItems
       @top.setBackColor(FXRGB(240, 240, 240))
       @top.setTableSize(5, 2)
       @top.setItemText(0, 1, sg)
       @top.setItemJustify(0, 1, FXTableItem::LEFT)
       @top.setColumnWidth(1,200)
       @top.setItemText(0, 0, "Security Group")
       @top.setItemJustify(0, 0, FXTableItem::LEFT)
       @top.setCellColor(0,0,FXRGB(240, 240, 240))
       lists_0 = []
       lists_1 = []
       lists_2 = []
       lists_3 = []
       groups_perm = []
       @sec_group_ids = {}
       x = @ec2_main.serverCache.secGrps(sg,vpc)
       if x != nil
	     if x['tagSet'] != nil and x['tagSet'].to_s != "{}"
    	     	@secgrp_tags = EC2_ResourceTags.new(@ec2_main,x['tagSet'],nil)
   	        @secgrp_tags_text = @secgrp_tags.show
   	     else
   	        @secgrp_tags = nil
    	        @secgrp_tags_text =""
   	     end
             #data = @ec2_main.environment.tags.all(x[:group_id])
    	     #ta = {}
    	     #if data != nil
    	     #   data.each do |aws_tag|
    	     #      ta[aws_tag['key']] = aws_tag['value']
    	     #    end
    	     #end
     	     #if ta.size>0
   	     #   @secgrp_tags = EC2_ResourceTags.new(@ec2_main,ta,nil)
    	     #   @secgrp_tags_text = @secgrp_tags.show
    	     #else
    	     #   @secgrp_tags = nil
    	     #   @secgrp_tags_text =""
    	     #end
             @secgrp['Description'] = x[:aws_description]
             @top.setItemText(1, 1, x[:aws_description])
             @top.setItemJustify(1, 1, FXTableItem::LEFT)
             @top.setItemText(1, 0, "Description")
             @top.setCellColor(1,0,FXRGB(240, 240, 240))
             @top.setItemJustify(1, 0, FXTableItem::LEFT)
             @secgrp['group_id'] = x[:group_id]
             @top.setItemText(2, 1, x[:group_id])
             @top.setItemJustify(2, 1, FXTableItem::LEFT)
             @top.setItemText(2, 0, "Group Id")
             #@top.setCellColor(2,0,FXRGB(240, 240, 240))
             @top.setItemJustify(2, 0, FXTableItem::LEFT)
             @secgrp['vpc_id'] = x[:vpc_id]
             @top.setItemText(3, 1, x[:vpc_id])
             @top.setItemJustify(3, 1, FXTableItem::LEFT)
             @top.setItemText(3, 0, "VPC Id")
             #@top.setCellColor(3,0,FXRGB(240, 240, 240))
             @top.setItemJustify(3, 0, FXTableItem::LEFT)
             @top.setItemText(4, 1, @secgrp_tags_text)
             @top.setItemJustify(4, 1, FXTableItem::LEFT)
             @top.setItemText(4, 0, "Tags")
             #@top.setCellColor(4,0,FXRGB(240, 240, 240))
             @top.setItemJustify(4, 0, FXTableItem::LEFT)
             j = 0
             y = x[:aws_perms]
             if y != nil
              y.each do |p|
                 o = "owner"
                if p.has_key?(o.to_sym)
                  if x[:aws_owner] != p[:owner]
                     gp_key = "#{p[:owner]}:#{p[:group_name]}"
                  else
                     gp_key = "#{p[:group_name]}"
                  end
                  if !groups_perm.include?(gp_key)
                     groups_perm.push(gp_key)
                     lists_0[j] = "icmp"
   	             lists_1[j] = "-1"
   	             lists_2[j] = "-1"
   	             lists_3[j] = gp_key
   	             lists_0[j+1] = "tcp"
	  	     lists_1[j+1] = "1"
	  	     lists_2[j+1] = "65535"
   	             lists_3[j+1] = gp_key
   	             lists_0[j+2] = "udp"
		     lists_1[j+2] = "1"
		     lists_2[j+2] = "65535"
   	             lists_3[j+2] = gp_key
   	             j=j+3
   	          end
                else
                  lists_0[j] = p[:protocol]
   	          lists_1[j] = p[:from_port]
   	          lists_2[j] = p[:to_port]
   	          lists_3[j] = p[:cidr_ips]
   	          j=j+1
   	        end
             end
          else
             y = x['ipPermissions']
             acct_no = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
             y.each do |p|
    	          p['groups'].each do |item|
   	             gp_key = ""
   	             if item['groupName'] != nil
   	                gp_key = item['groupName']
   	                gp_key = "#{item['userId']}:#{gp_key}" if item['userId'].to_s != acct_no
   	             end
    	             if item['groupName'] == nil and item['groupId'] != nil and @secgrp['vpc_id'] != nil and @secgrp['vpc_id'] != ""
    	                @ec2_main.environment.security_group.all({'group-id' => item['groupId'], 'vpc-id' => @secgrp['vpc_id']}).each do |r|
   	                   gp_key = r['groupName']
   	                   gp_key = "#{item['userId']}:#{gp_key}" if item['userId'].to_s != acct_no
   	                   @sec_group_ids[gp_key] = item['groupId']
   	                end
   	             elsif gp_key == ""
   	                puts "ERROR: Group name found for group permission #{item['groupId']}"
   	             end
   	             lists_0[j] = p['ipProtocol']
   	             lists_1[j] = p['fromPort'].to_s
   	             lists_2[j] = p['toPort'].to_s
   	             lists_3[j] = gp_key
   	             j=j+1
   	          end
   	          p['ipRanges'].each do |item|
                     lists_0[j] = p['ipProtocol']
   	             lists_1[j] = p['fromPort'].to_s
   	             lists_2[j] = p['toPort'].to_s
   	             lists_3[j] = item['cidrIp']
   	             j=j+1
   	          end
             end
          end
          i = lists_0.length
          @table.clearItems
          @table.setTableSize(i, 4)
	  @table.setColumnText(0,"Protocol")
	  @table.setColumnWidth(0,100)
	  @table.setColumnText(1,"From Port")
	  @table.setColumnWidth(1,100)
	  @table.setColumnText(2,"To Port")
	  @table.setColumnWidth(2,100)
	  @table.setColumnText(3,"Source (IP or Group)")
	  @table.setColumnWidth(3,200)
          while i>0
            i = i-1
    	    @table.setItemText(i, 0, lists_0[i])
	    @table.setItemJustify(i, 0, FXTableItem::LEFT)
	    @table.setItemText(i, 1, lists_1[i])
	    @table.setItemJustify(i, 1, FXTableItem::RIGHT)
	    @table.setItemText(i, 2, lists_2[i])
	    @table.setItemJustify(i, 2, FXTableItem::RIGHT)
	    @table.setItemText(i, 3, lists_3[i])
	    @table.setItemJustify(i, 3, FXTableItem::RIGHT)
	  end
	  @curr_item = ""
	  @curr_item_1 = ""
	  @curr_item_2 = ""
	  @curr_item_3 = ""
          @secgrp_loaded = true
          @ec2_main.app.forceRefresh
        end

     end
  end

  def load_ops(sg)
     @secgrp['Security_Group'] = sg
     @top.clearItems
     @top.setBackColor(FXRGB(240, 240, 240))
     @top.setTableSize(5, 2)
     @top.setItemText(0, 1, sg)
     @top.setItemJustify(0, 1, FXTableItem::LEFT)
     @top.setColumnWidth(1,200)
     @top.setItemText(0, 0, "Security Group")
     @top.setItemJustify(0, 0, FXTableItem::LEFT)
     @top.setCellColor(0,0,FXRGB(240, 240, 240))
     lists_0 = []
     lists_1 = []
     lists_2 = []
     lists_3 = []
     @rule_ids = []
     groups_perm = []
     x = @ec2_main.serverCache.secGrps(sg)
     if x != nil
        y = x[:rules]
        ec2 = @ec2_main.environment.connection
        ta = {}
        @secgrp['Description'] = x[:description]
        @top.setItemText(1, 1, x[:description])
        @top.setItemJustify(1, 1, FXTableItem::LEFT)
        @top.setItemText(1, 0, "Description")
        @top.setCellColor(1,0,FXRGB(240, 240, 240))
        @top.setItemJustify(1, 0, FXTableItem::LEFT)
        @secgrp['group_id'] = x[:id].to_s
        @top.setItemText(2, 1, x[:id].to_s)
        @top.setItemJustify(2, 1, FXTableItem::LEFT)
        @top.setItemText(2, 0, "Group Id")
        #@top.setCellColor(2,0,FXRGB(240, 240, 240))
        @top.setItemJustify(2, 0, FXTableItem::LEFT)
        j = 0
        if y != nil
          if @ec2_main.settings.openstack_hp or @ec2_main.settings.openstack_rackspace
           y.each do |p|
                lists_0[j] = p["ip_protocol"]
   	      lists_1[j] = p["from_port"].to_s
   	      lists_2[j] = p["to_port"].to_s
   	      if p["ip_range"]["cidr"] != nil
   	         lists_3[j] = p["ip_range"]["cidr"]
   	      elsif  p["group"]["name"] != nil
   	         lists_3[j] = p["group"]["name"]
   	      end
   	      @rule_ids[j] = p["id"]
   	      j=j+1
   	   end
   	  else
            y.each do |p|
                lists_0[j] = p.ip_protocol
   	      lists_1[j] = p.from_port.to_s
   	      lists_2[j] = p.to_port.to_s
   	      if p.ip_range['cidr'] != nil
   	         lists_3[j] = p.ip_range['cidr']
   	      elsif  p.group['name'] != nil
   	         lists_3[j] = p.group['name']
   	      end
   	      @rule_ids[j] = p.id
   	      j=j+1
   	   end
   	  end
        end
        i = lists_0.length
        @table.clearItems
        @table.setTableSize(i, 4)
        @table.setColumnText(0,"Protocol")
	@table.setColumnWidth(0,100)
	@table.setColumnText(1,"From Port")
	@table.setColumnWidth(1,100)
	@table.setColumnText(2,"To Port")
	@table.setColumnWidth(2,100)
	@table.setColumnText(3,"Source (IP or Group)")
	@table.setColumnWidth(3,120)
        while i>0
           i = i-1
    	   @table.setItemText(i, 0, lists_0[i])
	   @table.setItemJustify(i, 0, FXTableItem::LEFT)
	   @table.setItemText(i, 1, lists_1[i])
	   @table.setItemJustify(i, 1, FXTableItem::RIGHT)
	   @table.setItemText(i, 2, lists_2[i])
	   @table.setItemJustify(i, 2, FXTableItem::RIGHT)
	   @table.setItemText(i, 3, lists_3[i])
	   @table.setItemJustify(i, 3, FXTableItem::RIGHT)
	end
	@curr_item = ""
	@curr_item_1 = ""
	@curr_item_2 = ""
	@curr_item_3 = ""
        @secgrp_loaded = true
        @ec2_main.app.forceRefresh
     end
  end


  def setType_ec2
     @type = "ec2"
  end

  def clear
        #@type = ""
        @secgrp['Security_Group'] = ""
        @secgrp['Description'] = ""
        @secgrp['vpc_id'] = ""
        @top.clearItems
        @table.clearItems
        @secgrp_loaded = false
        @ec2_main.app.forceRefresh
  end

  def delete
       secgrp_name = @secgrp['Security_Group']
       secgrp_id = @secgrp['group_id']
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Security Group "+secgrp_name)
       if answer == MBOX_CLICKED_YES
	     deleted = false
	     begin
	        deleted = @ec2_main.environment.security_group.delete(secgrp_id, secgrp_name )
                deleted = true
             rescue
                error_message("Security_Group Delete failed",$!)
             end
             if deleted
	        @ec2_main.treeCache.delete_secGrp(secgrp_name,@secgrp['vpc_id'])
	        @ec2_main.serverCache.delete_secGrp(secgrp_name,@secgrp['vpc_id'])
	        clear
	        @ec2_main.app.forceRefresh
	     end
       end
  end

 def enable_if_env_set(sender)
       @env = @ec2_main.environment.env
       if @env != nil and @env.length>0
       	 sender.enabled = true
       else
         sender.enabled = false
       end
 end

 def loaded
      return @secgrp_loaded
 end

 def enable_if_secgrp_loaded(sender)
       if loaded and !@ec2_main.settings.openstack_rackspace
           sender.enabled = true
       else
           sender.enabled = false
       end
 end

end

