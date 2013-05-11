
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_EIPAssociateDialog < FXDialogBox

  def initialize(owner, eip_address, allocation_id=nil, domain='standard')
    puts "EIPAssociateDialog.initialize"
    @ec2_main = owner
    server_instance = ""
    eip_address_available = false
    @created = false
    eip_servers = {}    
    super(owner, "Associate Address "+eip_address, :opts => DECOR_ALL, :width => 350, :height => 120)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    i = 0 
    j = 0
    k = 0
       @ec2_main.environment.addresses.all.each do |r|
           if r[:instance_id] == nil
    	      if eip_address == r[:public_ip]
    	         eip_address_available = true
    	      end  
    	      j = j+1
    	   else 
    	      eip_servers[r[:instance_id]] = r[:public_ip]
           end
           i = i+1
       end 
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Server" )
    itemlist = FXComboBox.new(frame1, 35,
          	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    sa = sa = @ec2_main.serverCache.instance_running_names(domain)
    i = 0
    while i<sa.length
      sia = (sa[i]).split"/"
      inst = ""
      if sia.size>1
         inst = sia[1]
      end     
      if eip_servers[inst] == nil 
         itemlist.appendItem(sa[i])
         if server_instance == ""
            server_instance = sa[i]
         end
      end   
      i=i+1
    end
    itemlist.numVisible = 10
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      server_instance = data
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Associate   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if eip_address == nil or eip_address == ""
         error_message("Error","IP Address Address not selected")
       else
         if server_instance == nil or server_instance == ""
           error_message("Error","Server not selected")
         else
           associate_eip(eip_address, server_instance, allocation_id)
           if @created == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
           end   
         end
       end  
    end
  end 
  
  def associate_eip(eip_address, server_instance, allocation_id=nil)
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Associate  of "+eip_address+" To Instance "+server_instance)
     sia = (server_instance).split"/" 
     if sia.size>1
       server_instance = sia[1]
     end 
     if answer == MBOX_CLICKED_YES
        begin 
          r = @ec2_main.environment.addresses.associate(server_instance, eip_address, nil, allocation_id)
          @created = true
        rescue
          error_message("Asociate IP Address failed",$!)
        end
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