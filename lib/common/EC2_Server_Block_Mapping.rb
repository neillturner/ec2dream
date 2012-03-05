class EC2_Server_Block_Mapping 

   def initialize
      @block_mapping = Array.new
      @curr_row = 0
   end 

   def curr_row
      return @curr_row
   end

   def set_curr_row(a)
      @curr_row = a
   end
  
  def clear(field)
      @block_mapping = Array.new
      @curr_row = 0
      field.clearItems
  end

  def load(r,field)
       @block_mapping = Array.new 
       if r[:block_device_mappings] != nil
          r[:block_device_mappings].each do |m|
            if m!= nil      
               @block_mapping.push(m)
 	    end
 	  end 
       end
       load_table(field)      
  end

  def load_table(field)
          field.clearItems
          field.rowHeaderWidth = 0	
          field.setTableSize(@block_mapping.size, 1)
          field.setColumnText(0, "Device Name;Volume;Attach Time;Status;Size;Delete On Termination") 
          field.setColumnWidth(0,350)
          i = 0
          @block_mapping.each do |m|
            if m!= nil 
               field.setItemText(i, 0, "#{m[:device_name]};#{m[:ebs_volume_id]};#{m[:ebs_attach_time]};#{m[:ebs_status]};#{m[:ebs_volume_size]};#{m[:ebs_delete_on_termination]}")
               field.setItemJustify(i, 0, FXTableItem::LEFT)
               i = i+1
    	      end 
          end   
  end

end
