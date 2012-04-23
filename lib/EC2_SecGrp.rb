require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_SecGrp_AuthorizeDialog'
require 'dialog/RDS_SecGrp_AuthorizeDialog'
require 'dialog/EC2_SecGrp_RevokeDialog'
require 'dialog/RDS_SecGrp_RevokeDialog'
require 'dialog/EC2_SecGrp_SelectDialog'
require 'dialog/EC2_TagsAssignDialog'
require 'common/EC2_ResourceTags'

class EC2_SecGrp

  def initialize(owner)
        @ec2_main = owner
        @secgrp_loaded = false
        @type = ""
        @curr_item = ""
        @curr_item_1 = ""
        @curr_item_2 = ""
        @curr_item_3 = ""
        @secgrp = {}
    	@secgrp_tags = nil
    	@secgrp_tags_text =""        
        tab = FXTabItem.new(@ec2_main.tabBook, " SecGrp ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Refresh Security Group"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	    puts "server.refresh.connect"
	    if @secgrp_loaded == true
	       if @type == "ec2" or @type == "ops" 
	          @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'])
	          load(@secgrp['Security_Group'])
	       end   
	       if @type == "rds"
	          @ec2_main.serverCache.refresh_db_secGrps(@secgrp['Security_Group'])
	          load_rds(@secgrp['Security_Group'])
	       end
	    end   
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	@create_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create = @ec2_main.makeIcon("new.png")
	@create.create
	@create_button.icon = @create
	@create_button.tipText = "  Create Security Group "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	    create_type = 'linux'
	    if @type == "rds"
	       create_type = 'database'
	    end  
	    @secgrpdialog = EC2_SecGrpDialog.new(owner,create_type)
	    @secgrpdialog.execute
	    created = @secgrpdialog.created
	    if created
	       type = @secgrpdialog.type
	       created_secgrp = @secgrpdialog.sec_grp
	       if type == "database"
	          load_rds(created_secgrp)
	       else   
	          load(created_secgrp)
	       end   
	    end 	     
	end
	@create_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender)
	end
	@select_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)	
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@select_button.icon = @magnifier
	@select_button.tipText = "  Select Security Group  "
	@select_button.connect(SEL_COMMAND) do |sender, sel, data|
	   @secgrpseldialog = EC2_SecGrp_SelectDialog.new(owner,@type)
	   @secgrpseldialog.execute
	   selected = @secgrpseldialog.selected
	   if selected
	      type = @secgrpseldialog.type
	      selected_secgrp = @secgrpseldialog.sec_grp
	      if type == "database"
	         load_rds(selected_secgrp)
	      else   
	         load(selected_secgrp)
	      end   
	   end	
	end	
	@select_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
	
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@kill = @ec2_main.makeIcon("kill.png")
	@kill.create
	@delete_button.icon = @kill
	@delete_button.tipText = " Delete Security Group "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	    delete
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_secgrp_loaded(sender) 
	end
	@link_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link = @ec2_main.makeIcon("link.png")
	@link.create
	@link_button.icon = @link
        @link_button.tipText = "Make Authorisation"	
	@link_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type == "ec2"
	      linkdialog = EC2_SecGrp_AuthorizeDialog.new(@ec2_main,@secgrp['Security_Group'] )
	      linkdialog.execute
	      if linkdialog.created
	         @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'])
                 load(@secgrp['Security_Group'])
              end 
           elsif @type == "rds"
 	      linkdialog = RDS_SecGrp_AuthorizeDialog.new(@ec2_main,@secgrp['Security_Group'] )
	      linkdialog.execute
	      if linkdialog.created
	         @ec2_main.serverCache.refresh_db_secGrps(@secgrp['Security_Group'])
                 load_rds(@secgrp['Security_Group'])
              end   
           end
 	end
	@link_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @secgrp_loaded == true 
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end 
	end
	@link_break_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link_break = @ec2_main.makeIcon("link_break.png")
	@link_break.create
	@link_break_button.icon = @link_break
        @link_break_button.tipText = "Revoke Authorisation"
	@link_break_button.connect(SEL_COMMAND) do |sender, sel, data|
           if @type == "ec2"
	     if (@curr_item == nil or @curr_item == "") and (@curr_item_1 == nil or @curr_item_1 == "") and (@curr_item_2 == nil or @curr_item_2 == "") and (@curr_item_3 == nil or @curr_item_3 == "")
                error_message("No Authorization selected","No Authorization selected to revoke")
             else	   
	        deletedialog = EC2_SecGrp_RevokeDialog.new(@ec2_main,@secgrp['Security_Group'],@curr_item, @curr_item_1, @curr_item_2, @curr_item_3 )
	        if deletedialog.deleted
	           @ec2_main.serverCache.refresh_secGrps(@secgrp['Security_Group'])
	           load(@secgrp['Security_Group'])
	        end
	        @curr_item = ""
	        @curr_item_1 = ""
	        @curr_item_2 = ""
	        @curr_item_3 = ""
	     end   
	   elsif @type == "rds"
	     if (@curr_item == nil or @curr_item == "") and (@curr_item_1 == nil or @curr_item_1 == "") and (@curr_item_2 == nil or @curr_item_2 == "")
                error_message("No Authorization selected","No Authorization selected to revoke")
             else
	        deletedialog = RDS_SecGrp_RevokeDialog.new(@ec2_main,@secgrp['Security_Group'], @curr_item,@curr_item_1, @curr_item_2)
                if deletedialog.deleted
                   @ec2_main.serverCache.refresh_db_secGrps(@secgrp['Security_Group'])
                   load_rds(@secgrp['Security_Group'])
	           @curr_item = ""
	           @curr_item_1 = ""
	           @curr_item_2 = ""
	           @curr_item_3 = ""                   
                end	          
	     end	   
           end
	end
	@link_break_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @secgrp_loaded == true
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end 
	end
        @tag_red = @ec2_main.makeIcon("tag_red.png")
	@tag_red.create
        @tag_button = FXButton.new(page1a, "", :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @tag_button.icon = @tag_red
        @tag_button.tipText = "Edit Tags"
        @tag_button.connect(SEL_COMMAND) do
            dialog = EC2_TagsAssignDialog.new(@ec2_main,@secgrp['group_id'],@secgrp_tags)
            dialog.execute
            if dialog.saved
               load(@secgrp['Security_Group']) 
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
	   #if which.col == 0
	      @curr_item = @table.getItemText(which.row,0).to_s
	      @curr_item_1 = @table.getItemText(which.row,1).to_s
	      @curr_item_2 = @table.getItemText(which.row,2).to_s
	      if @type == "ec2"
	         @curr_item_3 = @table.getItemText(which.row,3).to_s
	      else
	         @curr_item_3 = ""
	      end
	      puts @curr_item
	      @table.selectRow(which.row)
	   #end 
	end  	
  end 
  
  def secgrpPanel(item)
      puts "secgrp.secgrpPanel"
      load(item.text)
  end 
  
  def load(sg)
    if @ec2_main.settings.get("EC2_PLATFORM") == "openstack"
       load_ops(sg)    
    else
       @type = "ec2"
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
       lists_0 = Array.new 
       lists_1 = Array.new
       lists_2 = Array.new
       lists_3 = Array.new
       groups_perm = Array.new
       x = @ec2_main.serverCache.secGrps(sg)
       if x != nil
          y = x[:aws_perms]
          puts "x #{x}"
          ec2 = @ec2_main.environment.connection
          ta = {}
          begin
             tx = ec2.describe_tags(:filters => {'resource-id' => x[:group_id]})
    	     puts tx
    	  rescue
    	  # not supported by eucalyptis
    	  end
    	     if tx != nil
    	        tx.each do |aws_tag|
    	           ta[aws_tag[:key]] = aws_tag[:value]
    	        end
    	     end
    	     if ta.size>0
   	        @secgrp_tags = EC2_ResourceTags.new(@ec2_main,ta,nil)
    	        @secgrp_tags_text = @secgrp_tags.show
    	     else
    	        @secgrp_tags = nil
    	        @secgrp_tags_text =""
    	     end            
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
             y.each do |p|
                o = "owner"
                puts p
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
  end 
  
  def load_ops(sg)
        @type = "ops"
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
        @secgrp['Description'] = ""
        @top.setItemText(1, 1, "")
        @top.setItemJustify(1, 1, FXTableItem::LEFT)
        @top.setItemText(1, 0, "Description")
        @top.setCellColor(1,0,FXRGB(240, 240, 240))
        @top.setItemText(2, 1, "")
        @top.setItemJustify(2, 1, FXTableItem::LEFT)
        @top.setItemText(2, 0, "")
        #@top.setCellColor(2,0,FXRGB(240, 240, 240))
        @top.setItemJustify(2, 0, FXTableItem::LEFT)
        @top.setItemText(3, 1, "")
        @top.setItemJustify(3, 1, FXTableItem::LEFT)
        @top.setItemText(3, 0, "")
        #@top.setCellColor(3,0,FXRGB(240, 240, 240))
        @top.setItemJustify(3, 0, FXTableItem::LEFT)
        @top.setItemText(4, 1, "")
        @top.setItemJustify(4, 1, FXTableItem::LEFT)
        @top.setItemText(4, 0, "")
        #@top.setCellColor(4,0,FXRGB(240, 240, 240))
        @top.setItemJustify(4, 0, FXTableItem::LEFT)         
        @table.clearItems
        @table.setTableSize(0, 4) 
  	@table.setColumnText(0,"Protocol")
  	@table.setColumnWidth(0,100)
  	@table.setColumnText(1,"From Port")
  	@table.setColumnWidth(1,100)
  	@table.setColumnText(2,"To Port")
  	@table.setColumnWidth(2,100) 
  	@table.setColumnText(3,"Source (IP or Group)")
  	@table.setColumnWidth(3,120)          
        @secgrp_loaded = true
        @ec2_main.app.forceRefresh
  end 
  
  def load_rds(sg)
     puts "load rds #{sg}"
     @type = "rds"
     @secgrp['Security_Group'] = sg
     @top.clearItems
     @top.setBackColor(FXRGB(240, 240, 240))     
     @top.setTableSize(2, 2)
     @top.setItemText(0, 1, sg)
     @top.setItemJustify(0, 1, FXTableItem::LEFT)
     @top.setColumnWidth(1,200)
     @top.setItemText(0, 0, "DB Security Group")
     @top.setItemJustify(0, 0, FXTableItem::LEFT)
     @top.setCellColor(0,0,FXRGB(240, 240, 240))
     id = @ec2_main.settings.get_system("AMAZON_ACCOUNT_ID")
        lists_0 = Array.new 
        lists_1 = Array.new
        lists_2 = Array.new
        lists_3 = Array.new        
        x = @ec2_main.serverCache.db_secGrps(sg)
        @secgrp['Description'] = x[:description]
        @top.setItemText(1, 1, x[:description])
        @top.setItemJustify(1, 1, FXTableItem::LEFT)
        @top.setItemText(1, 0, "Description")
        @top.setCellColor(1,0,FXRGB(240, 240, 240))
        @top.setItemJustify(1, 0, FXTableItem::LEFT)
        if x[:ec2_security_groups] != nil
            y = x[:ec2_security_groups]
            j = 0
            y.each do |p|

               if p[:owner_id] != nil and p[:owner_id] != ""
                  lists_0[j] = p[:owner_id]
               end
               lists_1[j] = p[:name]
               lists_2[j] = ""
               lists_3[j] = p[:status] 
               j=j+1
            end
         end
         if x[:ip_ranges] != nil
            y = x[:ip_ranges]            
            y.each do |p|
               puts "ip #{p}"
               lists_0[j] = ""
               lists_1[j] = ""
               lists_2[j] = p[:cidrip]
               lists_3[j] = p[:status]
               j=j+1
            end
         end   
         i = lists_0.length
         @table.clearItems
         @table.setTableSize(i, 4)
         @table.setColumnText(0,"Owner ID")
	 @table.setColumnWidth(0,100)         
	 @table.setColumnText(1,"EC2 SecGrps")
	 @table.setColumnWidth(1,100)
	 @table.setColumnText(2,"IPs")
	 @table.setColumnWidth(2,100)
	 @table.setColumnText(3,"Status")
	 @table.setColumnWidth(3,120)     
         while i>0
            i = i-1
            @table.setItemText(i, 0, lists_0[i])
	    @table.setItemJustify(i, 0, FXTableItem::LEFT)           
    	    @table.setItemText(i, 1, lists_1[i])
	    @table.setItemJustify(i, 1, FXTableItem::LEFT)
    	    @table.setItemText(i, 2, lists_2[i])
	    @table.setItemJustify(i, 2, FXTableItem::RIGHT)
	    @table.setItemText(i, 3, lists_3[i])
	    @table.setItemJustify(i, 3, FXTableItem::LEFT)
	 end
         @curr_item = ""
         @curr_item_1 = ""
	 @curr_item_2 = ""
	 @curr_item_3 = ""	 
     @secgrp_loaded = true
     @ec2_main.app.forceRefresh
  end  
  
  
  def setType_ec2
     @type = "ec2"
     if @ec2_main.settings.get("EC2_PLATFORM") == "openstack"
        @type = "ops"
     end
  end   
  
   def setType_rds
       @type = "rds"
  end 
  
  def clear
        #@type = ""
        @secgrp['Security_Group'] = ""
        @secgrp['Description'] = ""
        @top.clearItems
        @table.clearItems
        @secgrp_loaded = false
        @ec2_main.app.forceRefresh
  end 
  
  def delete
     if @type == "rds"
       delete_rds
     elsif @type == "ops"
       delete_ops
     else
       secgrp_name = @secgrp['Security_Group']
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Security Group "+secgrp_name)
       if answer == MBOX_CLICKED_YES
          ec2 = @ec2_main.environment.connection
	  if ec2 != nil
	     deleted = false
	     begin
	        if @ec2_main.settings.get("EC2_PLATFORM") == "amazon"
	           r = ec2.delete_security_group(:group_id => @secgrp['group_id'])
	        else
	           r = ec2.delete_security_group(:group_name => secgrp_name)
                end
                deleted = true
             rescue
                error_message("Security_Group Delete failed",$!.to_s)
             end
             if deleted 
	        clear
	        @ec2_main.treeCache.delete_secGrp(secgrp_name)
	        @ec2_main.serverCache.delete_secGrp(secgrp_name)
	        @ec2_main.app.forceRefresh
	     end 
  	  end
       end
     end   
  end
 
 def delete_ops
        secgrp_name = @secgrp['Security_Group']
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Security Group "+secgrp_name)
        if answer == MBOX_CLICKED_YES
           deleted = @ec2_main.serverCache.ops_secgrp.delete(secgrp_name)
           if !deleted
              error_message("Security_Group Delete failed",$!.to_s)
           end   
           if deleted 
 	      clear
 	      @ec2_main.treeCache.delete_secGrp(secgrp_name)
 	      @ec2_main.serverCache.delete_secGrp(secgrp_name)
 	      @ec2_main.app.forceRefresh
 	   end 
        end
  end
 
 
  def delete_rds
        secgrp_name = @secgrp['Security_Group']
        answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of DB Security Group "+secgrp_name)
        if answer == MBOX_CLICKED_YES
           rds = @ec2_main.environment.rds_connection
 	  if rds != nil
	     deleted = false
	     begin 
                r = rds.delete_db_security_group(secgrp_name)
                deleted = true
             rescue
                error_message("DB Security_Group Delete failed",$!.to_s)
             end	  
             if deleted 
	        clear
	        @ec2_main.treeCache.delete_db_secGrp(secgrp_name)
	        @ec2_main.serverCache.delete_db_secGrp(secgrp_name)
	        @ec2_main.app.forceRefresh
	     end 	  
   	  end
        end
  end
 
  def refreshSecGrpsTree(tree, secgrpBranch, doc, doc_script, securityGrps)
     i=0
     while i<securityGrps.size
      s=securityGrps[i]
      tree.appendItem(secgrpBranch, s, doc, doc)
      i = i+1
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
       if loaded
           sender.enabled = true
       else
           sender.enabled = false
       end 
 end
   
 def error_message(title,message)
       FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
 end
 
end

