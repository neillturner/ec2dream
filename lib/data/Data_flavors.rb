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
      if !@ec2_main.settings.openstack 
         data.push('t1.micro             (EBS only Micro 32 or 64-bit, 613 MB, up to 2 compute unit)')    
         data.push('m1.small            (Small 32 or 64-bit, 1.7 GB, 1 compute unit)')
         data.push('m1.medium       (Medium 32 or 64-bit, 3.75 GB, 2 compute unit)')
         data.push('m1.large             (Large 64-bit, 7.5 GB, 4 compute unit)')
         data.push('m1.xlarge           (Extra Large 64-bit, 15 GB, 8 compute unit)')
         data.push('m3.xlarge         (EBS Only Extra Large 64-bit, 15 GB, 13 compute unit)')
         data.push('m3.2xlarge         (EBS Only Extra Double Large 64-bit, 30 GB, 26 compute unit)')
         data.push('m2.2xlarge         (High Memory Extra Large 64-bit, 17.1 GB, 6.5 compute unit)')
         data.push('m2.4xlarge         (High Memory Double Extra Large 64-bit, 34.2 GB, 13 compute unit)')
         data.push('c1.medium        (High CPU Medium 32 or 64-bit, 1.7 GB, 5 compute unit)')
         data.push('c1.xlarge            (High CPU Extra Large 64-bit, 7 GB, 20 compute unit)')
         data.push('cc1.4xlarge        (Cluster Compute Quadruple Extra Large  64-bit, 23 GB, 33.5 compute unit. 10GBit network)')
         data.push('cc2.8xlarge        (Cluster Compute Eight Extra Large  64-bit, 60.5 GB, 88 compute unit. 10GBit network)')
         data.push('cg1.4xlarge        (Cluster GPU Quadruple Extra Large  64-bit, 22 GB, 33.5 compute unit. 10GBit network)')      
         data.push('hi1.4xlarge        (High I/O Quadruple Extra Large 64-bit, 22 GB, 2x1024GB SSD, 35 compute unit. 10GBit network)')
       else  
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
              puts "**Error getting all flavors  #{$!}"
           end
        else 
           raise "Connection Error"   
        end   
      end   
      return data
  end
 
 end