def convert_time(t)
 if t == nil 
    return ""
 else
   #if t.class.to_s == "Fog::Time"
   tzone = ($ec2_main.settings.get_system('TIMEZONE')).upcase
   if tzone != "UTC"
     return (t.getlocal).to_s 
   else 
     return t.to_s
   end
 end   
end
