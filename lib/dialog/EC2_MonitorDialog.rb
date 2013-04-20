require 'fox16'
require 'google_chart'
require 'open-uri'
require 'rubygems'
require 'net/http'

include Fox


class Hours
   attr_reader :value

   def initialize(value)
      @value = value
   end
end

# Patch the #-() method to handle subtracting hours
# in addition to what it normally does

class DateTime

   alias old_subtract -

   def -(x) 
      case x
        when Hours; return DateTime.new(year, month, day, hour-x.value, min, sec)
        else;       return self.old_subtract(x)
      end
   end

end

# Add an #hours attribute to Fixnum that returns an Hours object. 
# This is for syntactic sugar, allowing you to write "someDate - 4.hours" for example

class Fixnum
   def hours
      Hours.new(self)
   end
end


class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end  


class EC2_MonitorDialog  < FXDialogBox

  def initialize(owner, instanceId, groupName, report, config)

    puts "EC2_MonitorDialog.initialize"
    @ec2_main = owner
    @env = ""
    @msg = ""
    @max_data = 0
    @created = false
    @mon = @ec2_main.environment.cloud_watch
    @config = config
    report_count=0
    @config["CloudWatch"].each do |report|
       report_count=report_count+1
    end  
    height=((report_count/2.0).round)*167 
    super(owner, "Monitoring", :opts => DECOR_ALL, :width => 800, :height => height)

    @mainFrame = FXVerticalFrame.new(self,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    
    @titleFrame = FXHorizontalFrame.new(@mainFrame,LAYOUT_CENTER_Y|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
    @title = FXLabel.new(@titleFrame, "",nil,:opts => LAYOUT_CENTER_X|JUSTIFY_TOP)
    @title.font = FXFont.new(@ec2_main.app, "Arial",12,FXFont::Bold)
    
    @topFrame = FXMatrix.new(@mainFrame, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL)
   
    
    @stats = ["Minimum","Maximum","Average"]
    @dimensions = {}
    @dimensions["InstanceId"]=instanceId
    puts "Report #{report}"
    if report == "Last Fortnight"
	@end_date = Date.today()
        @end_month = @end_date.strftime("%b")
        @start_date = @end_date - 13
        @start_month = @start_date.strftime("%b")
        puts "Fornight Report from #{@start_date} to #{@end_date}"
        @title.text = "Graphs for #{groupName}/#{instanceId} from "+@start_date.strftime("%b %d")+" to "+@end_date.strftime("%b %d")+" (Daily, Times in UTC)"       
        getStatsReports(groupName,instanceId,"Fortnight")
    else if report == "Last Hour"
 	    @end_date = DateTime.now.new_offset(0)
 	    @start_date = @end_date - 1.hours 
 	    puts "Last 1 Hour for #{@start_date} to #{@end_date}"
 	    @title.text = "Graphs for #{groupName}/#{instanceId} "+@start_date.strftime("%b %d %H:%M")+"-"+@end_date.strftime("%b %d %H:%M")+" (Times in UTC)"
 	    getStatsReports(groupName,instanceId,"Hourly")
         else if report == "Last 3 Hours"
		@end_date = DateTime.now.new_offset(0)
	        @start_date = @end_date - 3.hours 
 	        puts "Last 3 Hours for #{@start_date} to #{@end_date}"
 	        @title.text = "Graphs for #{groupName}/#{instanceId} "+@start_date.strftime("%b %d %H:%M")+"-"+@end_date.strftime("%b %d %H:%M")+" (Times in UTC)"
 	        getStatsReports(groupName,instanceId,"Three Hourly")
              else if report == "Last 12 Hours"
 		     @end_date = DateTime.now.new_offset(0)
 	             @start_date = @end_date - 0.5 
  	             puts "Last 12 Hours for #{@start_date} to #{@end_date}"
  	             @title.text = "Graphs for #{groupName}/#{instanceId} "+@start_date.strftime("%b %d %H:%M")+"-"+@end_date.strftime("%b %d %H:%M")+" (Times in UTC)"
 	             getStatsReports(groupName,instanceId,"Twelve Hourly")
                   else
            	       d = Date.today
		       if report == "Today"
		       # default
		       else if report == "Yesterday"
               		       d = d - 1
            		    else
            		       d = Date.parse(report)
            		    end   
                       end
       		       @start_date = DateTime.new(d.year,d.month,d.day,1)
       		       @end_date = DateTime.new(d.year,d.month,d.day,24)
       		       puts "Daily Report for #{@start_date} to #{@end_date}"
       		       @title.text = "Graphs for #{groupName}/#{instanceId} for "+@start_date.strftime("%b %d")+" (Times in UTC)"                   
                       getStatsReports(groupName,instanceId,"Daily")
                   end
              end     
         end
    end
    @msgFrame = FXHorizontalFrame.new(@mainFrame,LAYOUT_CENTER_Y|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
    @msg = FXLabel.new(@msgFrame, "",nil,:opts => LAYOUT_CENTER_X|JUSTIFY_TOP)
    @msg.text = "* Graphs only available when Amazon CloudWatch Monitoring Scripts installed on instance"
  end  
  
  def getStatsReports(groupName,instanceId,duration)
     @config["CloudWatch"].each do |report|
        title=report[0]
        parms=report[1]
        getStats(title,parms['namespace'],parms['measure'],parms['unit'],parms['dimensions'],groupName,instanceId,duration,true)
	if @msg != nil and @msg != ""
	  return 
        end  
     end   
  end   
  
  def getStats(title,namespace,measure,unit,dimensions,groupName,instanceId,duration,debug)
      if measure == "DiskSpaceUtilization"
        begin
         @dev = ""
         options = {}
         options["MetricName"]  = measure
         options["Namespace"]  = namespace
         options["Dimensions"]  = [{"Name" => "InstanceId","Value" => instanceId}] 
         dimensions.each do |d|
           options["Dimensions"].push(d)
         end  
         @response = @mon.list_metrics(options)
         @response[0]['Dimensions'].each do |m|
            if m['Name'] == "Filesystem"
               @dev = m['Value']
               puts "filesystem device for DiskSpaceUtilization report is #{@dev}"
               title = "#{title} for #{@dev}"
            end 
        end
       rescue
          puts "*** Error finding Filesystem for DiskSpaceUtilization report"
       end
     end
     begin  
      if debug 
         puts "getStats #{namespace} #{measure} #{duration} #{instanceId}"
      end   
      period = 3600
      case duration
        when "Fortnight"
           period = 86400
        when "Daily" 
           perod=3600
        when "Three Hourly"
           period=900
        when "Hourly"
           period=300
        when "Twelve Hourly"
           period=1800   
      end
      #puts "period #{period}"
      options = {}
      options["Statistics"] = @stats
      options["StartTime" ]     = @start_date
      options["EndTime" ]      = @end_date
      options["Period" ]          = period
      options["Unit" ]             = unit
      options["MetricName"]  = measure
      options["Namespace"]  = namespace
      options["Dimensions"]  = [{"Name" => "InstanceId","Value" => instanceId}] 
      if !dimensions.empty?
         dimensions.each do |d|
            options["Dimensions"].push(d)
         end   
      end 
      if measure == "DiskSpaceUtilization" and @dev != nil and @dev != ""
         options["Dimensions"].push({"Name" => "Filesystem","Value" => @dev})
      end
      #options = {}
      #options[:measure_name] = measure
      #options[:statistics] = @stats
      #options[:start_time] = @start_date
      #options[:end_time] = @end_date
      #options[:unit] = unit
      #options[:period] = period
      #options[:dimentions] = @dimensions
      #options[:namespace] = namespace
      @response = @mon.get_metric_statistics(options)
      #if debug 
         puts "*** response #{@response}"
      #end 
         @max_data = 0
         @data = Array.new
         d = 0
         c = 0
         @response.each do |r|
            avg = 0.0
            max = 0.0
            min = 0.0
            time = 0
            s = {}
            r.each do |key, value|
                if debug
                   if key == "Timestamp"
         	      puts "#{key} = #{value} ---------------------------------------"
         	   else
         	      puts "#{key} = #{value}"
         	   end
         	end   
         	if key.to_s == "Average"
         	   s[:avg] = value.to_f
         	   if unit == "Bytes"
         	      s[:avg] = s[:avg]/60
         	   end 
         	end
         	if key.to_s == "Maximum"
	 	   s[:max] = value.to_f
	 	   if unit == "Bytes"
		      s[:max] = s[:max]/60
         	   end 
         	end
         	if key.to_s == "Minimum"
	 	   s[:min] = value.to_f
		   if unit == "Bytes"
         	      s[:min] = s[:min]/60
         	   end 	 	   
         	end
         	if key.to_s == "Average" or key.to_s == "Maximum" or key.to_s == "Average"
         	   if unit == "Bytes"
         	      if value.to_i > @max_data*60
         	         @max_data =  (value.to_i)/60
           	      end   
         	    else 
         	      if value.to_i > @max_data
		         @max_data =  value.to_i
         	      end 	 
         	   end
         	end
		if key.to_s == "Timestamp" and duration == "Fortnight"
                   d =  DateTime.parse(value.to_s)
                   c = d - @start_date
                   if debug 
                      puts "Day is #{c}"
                   end   
                   s[:key] = c         	
         	end
 		if key.to_s == "Timestamp" and duration == "Daily"
         	   d =  DateTime.parse(value.to_s)
         	   if debug 
         	      puts "Hour  #{d.hour()}"
         	   end   
         	   s[:key] = d.hour()
         	end
                if key.to_s == "Timestamp" and duration == "Hourly"
                   if debug 
                      puts "Value #{value}"
                   end   
                   d =  DateTime.parse(value.to_s)
                   diff = d - @start_date
                   diff = diff*24*12
                   s[:key] = (diff.to_i)+1
                   if debug
                      puts "diff #{diff} #{(diff.to_i)+1}"
                   end   
                end
                if key.to_s == "Timestamp" and duration == "Three Hourly"
                   d =  DateTime.parse(value.to_s)
                   diff = d - @start_date
                   diff = diff*24*4
                   s[:key] = (diff.to_i)+1
                   if debug 
                      puts "diff #{diff} #{(diff.to_i)+1}"
                   end   
                end
                if key.to_s == "Timestamp" and duration == "Twelve Hourly"
                   d =  DateTime.parse(value.to_s)
                   diff = d - @start_date
                   diff = diff*24*2
                   s[:key] = (diff.to_i)+1
                   if debug 
                      puts "diff #{diff} #{(diff.to_i)+1}"
                   end   
                end                
  	    end
  	    @data << s
  	    
      end       
     rescue
      puts "ERROR: Failed  "+$!.to_s
      return
     end
   begin 
    f = FXImageFrame.new(@topFrame, nil, :opts => LAYOUT_FILL)
    if duration == "Fortnight"
       f.image = FXPNGImage.new(app, open(fortnight_line_chart(title,measure,groupName,instanceId,debug).to_escaped_url, "rb").read)
    end
    if duration == "Daily"
       f.image = FXPNGImage.new(app, open(daily_line_chart(title,measure,groupName,instanceId,debug).to_escaped_url, "rb").read)
    end
    if duration == "Hourly"
       f.image = FXPNGImage.new(app, open(hourly_line_chart(title,measure,groupName,instanceId,debug).to_escaped_url, "rb").read)
    end
    if duration == "Three Hourly"
       f.image = FXPNGImage.new(app, open(three_hourly_line_chart(title,measure,groupName,instanceId,debug).to_escaped_url, "rb").read)
    end
    if duration == "Twelve Hourly"
       f.image = FXPNGImage.new(app, open(twelve_hourly_line_chart(title,measure,groupName,instanceId,debug).to_escaped_url, "rb").read)
    end 
   rescue
     puts "ERROR: Failed  "+$!.to_s
     return
   end
    
  end
  

def fortnight_line_chart(title,measure,groupName,instanceId,debug) 

  d = DateTime.now()
  x_axis_labels = Array.new
  i=0 
  while i <14
    x_axis_labels[13-i] = ((d-i).day).to_s
    i=i+1
  end 

  y_axis_labels = create_y_axis_labels()


  series_1_xy = []
  series_2_xy = []
  series_3_xy = []

  @data = @data.sort_by {|r| r[:key]}
  i =0
  @data.each do |r|
    series_1_xy[i] = [r[:key], r[:avg] ]
    series_2_xy[i] = [r[:key], r[:max] ]
    series_3_xy[i] = [r[:key], r[:min] ]
    if debug 
        puts "avg - #{i}   [#{r[:key]},#{r[:avg]}]"
        puts "max - #{i}   [#{r[:key]},#{r[:max]}]"
        puts "min - #{i}   [#{r[:key]},#{r[:min]}]"
    end    
    i=i+1
  end  

  GoogleChart::LineChart.new('380x140', title, true) do  |lcxy|
    lcxy.data "Max", series_2_xy, '0404B4'
    lcxy.data "Avg", series_1_xy, '458B00'
    lcxy.data "Min", series_3_xy, 'B40404'
    lcxy.max_value [13,@max_data]
    lcxy.data_encoding = :text
    lcxy.axis :x, :labels => x_axis_labels
    lcxy.axis :y, :labels => y_axis_labels
    lcxy.grid :x_step => 7.7, :y_step => 10, :length_segment => 1, :length_blank => 3
    if debug
       puts lcxy.to_url
    end   
   end 

 end

def daily_line_chart(title,measure,groupName,instanceId,debug) 
  
  d = DateTime.now()
  x_axis_labels = Array.new
  i=1 
  while i <25
    x_axis_labels[i] = i
   i=i+1
  end
  
  y_axis_labels = create_y_axis_labels()
  
  series_1_xy = []
  series_2_xy = []
  series_3_xy = []
  
  @data = @data.sort_by {|r| r[:key]}
  i =0
  @data.each do |r|
    series_1_xy[i] = [r[:key], r[:avg] ]
    series_2_xy[i] = [r[:key], r[:max] ]
    series_3_xy[i] = [r[:key], r[:min] ]
    if debug
       puts "avg - #{i}   [#{r[:key]},#{r[:avg]}]"
       puts "max - #{i}   [#{r[:key]},#{r[:max]}]"
       puts "min - #{i}   [#{r[:key]},#{r[:min]}]"
    end   
    i=i+1
  end  
 
  GoogleChart::LineChart.new('380x140', title, true) do  |lcxy|
    lcxy.data "Max", series_2_xy, '0404B4'
    lcxy.data "Avg", series_1_xy, '458B00'
    lcxy.data "Min", series_3_xy, 'B40404'
    lcxy.max_value [24,@max_data]
    lcxy.data_encoding = :text
    lcxy.axis :x, :labels => x_axis_labels
    lcxy.axis :y, :labels => y_axis_labels
    lcxy.grid :x_step => 4.2, :y_step => 10, :length_segment => 1, :length_blank => 3
    if debug
       puts lcxy.to_url
    end   
   end 
  
end

def hourly_line_chart(title,measure,groupName,instanceId,debug) 
  m = @start_date.min()
  h = @start_date.hour()
  x_axis_labels = Array.new
  i=0 
  while i <12
   if i == 0 and m>9 
      x_axis_labels[i] = h.to_s+":"+m.to_s
   else if (m <5) or (i == 0 and m<10) 
          x_axis_labels[i] = h.to_s+":0"+m.to_s
        else
          x_axis_labels[i] = m
        end  
   end
   m = m +5 
   if m > 59
    m = m - 60
    if h <23
       h = h+1
    else
       h = 0
    end
   end 
   i=i+1
  end 
  
  y_axis_labels = create_y_axis_labels()
    
  series_1_xy = []
  series_2_xy = []
  series_3_xy = []
  
  @data = @data.sort_by {|r| r[:key]}
  i =0
  @data.each do |r|
    series_1_xy[i] = [r[:key], r[:avg] ]
    series_2_xy[i] = [r[:key], r[:max] ]
    series_3_xy[i] = [r[:key], r[:min] ]
    if debug
       puts "avg - #{i}   [#{r[:key]},#{r[:avg]}]"
       puts "max - #{i}   [#{r[:key]},#{r[:max]}]"
       puts "min - #{i}   [#{r[:key]},#{r[:min]}]"
    end   
    i=i+1
  end
  
  GoogleChart::LineChart.new('380x140', title, true) do  |lcxy|
    lcxy.data "Max", series_2_xy, '0404B4' 
    lcxy.data "Avg", series_1_xy, '458B00'
    lcxy.data "Min", series_3_xy, 'B40404'
    lcxy.max_value [11,@max_data]
    lcxy.data_encoding = :text
    lcxy.axis :x, :labels => x_axis_labels
    lcxy.axis :y, :labels => y_axis_labels
    lcxy.grid :x_step => 9.1, :y_step => 10, :length_segment => 1, :length_blank => 3
    if debug
       puts lcxy.to_url
    end   
   end 
  
end

def three_hourly_line_chart(title,measure,groupName,instanceId,debug) 
  m = @start_date.min()
  h = @start_date.hour()
  x_axis_labels = Array.new
  i=0 
  while i <12
   if i == 0 and m>15 
      x_axis_labels[i] = h.to_s+":"+m.to_s
   else if (m <15) or (i == 0 and m<16)
          if m<10
             x_axis_labels[i] = h.to_s+":0"+m.to_s
          else
             x_axis_labels[i] = h.to_s+":"+m.to_s
          end
        else
          x_axis_labels[i] = m
        end  
   end
   m = m +15 
   if m > 59
    m = m - 60
    if h <23
       h = h+1
    else
       h = 0
    end
   end 
   i=i+1
  end   
  y_axis_labels = create_y_axis_labels()
    
  series_1_xy = []
  series_2_xy = []
  series_3_xy = []
  
  @data = @data.sort_by {|r| r[:key]}
  i =0
  @data.each do |r|
    series_1_xy[i] = [r[:key], r[:avg] ]
    series_2_xy[i] = [r[:key], r[:max] ]
    series_3_xy[i] = [r[:key], r[:min] ]
    if debug
       puts "#{measure}#{groupName} avg - #{i}   [#{r[:key]},#{r[:avg]}]"
       puts "#{measure}#{groupName} max - #{i}   [#{r[:key]},#{r[:max]}]"
       puts "#{measure}#{groupName} min - #{i}   [#{r[:key]},#{r[:min]}]"
    end   
    i=i+1
  end
  
  GoogleChart::LineChart.new('380x140', title, true) do  |lcxy|
    lcxy.data "Max", series_2_xy, '0404B4'
    lcxy.data "Avg", series_1_xy, '458B00'
    lcxy.data "Min", series_3_xy, 'B40404'
    lcxy.max_value [11,@max_data]
    lcxy.data_encoding = :text
    lcxy.axis :x, :labels => x_axis_labels
    lcxy.axis :y, :labels => y_axis_labels
    lcxy.grid :x_step => 9.1, :y_step => 10, :length_segment => 1, :length_blank => 3
    if debug
       puts lcxy.to_url
    end   
  end 
  
end

def twelve_hourly_line_chart(title,measure,groupName,instanceId,debug) 
  m = @start_date.min()
  h = @start_date.hour()
  x_axis_labels = Array.new
  i=1 
  while i <25
   if i%2 != 0
      x_axis_labels[i] = h
   else
      x_axis_labels[i] = ""
   end   
   m = m +30 
   if m > 59
    m = m - 60
    if h <23
      h = h+1
    else
      h = 0
    end
   end 
   i=i+1
  end 
  
  y_axis_labels = create_y_axis_labels()
  #if @max_data < 10 
  #  @max_data = 10
  #end  
  #y_axis_labels = (0..10).to_a.collect do |v|
  #  #val = 10 * v
  #  if v ==5
  #    (@max_data/2).to_s
  #  else if v == 10
  #    @max_data.to_s
  #    else
  #      nil
  #    end  
  #  end
  #end
  
  series_1_xy = []
  series_2_xy = []
  series_3_xy = []
  
  @data = @data.sort_by {|r| r[:key]}
  i =0
  @data.each do |r|
    series_1_xy[i] = [r[:key], r[:avg] ]
    series_2_xy[i] = [r[:key], r[:max] ]
    series_3_xy[i] = [r[:key], r[:min] ]
    if debug
       puts "avg - #{i}   [#{r[:key]},#{r[:avg]}]"
       puts "max - #{i}   [#{r[:key]},#{r[:max]}]"
       puts "min - #{i}   [#{r[:key]},#{r[:min]}]"
    end   
    i=i+1
  end
  
  GoogleChart::LineChart.new('380x140', title, true) do  |lcxy|
    lcxy.data "Max", series_2_xy, '0404B4'
    lcxy.data "Avg", series_1_xy, '458B00'
    lcxy.data "Min", series_3_xy, 'B40404'
    lcxy.max_value [24,@max_data]
    lcxy.data_encoding = :text
    lcxy.axis :x, :labels => x_axis_labels
    lcxy.axis :y, :labels => y_axis_labels
    lcxy.grid :x_step => 4.2, :y_step => 10, :length_segment => 1, :length_blank => 3
    if debug
       puts lcxy.to_url
    end   
   end 
  
end

def create_y_axis_labels
  #puts "max data #{@max_data}"
  if @max_data < 10 
     @max_data = 10
  end  
  y_axis_labels = (0..10).to_a.collect do |v|
     #puts "v #{v}"
     if v ==5
        t = @max_data/2
        if t > 10000000
              ((t/1000000).to_i).to_s+"M"
        else if t > 1000000
              (((t.to_f)/1000000).round(2)).to_s+"M"   
        else if @max_data > 10000
                ((t/1000).to_i).to_s+"K"
             else 
                  t.to_s
             end
        end     
        end        
     else if v == 10
           if @max_data > 10000000
              ((@max_data/1000000).to_i).to_s+"M"
           else if @max_data > 1000000
              (((@max_data.to_f)/1000000).round(2)).to_s+"M"     
           else if @max_data > 10000
                ((@max_data/1000).to_i).to_s+"K"
                else 
                  @max_data.to_s
                end
           end     
           end
          else
            nil
          end  
     end
  end
  return y_axis_labels   
end  


end





