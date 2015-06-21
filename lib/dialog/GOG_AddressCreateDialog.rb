require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_AddressCreateDialog < FXDialogBox

  def initialize(owner)
    puts "AddressCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    @address_name = ""
    super(owner, "Create Address", :opts => DECOR_ALL, :width => 700, :height => 150)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Address Name" )
    name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
      if name.text == nil or name.text == ""
        error_message("Error","Address Name not specified")
      else
        @address_name = name.text
        create_address(name.text)
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil) if @created == true
      end  
    end
    cancel = FXButton.new(frame2, "   &Cancel   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
  end 
  def create_address(name)
    begin 
      r = @ec2_main.environment.addresses.insert_address(name,$google_region)
      @created = true
    rescue
      error_message("Create Address Failed",$!)
    end 
  end 
  def address
    address = ""
    # this does not return address must be google bug
    #begin 
    #  puts "*** address name #{@address_name} "
    #  r = @ec2_main.environment.addresses.get_address(@address_name,$google_region)
    #  puts "*** address r #{r} "
    #  address = r['address'] if r != nil
    #rescue 
    #end
    sleep 3 
    r = []	
    begin 
      r = @ec2_main.environment.addresses.all
    rescue
      return address
    end 
    puts "*** address name #{@address_name}"
    puts "*** address r #{r} "
    r.each do |e|
      puts "*** address e #{r} "
      address = e['address'] if e['name'] == @address_name 
    end     	
    puts "*** address #{address}"
    return address
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
