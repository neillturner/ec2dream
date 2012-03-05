
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_ParmGrpModifyDialog < FXDialogBox
      
  def initialize(owner, item, engine)
        puts "RDSParmGrpModifyDialog.initialize"
        @ec2_main = owner
        @modified = false
        @parm = Array.new
        @eng_parms = {}
        @db_parm_grp = item
        @curr_item = ""
        engine_parms(engine)
        super(owner, "Modify DB Parameter Group - "+@db_parm_grp+ " ("+engine+")", :opts => DECOR_ALL, :width => 800, :height => 600)
        frame1 = FXMatrix.new(self, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_ROW)
        frame2 = FXVerticalFrame.new(frame1, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 200, :height => 450)
        parmlist = FXList.new(frame2, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
	i = 0
	#puts @parm.size
	while i < @parm.size
	   #puts @parm[i]
	   parmlist.appendItem(@parm[i])
	   i = i+1
	end
        frame2 = FXVerticalFrame.new(frame1,LAYOUT_FILL, :padding => 0)
        frame3 = FXMatrix.new(frame2, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
        FXLabel.new(frame3, "Parameter Name" )
        parameter_name = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        FXLabel.new(frame3, "Value" )
        value = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        FXLabel.new(frame3, "Description" )
        description = FXText.new(frame3, :height => 50, :width => 366, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FIX_WIDTH|TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY, :padding => 0)
        FXLabel.new(frame3, "Source" )
        source = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        FXLabel.new(frame3, "Apply Type" )
        apply_type = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        FXLabel.new(frame3, "Data Type" )
        data_type = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
        FXLabel.new(frame3, "Allowed Values" )
        allowed_values = FXText.new(frame3, :height => 50,:width => 366, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FIX_WIDTH|TEXT_WORDWRAP|LAYOUT_FILL|TEXTFIELD_READONLY, :padding => 0)
        FXLabel.new(frame3, "Is Modifiable" )
        is_modifiable = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)	
        FXLabel.new(frame3, "Minimum Version" )
        minimum_version = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)	
	parmlist.connect(SEL_COMMAND) do |sender, sel, data|
	   selected_item = ""
	   @curr_item = ""
	   parmlist.each do |item|
	      selected_item = item.text if item.selected?
	   end
	   puts "item "+selected_item
	   if selected_item != nil and selected_item != ""
	      @curr_item = selected_item
	      r = @eng_parms[selected_item]
	      parameter_name.text = r[:name]
	      value.text = r[:value]
	      description.text = r[:description]
	      source.text = r[:source]
	      apply_type.text = r[:apply_type]
	      data_type.text = r[:data_type] 
	      allowed_values.text = r[:allowed_values]
	      is_modifiable.text = r[:is_modifiable].to_s
              minimum_version.text = r[:minimum_version]
	   end   
       end
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       FXHorizontalSeparator.new(frame3, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
       FXHorizontalSeparator.new(frame3, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "" )
       FXLabel.new(frame3, "DB Parameters (Maxiumum 20)", :opts => LAYOUT_CENTER_X )
       parameters_button = FXButton.new(frame3, "  >>  ", :opts => LAYOUT_CENTER_X|LAYOUT_CENTER_Y|BUTTON_NORMAL)
       parameters_button.tipText = "Select Parameter"
       parameters = FXText.new(frame3, :width => 450, :height => 150, :opts => LAYOUT_FIX_HEIGHT|LAYOUT_FIX_WIDTH|TEXT_WORDWRAP|LAYOUT_FILL, :padding => 0)
       parameters_button.connect(SEL_COMMAND) do
	  if @curr_item != nil and @curr_item != ""
	     r=@eng_parms[@curr_item]
	     if r[:is_modifiable] == true
	        v = ""
	        if r[:allowed_values] != nil and r[:allowed_values] != ""
	           v = r[:allowed_values]
	           if r[:apply_type] == "dynamic"
	              a = "immediate"
	           else
	              a = "pending-reboot"
	           end
	        else
	           if r[:data_type] != nil and r[:data_type] != ""
	              v = r[:data_type]
	              if r[:apply_type] == "dynamic"
	                 a = "immediate"
	              else
	                 a = "pending-reboot"
	              end
	           end
	        end   
	        if parameters.text == nil or parameters.text == ""
	           parameters.text = "name="+@curr_item + ",value=<"+v+">,applyMethod="+a
	        else   
                   parameters.text = parameters.text + ",\nname="+@curr_item + ",value=<"+v+">,applyMethod="+a
                end
             else
                error_message("Error","Parameter "+@curr_item+" cannot be modified")
             end 
	  end   
       end
	FXLabel.new(frame3, "" )
	FXLabel.new(frame3, "" )
        FXLabel.new(frame3, "" )
        modify = FXButton.new(frame3, "   &Modify   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        modify.connect(SEL_COMMAND) do |sender, sel, data|
           modify_db_parm_grp(parameters.text)
           if @modified == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
           end           
        end
  end 
  
  def engine_parms(engine)
      rds = @ec2_main.environment.rds_connection
      if rds != nil
         i=0
         ep = rds.describe_engine_default_parameters(engine)
         ep.each do |r|
            @parm[i] = r[:name]
            @eng_parms[r[:name]]=r
            i = i+1
         end
      end  
      @parm = @parm.sort
      return @parm
  end     
  
  def modify_db_parm_grp(parameters)
    modify_parm = {}
    message = ""
    pn = parameters.delete("\n")
    sa = pn.split(",")
    i = 0
    name=""
    value=""
    method=""
    sa.each do |r|
      puts "r #{r}" 
      ra = r.split("=")
      puts ra
      if ra.size>1
        if ra[0].downcase == "name"
           name = ra[1]
        end
        if ra[0].downcase == "value"
           value = ra[1]
        end
        if ra[0].downcase == "applymethod"
           method  = ra[1]
           if i < 20
              v = {}
              v[:value]=value
              v[:method]=method
              modify_parm[name]=v
              message = message + "name=#{name} value=#{value} applyMethod=#{method}\n"
              i = i+1
           end
           name=""
           value=""
           method=""           
        end        
      end  
    end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Modify DB Parameter Group "+@db_parm_grp,message)
    if answer == MBOX_CLICKED_YES
       rds = @ec2_main.environment.rds_connection
       if rds != nil
          begin
             r = rds.modify_db_parameter_group(@db_parm_grp, modify_parm)
             @modified = true
          rescue
             error_message("Modify DB Instance Failed",$!.to_s)
          end  
       end
    end 
  end 
  
  def modified
     @modified
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end