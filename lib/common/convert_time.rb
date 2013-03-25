def convert_time(t)

 if t == nil 
    return ""
 else
   if t.class.to_s == "Fog::Time"
    t = t.to_iso8601_basic
   end  
   tzone = $ec2_main.settings.get_system('TIMEZONE')
   if tzone != "UTC"
      tz = TZInfo::Timezone.get(tzone)
      t = tz.utc_to_local(DateTime.new(t[0,4].to_i,t[5,2].to_i,t[8,2].to_i,t[11,2].to_i,t[14,2].to_i,t[17,2].to_i)).to_s
   end
   k = t.index("T")
   if k != nil and k> 0
      t[k] = " "
   end
   k = t.index("Z")
   if k != nil and k> 0
      t[k] = " "
   end
   return t
 end   
end
