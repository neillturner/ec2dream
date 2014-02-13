class GOG_Firewall_Mapping 

   def initialize
      @firewall_mapping = []
      @curr_row = nil 
      
   end 

  def array
     return @firewall_mapping 
  end  

 # def array_fog
 #      i=0
 #      data = Array.new
 #      @firewall_mapping.each do |m|
 #          if m != nil
 #             r= {}
 #             r['IPProtocol']=m['IPProtocol']
 #             r['ports']=m['ports']
 #             data[i]=r 
 #             i = i+1
 #          end   
 #       end
 #       return data
 #  end  

  def curr_row
      return @curr_row
   end

  def size
     return @firewall_mapping.size 
  end 

   def set_curr_row(a)
      @curr_row = a
      puts "Curr Row #{@curr_row}" 
   end

   def get
      @firewall_mapping[@curr_row]
   end

   def update(item)
     @firewall_mapping[@curr_row] = item
     puts "Curr Row #{@curr_row} Updated"
     puts @firewall_mapping[@curr_row]
   end  

   def push(item)
     @firewall_mapping.push(item)
   end 

   def delete
     @firewall_mapping.delete_at(@curr_row)
   end       
  
  def clear_init
     @firewall_mapping = []
     @curr_row = nil
  end
  
 
  
 # def load(r,field)
 #      @firewall_mapping = Array.new 
 #      # puts "field #{r[:field]}"
 #      if r[:firewall_device_mappings] != nil
 #         r[:firewall_device_mappings].each do |m|
 #           if m!= nil   
 #              puts "m #{m}"
 #              @firewall_mapping.push(m)
# 	    end
 #	  end 
 #      end
 #      load_table(field)      
 # end
  
 # def load_fog(r,field)
 #        @firewall_mapping = Array.new 
 #        # puts "field #{r[:field]}"
 #        if r[:firewall_device_mappings] != nil
 #           r[:firewall_device_mappings].each do |m|
 #             if m!= nil   
 #                puts "m #{m}"
 #                @firewall_mapping.push(m)
 #  	    end
 #  	  end 
 #        end
 #        load_table_fog(field)      
 # end

   def load_table(field)
         field.clearItems
         field.rowHeaderWidth = 0	
         field.setTableSize(@firewall_mapping.size, 1)
         field.setColumnText(0, "IPProtocol;ports") 
         field.setColumnWidth(0,350)
         i = 0
         @firewall_mapping.each do |m|
           if m!= nil 
              field.setItemText(i, 0, "#{m['IPProtocol']};#{m['ports']}")
              field.setItemJustify(i, 0, FXTableItem::LEFT)
              i = i+1
   	     end 
         end   
   end
   
 end
