class EC2_Block_Mapping 

   def initialize
      @block_mapping = Array.new
      @curr_row = nil 
      
   end 

  def array
     return @block_mapping 
  end  

  def array_fog
       i=0
       data = Array.new
       @block_mapping.each do |m|
           if m != nil
              r= {}
              r['DeviceName']=m[:device_name]
              r['Ebs.SnapshotId']=m[:ebs_snapshot_id]
              r['Ebs.VolumeSize']=m[:ebs_volume_size].to_i
              r['VirtualName']=m[:virtual_name]
              r['Ebs.DeleteOnTermination']=m[:ebs_delete_on_termination]
              data[i]=r 
              i = i+1
           end   
        end
        return data
   end  

  def curr_row
      return @curr_row
   end

  def size
     return @block_mapping.size 
  end 

   def set_curr_row(a)
      @curr_row = a
      puts "Curr Row #{@curr_row}" 
   end

   def get
      @block_mapping[@curr_row]
   end

   def update(item)
     @block_mapping[@curr_row] = item
     puts "Curr Row #{@curr_row} Updated"
     puts @block_mapping[@curr_row]
   end  

   def push(item)
     @block_mapping.push(item)
   end 

   def delete
     @block_mapping.delete_at(@curr_row)
   end       
  
  def clear_init
     @block_mapping = Array.new
     @curr_row = nil
  end
  

  def clear(props,prop_text,field)
      i=0
      @block_mapping.each do |m|
         @block_mapping[i]=nil
         props["#{prop_text}_#{i}"]=nil
         i = i+1
      end
      @curr_row = nil
      load_table(field)
   end

  def save(props,prop_text)
       i=0
       @block_mapping.each do |m|
           if m != nil
              puts "#{i}  #{m}"
              props["#{prop_text}_#{i}"]="#{m[:device_name]};#{m[:virtual_name]};#{m[:ebs_snapshot_id]};#{m[:ebs_volume_size]};#{m[:ebs_delete_on_termination]}"
              i = i+1
           end   
        end
   end

   def load(r,field)
       @block_mapping = Array.new 
       # puts "field #{r[:field]}"
       if r[:block_device_mappings] != nil
          r[:block_device_mappings].each do |m|
            if m!= nil   
               puts "m #{m}"
               @block_mapping.push(m)
 	    end
 	  end 
       end
       load_table(field)      
  end
  
  def load_fog(r,field)
         @block_mapping = Array.new 
         # puts "field #{r[:field]}"
         if r[:block_device_mappings] != nil
            r[:block_device_mappings].each do |m|
              if m!= nil   
                 puts "m #{m}"
                 @block_mapping.push(m)
   	    end
   	  end 
         end
         load_table_fog(field)      
  end

  def load_from_properties(props,prop_text,field)
      i=0
      @block_mapping = Array.new
      while i<100
         if props["#{prop_text}_#{i}"]!=nil
            a = props["#{prop_text}_#{i}"].split(';')
            m = {}
            m[:device_name] = a[0]
            m[:virtual_name] = a[1]
            m[:no_device] = ""
            m[:ebs_snapshot_id] = a[2]
            m[:ebs_volume_size] = a[3]
            m[:ebs_delete_on_termination] = a[4]
            @block_mapping[i]=m
            props["#{prop_text}_#{i}"]=nil
         end   
         i = i+1
      end
      load_table(field)      
   end
   
   def load_table(field)
         field.clearItems
         field.rowHeaderWidth = 0	
         field.setTableSize(@block_mapping.size, 1)
         field.setColumnText(0, "Device Name;Virtual Name;Snapshot Id;Size;Delete On Termination") 
         field.setColumnWidth(0,350)
         i = 0
         @block_mapping.each do |m|
           if m!= nil 
              field.setItemText(i, 0, "#{m[:device_name]};#{m[:virtual_name]};#{m[:ebs_snapshot_id]};#{m[:ebs_volume_size]};#{m[:ebs_delete_on_termination]}")
              field.setItemJustify(i, 0, FXTableItem::LEFT)
              i = i+1
   	     end 
         end   
   end
   
   def load_table_fog(field)
            field.clearItems
            field.rowHeaderWidth = 0	
            field.setTableSize(@block_mapping.size, 1)
            field.setColumnText(0, "Device Name;Virtual Name;Snapshot Id;Size;Delete On Termination") 
            field.setColumnWidth(0,350)
            i = 0
            @block_mapping.each do |m|
              if m!= nil 
                 field.setItemText(i, 0, "#{m['DeviceName']};#{m['VirtualName']};#{m['Ebs.SnapshotId']};#{m['Ebs.VolumeSize']};#{m['Ebs.DeleteOnTermination']}")
                 field.setItemJustify(i, 0, FXTableItem::LEFT)
                 i = i+1
      	     end 
            end   
   end

end
