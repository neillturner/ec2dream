require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fileutils'

include Fox

class EC2_ImageCache

  def initialize(owner)
    @ec2_main = owner
    @image_all = Array.new
    @image_self = Array.new
    @image_small = Array.new
    @image_large = Array.new
    @image_ebs = Array.new
    @image_ebs_small = Array.new
    @image_ebs_large = Array.new
    @image_instance = Array.new
    @image_instance_small = Array.new
    @image_instance_large = Array.new
    @status = "empty"
  end
  def load
    @status = "loading"
    env_name = @ec2_main.environment.env
    cache_filename = @ec2_main.settings.get_system("REPOSITORY_LOCATION")+"/"+env_name+"/image_cache.txt"
    cache_self_filename = @ec2_main.settings.get_system("REPOSITORY_LOCATION")+"/"+env_name+"/image_cache_self.txt"
    if !File.exist?(cache_filename)
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Load Image Cache","Do you wish to load the public image cache (this is will take several minutes but without the cache no public images can be listed)?")
      if answer == MBOX_CLICKED_NO
        puts "*********************************************************************"
        puts "*** No ImageCache Loading so unable to list any public images     ***"
        puts "*********************************************************************"
        @status = "empty"
        return
      end
    end
    if File.exist?(cache_filename)
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Existing Cache","Do you wish to use the existing public image cache (it takes several minutes to reload the cache)?")
      if answer == MBOX_CLICKED_NO
        File.delete(cache_filename)
        begin
          File.delete(cache_self_filename)
        rescue
        end
      end
    end
    if !File.exist?(cache_filename)
      puts "*********************************************************************"
      puts "*** ImageCache Loading. This could take a few minutes             ***"
      puts "*** but once loaded it will be much quicker searching for images  ***"
      puts "*********************************************************************"
      puts "Creating Image Cache File #{cache_filename}...."
      doc = ""
      doc_self = ""
      acct_no = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
      #ec2.describe_images_by_executable_by("all").each do |r|
      x=@ec2_main.environment.images.find_by_executable("all")
      x.each do |r|
        if @ec2_main.settings.openstack and acct_no ==  r["owner_id"]
          doc_self = doc_self + "#{r['imageId']},#{r['architecture']},#{r['rootDeviceType']},#{r['imageLocation']}\n"
        else
          doc = doc + "#{r['imageId']},#{r['architecture']},#{r['rootDeviceType']},#{r['imageLocation']}\n"
        end
      end
      File.open( cache_filename, "w") do |f|
        f.write(doc)
        f.close
      end
      File.open( cache_self_filename, "w") do |f|
        f.write(doc_self)
        f.close
      end
    end
    @image_all = Array.new
    @image_self = Array.new
    @image_small = Array.new
    @image_large = Array.new
    @image_ebs = Array.new
    @image_ebs_small = Array.new
    @image_ebs_large = Array.new
    @image_instance = Array.new
    @image_instance_small = Array.new
    @image_instance_large = Array.new
    cache_file = File.new(cache_filename, "r")
    puts "Reading Image Cache File #{cache_filename}...."
    while (line = cache_file.gets)
      sa = (line).split","
      r = {}
      r['imageId'] = sa[0].strip
      r['architecture'] = sa[1].strip
      r['rootDeviceType'] = sa[2].strip
      r['imageLocation']  = sa[3].strip
      @image_all.push(r['imageLocation']+"  ("+r['imageId']+")")
      if r['architecture'] == "i386"
        @image_small.push(r['imageLocation']+"  ("+r['imageId']+")")
      else
        @image_large.push(r['imageLocation']+"  ("+r['imageId']+")")
      end
      if r['rootDeviceType'] == "ebs" or  r['rootDeviceType'] == "snapshot"
        @image_ebs.push(r['imageLocation']+"  ("+r['imageId']+")")
        if r['architecture'] == "i386"
          @image_ebs_small.push(r['imageLocation']+"  ("+r['imageId']+")")
        else
          @image_ebs_large.push(r['imageLocation']+"  ("+r['imageId']+")")
        end
      else
        @image_instance.push(r['imageLocation']+"  ("+r['imageId']+")")
        if r['architecture'] == "i386"
          @image_instance_small.push(r['imageLocation']+"  ("+r['imageId']+")")
        else
          @image_instance_large.push(r['imageLocation']+"  ("+r['imageId']+")")
        end
      end
    end
    cache_file.close
    if @ec2_main.settings.openstack
      cache_file = File.new(cache_self_filename, "r")
      puts "Reading Image Cache File #{cache_self_filename}...."
      while (line = cache_file.gets)
        sa = (line).split","
        r = {}
        r['imageId'] = sa[0].strip
        r['architecture'] = sa[1].strip
        r['rootDeviceType'] = sa[2].strip
        r['imageLocation'] = sa[3].strip
        @image_self.push(r['imageLocation']+"  ("+r['imageId']+")")
      end
      cache_file.close
      @image_self = @image_self.sort
    end
    @image_all = @image_all.sort
    @image_ebs = @image_ebs.sort
    @image_instance = @image_instance.sort
    @image_small = @image_small.sort
    @image_large = @image_large.sort
    @image_ebs_small = @image_ebs_small.sort
    @image_ebs_large = @image_ebs_large.sort
    @image_instance_small = @image_instance_small.sort
    @image_instance_large = @image_instance_large.sort
    @status = "loaded"

    puts "ImageCache Loaded"
    puts "#{@image_all.size} All Images"
    puts "#{@image_self.size} Self Images"
    puts "#{@image_ebs.size} Ebs Images"
    puts "#{@image_instance.size} Instance Images"
    puts "#{@image_small.size} All Small Images"
    puts "#{@image_large.size} All Large Images"
    puts "#{@image_ebs_small.size} Ebs Small Images"
    puts "#{@image_ebs_large.size} Ebs Large Images"
    puts "#{@image_instance_small.size} Instance Small Images"
    puts "#{@image_instance_large.size} Instance Large Images"
  end

  def get(search,arch,root_device=nil,owner=nil)
    puts "ImageCache.get(#{search},#{arch},#{root_device},#{owner})"
    #while @status != "loaded" and @status != "empty"
    #  sleep 10
    #end
    if owner != nil and owner == "self"
      return @image_self
    elsif (root_device == nil or root_device == "")
      return build(search,arch,@image_all,@image_small,@image_large)
    elsif (root_device == "ebs"  or  root_device == "snapshot")
      return build(search,arch,@image_ebs,@image_ebs_small,@image_ebs_large)
    else
      return build(search,arch,@image_instance,@image_instance_small,@image_instance_large)
    end
  end
    def build(search,arch,image_all,image_small,image_large)
    puts "ImageCache.build(#{search},#{arch},#{image_all.size},#{image_small.size},#{image_large.size})"
    if (search == nil or search == "")
      if arch == "i386"
        return image_small
      elsif arch == "x86_64"
        return image_large
      else
        return image_all
      end
    else
      image_locs = Array.new
      if arch == "i386"
        image_small.each do |t|
          if t.index(search) != nil
            image_locs.push(t)
          end
        end
      elsif arch == "x86_64"
        image_large.each do |t|
          if t.index(search) != nil
            image_locs.push(t)
          end
        end
      else
        image_all.each do |t|
          if t.index(search) != nil
            image_locs.push(t)
          end
        end
      end
    end
    return image_locs
  end
    def status
    @status
  end

  def set_status(new_status)
    @status = new_status
  end
end