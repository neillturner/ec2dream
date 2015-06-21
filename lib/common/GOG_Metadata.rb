require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

class GOG_Metadata

  @tags = nil
  @ec2_main = nil

  def initialize(owner,tags=nil)
    @ec2_main = owner
    @tags = nil
    if tags != nil
      @tags = tags
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
