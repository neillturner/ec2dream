require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_keypairs 

  def initialize(owner)
     puts "Data_keypairs.initialize"
     @ec2_main = owner  
  end 

  # Retrieve a list of SSH keys.
  #
  # Returns an array of keys or an exception. Each key is represented as a two-element hash.
  #
  #  ec2.describe_key_pairs #=>
  #    [{:aws_fingerprint=> "01:02:03:f4:25:e6:97:e8:9b:02:1a:26:32:4e:58:6b:7a:8c:9f:03", :aws_key_name=>"key-1"},
  #     {:aws_fingerprint=> "1e:29:30:47:58:6d:7b:8c:9f:08:11:20:3c:44:52:69:74:80:97:08", :aws_key_name=>"key-2"},
  #      ..., {...} ]  
  def all
      data = []
      conn = @ec2_main.environment.connection
      if conn != nil
         begin 
            if @ec2_main.settings.openstack         
               x = conn.key_pairs.all
               x.each do |y|
                  r= {}
                  r[:aws_key_name] = y.name 
                  r[:aws_fingerprint] = y.fingerprint
                   data.push(r)
               end
            elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
               x = conn.key_pairs.all
               x.each do |y|
	          r = {}
                  r[:aws_key_name] = y.name 
                  r[:aws_fingerprint] = y.fingerprint
                  data.push(r)
               end 
            else                     
               data = conn.describe_key_pairs
            end   
         rescue
            puts "ERROR: getting all key pairs  #{$!}"
         end
      end   
      return data
  end
 
 # not used
  def get(key_pair_name) 
      data = {}
      conn = @ec2_main.environment.connection
      if conn != nil
         data = conn.key_pairs.get(key_pair_name)
      else 
         raise "Connection Error"
      end
      return data
  end 
 
  # Create new SSH key. Returns a hash of the key's data or an exception.
  #
  #  ec2.create_key_pair('my_awesome_key') #=>
  #    {:aws_key_name    => "my_awesome_key",
  #     :aws_fingerprint => "01:02:03:f4:25:e6:97:e8:9b:02:1a:26:32:4e:58:6b:7a:8c:9f:03",
  #     :aws_material    => "-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAK...Q8MDrCbuQ=\n-----END RSA PRIVATE KEY-----"}
  # NOTE: For Openstack returns 'private_key' instead of :aws_material   
  def create(key_name, public_key = nil)
      data = nil
      conn = @ec2_main.environment.connection
      if conn != nil
         if  @ec2_main.settings.openstack 
            response = conn.create_key_pair(key_name, public_key)
             if response.status == 200
	       data = response.body["keypair"]
	    else   
	       data = nil
	    end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	    response = conn.create_key_pair(key_name)
            if response.status == 200
              response = response.body
              data = {}
              data[:aws_key_name] = response['keyName']
	      data[:aws_fingerprint] = response['keyFingerprint']
	      data[:aws_material] = response['keyMaterial']
	    else
	      data = {}
            end 	    
         else   	    
            data = conn.create_key_pair(key_name)
         end
      else 
         raise "Connection Error"
      end
      return data
  end 

  # Delete a key pair. Returns +true+ or an exception.
  #
  #  ec2.delete_key_pair('my_awesome_key') #=> true
  #  
  def delete(key_name)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack 
           response = conn.delete_key_pair(key_name)
           if response.status == 202
	      data = true
	   else   
	      data = false
	   end
	elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	    response = conn.delete_key_pair(key_name)
            if response.status == 200
              data = true
	    else
	      data = false
            end 	    	   
        else    	   	   
           data = conn.delete_key_pair(key_name)
        end
     else 
        raise "Connection Error"
     end
     return data
  end   
  
  
 end