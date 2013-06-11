#!/usr/bin/env ruby
require 'rye'
require 'optparse'

def connection()
      return @connection_cache ||= begin
          user = "root"
          if @options[:user] != nil and @options[:user] != ""
             user = @options[:user]
          end
          if @options[:key] != nil and @options[:key] != ""
             puts "*****************************************************************"
             puts "*** Connecting to .... #{@name} as user #{user} with ssh key #{@options[:key]}"
             puts "*****************************************************************"
             rye = Rye::Box.new(@name, {:user => user, :keys => @options[:key], :safe => false, :password_prompt => false })
          else
             puts "*****************************************************************"
             puts "*** Connecting to .... #{@name} as user #{user}"
             puts "*****************************************************************"
             rye = Rye::Box.new(@name, {:user => user })
          end
          rye.disable_safe_mode
          rye
        end
end

def execute(commands, immediate=false)
      say("Executing: #{commands}", false)
      if immediate
        @conn.stdout_hook {|line| puts line}
      end
      return @conn.execute("(#{commands}) 2>&1")
    rescue Rye::Err => e
      puts "***********************"
      puts "*** EXECUTION ERROR ***"
      puts "***********************"
    ensure
      @conn.stdout_hook = nil
    end

def say(message, importance=nil)
    display = \
      case @verbosity
      when true
        true
      when nil
        importance != false
      else
        importance == true
      end

    if display
      puts message
    end
  end

 @options = {}
 @connection_cache = nil
 @name = nil
 @verbosity = true

 opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage:  hostname [OPTIONS]"
    opt.separator  ""
    opt.separator  "hostname: the name of the host to access"
    opt.separator  ""
    opt.separator  "Options"

    opt.on("-k","--key SSH_KEY_FILE","the ssh key pem file") do |filename|
      @options[:key] = filename
    end

    opt.on("-u","--user USERNAME","the user") do |user|
      @options[:user] = user
    end
  
    opt.on("-c","--command COMMAND","the command to execute") do |command|
      @options[:command] = command
    end

    opt.on("-h","--help","help") do
      puts opt_parser
    end
 end
 opt_parser.parse!

 if ARGV[0]==nil or ARGV[0]==""
   puts opt_parser
 else
   @name = ARGV[0]
 end

 @conn = connection()
 #puts ">#{@options[:command]}"
 if @options[:command]!=nil and @options[:command]!=""
    execute(@options[:command],true)
 end 
 

 

