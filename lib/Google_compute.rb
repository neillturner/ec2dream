require 'fog'

class Google_compute 

def initialize()
  @conn = {} 
  data = File.read("#{ENV['EC2DREAM_HOME']}/lib/google_compute_config.json")
  @config = JSON.parse(data)
end

def api 
   'goggle'
end

def name 
   'google'
end   

def config
 @config
end

def conn(type) 
  #Fog.mock!
  if @conn[type] == nil
    begin
     puts "Connecting to Google #{type} for project #{$ec2_main.settings.get('EC2_URL')} google_client_email #{$ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')} google_key_location #{$ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY')}"
     case type
	  when 'Compute'
	     ENV['SSL_CERT_FILE'] = "#{ENV['EC2DREAM_HOME']}/google/cacert.pem" 
         @conn[type] = Fog::Compute.new({:provider => "Google",:google_client_email  => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :google_key_location =>  $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :google_project   => $ec2_main.settings.get('EC2_URL')})
         $google_zone = $ec2_main.settings.get('AVAILABILITY_ZONE')	
         i=$google_zone.rindex('-')
		 $google_region=$google_zone[0..i-1]
         puts "Google Region #{$google_region}"		 
 	  else 
	    $google_zone = nil
        nil
     end
    rescue
       reset_connection
       puts "ERROR: on #{type} connection to Google Compute Engine #{$!}"
       puts "check your keys in environment"
    end  	
  else
    @conn[type]
  end
end 

def reset_connection 
   @conn = {} 
end

end