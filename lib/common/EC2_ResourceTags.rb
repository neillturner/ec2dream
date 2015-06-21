require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

class EC2_ResourceTags

  @tags = nil
  @ec2_main = nil

  def initialize(owner,tags=nil,tag_str=nil)
    @ec2_main = owner
    @tags = nil
    if tags != nil
      @tags = tags
    else
      if tag_str != nil
        nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
        if nickname_tag != nil and nickname_tag != ""
          @tags={}
          @tags[nickname_tag]=tag_str
        end
      end
    end
  end

  def update(tags)
    @tags = tags
  end

  def get
    return @tags
  end
    def empty
    if @tags == nil or @tags.size == 0
      return true
    else
      return false
    end
  end

  def show
    tag_str = ""
    if @tags != nil
      @tags.each_pair do |k,v|
        if tag_str == ""
          tag_str = "#{k}=#{v}"
        else
          tag_str = tag_str + " #{k}=#{v}"
        end
      end
    end
    return tag_str
  end
  def nickname
    nickname_value = ""
    nickname_tag = @ec2_main.settings.get('AMAZON_NICKNAME_TAG')
    if nickname_tag != nil and nickname_tag != ""
      nickname_tag = "#{nickname_tag}"
      if @tags != nil
        @tags.each_pair do |k,v|
          #puts "k #{k} v #{v}"
          if k == nickname_tag
            nickname_value = v
          end
        end
        # if no name use the autoscaling group name
        if nickname_value == nil or nickname_value == ""
          @tags.each_pair do |k,v|
            #puts "k #{k} v #{v}"
            if k == "aws:autoscaling:groupName"
              nickname_value = v
            end
          end
        end
      end
    end
    return nickname_value
  end
  def assign(resource_id)
    if !@ec2_main.settings.openstack
      if @tags != nil
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
          begin
            r = ec2.create_tags(resource_id, @tags)
            return true
          rescue
            puts("Create Tags Failed #{resource_id} #{@tags} #{$!.to_s}")
            return false
          end
        end
      end
    end
  end

  def load(fn)
    begin
      File.open(fn, "rb") do |f|
        @tags = Marshal.load(f)
        return true
      end
      return false
    rescue
      @tags = {}
      message = $!.to_s
      return false if message.start_with? "No such file or directory"
      puts("Error loading tags from #{fn} #{message}")
      return false
    end
  end

  def save(fn)
    begin
      File.open(fn, "wb") do |f|
        Marshal.dump(@tags, f)
        return true
      end
      return false
    rescue
      puts("Error saving tags tags to #{fn} #{$!.to_s}")
      return false
    end
  end
end
