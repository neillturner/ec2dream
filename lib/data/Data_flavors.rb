require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_flavors 

  def initialize(owner)
     puts "Data_flavors.initialize"
     @ec2_main = owner  
  end 

  # List Instance Types or Flavours
  #
  # Returns a array of strings containing instance types or flavor in openstack terminology
  #
  def all
      data = []
      if @ec2_main.settings.openstack 
        conn = @ec2_main.environment.connection
        if conn != nil
           begin 
              x = conn.flavors.all
               x.each do |y|
                 vcpu = nil
                 begin 
                  vcpu = y.vcpus
                 rescue
                  vcpu = nil 
                 end
                 if vcpu != nil 
                    data.push("#{y.id}  (#{y.name}    Mem: #{y.ram}MB     Disk: #{y.disk}GB   VCPU: #{y.vcpus}VCPUs)")
                 else
                    data.push("#{y.id}  (#{y.name}    Mem: #{y.ram}MB     Disk: #{y.disk}GB)")                 
                 end
              end
           rescue
              puts "ERROR: getting all flavors  #{$!}"
           end
        else 
           raise "Connection Error"   
        end 
      elsif @ec2_main.settings.google 
        conn = @ec2_main.environment.connection
        if conn != nil
           begin 
              response = conn.list_machine_types($google_zone)
			  if response.status == 200
	             x = response.body['items']
	             x.each do |r|
				    data.push("#{r['name']}  ( Mem: #{r['memoryMb']}MB     Disks: #{r['maximumPersistentDisks']} Disk Size: #{r['maximumPersistentDisksSizeGb']}GB   CPUs: #{r['guestCpus']})")
 	            end
	          else
	      	     data = []
              end
            rescue
              puts "ERROR: getting all flavors  #{$!}"
           end
        else 
           raise "Connection Error"   
        end 		
	  else 
         data.push('t1.micro             (EBS only Micro 32 or 64-bit, 613 MB, up to 2 compute unit)')    
         data.push('m1.small            (Small 32 or 64-bit, 1.7 GB, 1 compute unit)')
         data.push('m1.medium       (Medium 32 or 64-bit, 3.75 GB, 2 compute unit)')
         data.push('m1.large             (Large 64-bit, 7.5 GB, 4 compute unit)')
         data.push('m1.xlarge           (Extra Large 64-bit, 15 GB, 8 compute unit)')
         data.push('m3.xlarge           (EBS Only Extra Large 64-bit, 15 GB, 13 compute unit)')
         data.push('m3.2xlarge         (EBS Only Extra Double Large 64-bit, 30 GB, 26 compute unit)')
         data.push('m2.xlarge          (High Memory Extra Large 64-bit, 17.1 GB, 6.5 compute unit)')
         data.push('m2.2xlarge         (High Memory Double Extra Large 64-bit, 34.2 GB, 13 compute unit)')
         data.push('m2.4xlarge         (High Memory Quadruple Large 64-bit, 68.4 GB, 26 compute unit)')
         data.push('c1.medium        (Compute optimized CPU Medium 32 or 64-bit, 1.7 GB, 5 compute unit)')
         data.push('c1.xlarge            (Compute optimized CPU Extra Large 64-bit, 7 GB, 20 compute unit)')
         data.push('c3.xlarge          (Compute optimized Extra Large 64-bit, 3.75 GB, 7 compute unit)')
         data.push('c3.2xlarge         (Compute optimized Double Extra Large 64-bit, 7 GB, 14 compute unit)')
         data.push('c3.4xlarge         (Compute optimized Quadruple Large 64-bit, 15 GB, 28 compute unit)')	
         data.push('c3.8xlarge         (Compute optimized Eight Large 64-bit, 30 GB, 55 compute unit)')
         data.push('i2.xlarge		   (High I/O   1x800 GB SSD, 30.5 GB, 14 compute unit)')
         data.push('i2.2xlarge		   (High I/O   2x800 GB SSD, 61 GB, 27 compute unit)')
         data.push('i2.4xlarge		   (High I/O   4x800 GB SSD, 122 GB, 53 compute unit)')
         data.push('i2.8xlarge	 	   (High I/O   8x800 GB SSD, 244 GB, 104 compute unit)')		 
         data.push('cc1.4xlarge        (Cluster Compute Quadruple Extra Large  64-bit, 23 GB, 33.5 compute unit. 10GBit network)')
         data.push('cc2.8xlarge        (Cluster Compute Eight Extra Large  64-bit, 60.5 GB, 88 compute unit. 10GBit network)')
		 data.push('g2.2xlarge         (Cluster GPU Quadruple Extra Large  64-bit, 15 GB, 26compute unit.)') 
         data.push('cg1.4xlarge        (Cluster GPU Quadruple Extra Large  64-bit, 22 GB, 33.5 compute unit. 10GBit network)')      
         data.push('hi1.4xlarge        (High I/O Quadruple Extra Large 64-bit, 60.5 GB, 2x1024GB SSD, 35 compute unit. 10GBit network)')
		 data.push('hs1.8xlarge        (High I/O Quadruple Extra Large 64-bit, 117 GB, 24x2048GB SSD, 35 compute unit. 10GBit network)')
        		
      end   
      return data
  end
 
 end