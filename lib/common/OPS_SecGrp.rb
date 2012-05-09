require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

class OPS_SecGrp 

  def initialize(owner)
     puts "OPS_SecGrp initialize"
     @secgrp_folder = "ops_secgrp"
     @secgrp = "secgrp"
     @ec2_main = owner  
  end 
  
  def all
    sg_dir = "#{@ec2_main.settings.get_system('ENV_PATH')}/#{@secgrp_folder}"
    puts "sg dir #{sg_dir}"
    sec_grp = Array.new
    if File.directory? sg_dir
       sec_grp = Dir.entries(sg_dir)
    end
    sec_grp.delete(".")
    sec_grp.delete("..")
    sec_grp.each_index do |i|
       if sec_grp[i][-11..-1] == '.properties'
          sec_grp[i] = sec_grp[i][0..-12]
       end   
    end   
    puts "found openstack security group #{sec_grp}"
    return sec_grp
  end
  
  def create(sec_group,desc)
    puts "OPS_SecGrp create #{sec_group}"
    response = false
    sg_dir = "#{@ec2_main.settings.get_system('ENV_PATH')}/#{@secgrp_folder}"
    puts "Checking for folder #{sg_dir}"
    if !File.directory? sg_dir
       puts "creating....#{sg_dir}"
       Dir.mkdir(sg_dir)
    end
    fn = @ec2_main.settings.get_system('ENV_PATH')+"/#{@secgrp_folder}/#{sec_group}.properties"
    puts "writing #{fn}"
    doc = "#{sec_group}"
    begin
       File.open(fn, "w") do |f|
          f.write(doc)
       end
       puts "openstack secgrp create false"
       response = true
    rescue
       puts "openstack secgrp create false"
       response = false      
    end       
    return response 
  end

  def delete(sec_group)
    response = false
    sg_dir = "#{@ec2_main.settings.get_system('ENV_PATH')}/#{@secgrp_folder}"
    fn = @ec2_main.settings.get_system('ENV_PATH')+"/#{@secgrp_folder}/#{sec_group}.properties"
    begin
       File.delete(fn)
       response = true
    rescue
       puts "openstack secgrp delete false"
       response = false      
    end       
    return response 
  end


end