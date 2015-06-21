require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

class EC2_FilterTags

  @tags = nil

  def initialize(tags=nil,tag_str=nil)
    if tags != nil
      @tags = tags
    else
      if tag_str != nil
        @tags = Marshal.load(tag_str)
      end
    end
  end

  def update(tags)
    @tags = tags
  end

  def get
    return @tag
  end

  def show
    tag_str = ""
    @tags.each do |h|
      h.each_pair do |k,v|
        value_str = ""
        case k
        when "key"
          v.each do |j|
            if tag_str == ""
              tag_str = "#{j}="
            else
              tag_str = "#{tag_str} #{j}="
            end
          end
        when "value"
          v.each do |j|
            if value_str == ""
              value_str  = "#{value_str},#{j}"
            else
              value_str = j
            end
          end
          tag_str = "#{tag_str}#{value_str}"
        end
      end
    end
    return tag_str
  end
end
