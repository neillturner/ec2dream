require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

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
      data.push('t2.micro       (1 vCPU, 6 CPU Credits, 1GB Mem, EBS Only)')
      data.push('t2.small       (1 vCPU, 12 CPU Credits, 2GB Mem, EBS Only)')
      data.push('t2.medium      (2 vCPU, 24 CPU Credits, 4GB Mem, EBS Only)')
      data.push('t2.large       (2 vCPU, 36 CPU Credits, 8GB Mem, EBS Only)')
      data.push('m4.large       (2 vCPU, 8GB Mem, 450 Mbps)')
      data.push('m4.xlarge      (4 vCPU, 16GB Mem, 750 Mbps)')
      data.push('m4.2xlarge     (8 vCPU, 32GB Mem, 1000 Mbps)')
      data.push('m4.4xlarge     (16 vCPU, 64GB Mem, 2000 Mbps)')
      data.push('m4.10xlarge    (40 vCPU, 160GB Mem, 4000 Mbps)')
      data.push('m3.medium      (1 vCPU, 3.75GB Mem, 1 x 4GB SSD)')
      data.push('m3.large       (2 vCPU, 7.5GB Mem, 1 x 32GB SSD )')
      data.push('m3.xlarge      (4 vCPU, 15GB Mem, 2 x 40GB SSD)')
      data.push('m3.2xlarge     (8 vCPU, 30GB Mem, 2 x 80GB SSD)')
      data.push('c4.large       (2 vCPU, 3.75GB Mem, 500 Mbps)')
      data.push('c4.xlarge      (4 vCPU, 7.5GB Mem, 750 Mbps)')
      data.push('c4.2xlarge     (8 vCPU, 15GB Mem, 1000 Mbps)')
      data.push('c4.4xlarge     (16 vCPU, 30GB Mem, 2000 Mbps)')
      data.push('c4.8xlarge     (36 vCPU, 60GB Mem, 4000 Mbps)')
      data.push('c3.large       (2 vCPU, 3.75GB Mem, 2 x 16GB SSD)')
      data.push('c3.xlarge      (4 vCPU, 7.5GB Mem, 2 x 40GB SSD)')
      data.push('c3.2xlarge     (8 vCPU, 15GB Mem, 2 x 80GB SSD)')
      data.push('c3.4xlarge     (16 vCPU, 30GB Mem, 2 x 160GB SSD)')
      data.push('c3.8xlarge     (32 vCPU, 60GB Mem, 2 x 320GB SSD)')
      data.push('r3.large       (2 vCPU, 15.25GB Mem, 1 x 32GB SSD)')
      data.push('r3.xlarge      (4 vCPU, 30.5GB Mem, 1 x 80GB SSD)')
      data.push('r3.2xlarge     (8 vCPU, 61GB Mem, 1 x 160GB SSD)')
      data.push('r3.4xlarge     (16 vCPU, 122GB Mem, 1 x 320GB SSD)')
      data.push('r3.8xlarge     (32 vCPU, 244GB Mem, 2 x 320GB SSD)')
      data.push('g2.2xlarge     (8 vCPU, 15GB Mem, 1 x 60GB SSD)')
      data.push('g2.8xlarge     (32 vCPU, 60GB Mem, 2 x 120GB SSD)')
      data.push('i2.xlarge      (4 vCPU, 30.5GB Mem, 1 x 800GB SSD)')
      data.push('i2.2xlarge     (8 vCPU, 61GB Mem, 2 x 800GB SSD)')
      data.push('i2.4xlarge     (16 vCPU, 122GB Mem, 4 x 800GB SSD)')
      data.push('i2.8xlarge     (32 vCPU, 244GB Mem, 8 x 800GB SSD)')
      data.push('d2.xlarge      (4 vCPU, 30.5GB Mem, 3 x 2000 HDD)')
      data.push('d2.2xlarge     (8 vCPU, 61GB Mem, 6 x 2000 HDD)')
      data.push('d2.4xlarge     (16 vCPU, 122GB Mem, 12 x 2000 HDD)')
      data.push('d2.8xlarge     (32 vCPU, 244GB Mem, 24 x 2000 HDD)')
    end
    return data
  end
end
