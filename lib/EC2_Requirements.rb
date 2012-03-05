#
# for windows auto install gem packages
#

require 'rubygems'

def gem_install(g)
 puts "gem_#{g}" 
 c = "cmd.exe /C %EC2DREAM_HOME%/ruby/gem_#{g}.bat"
 puts c 
 system(c)
end
if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
    begin
      require 'fox16'
    rescue LoadError
      gem_install("fxruby")
    end
    begin
      require 'right_aws'
    rescue LoadError
      gem_install("right_aws")
    end
    begin
      require 'tzinfo'
    rescue LoadError
      gem_install("tzinfo")
    end
    begin
      require 'zip/zip'
    rescue LoadError
      gem_install("rubyzip")
    end
    begin
      require "google_chart"
    rescue LoadError
      gem_install("gbchartrb")
    end    
    begin
      require 'pocketknife'
    rescue LoadError
      gem_install("pocketknife")
    end      
end

