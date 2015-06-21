require 'rubygems'
require 'net/http'
require 'resolv'

class Data_cloud_watch

  def initialize(owner)
    puts "data_cloud_watch.initialize"
    @ec2_main = owner
  end
  def get_metric_statistics(options)
    data = []
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn.get_metric_statistics(options).body['GetMetricStatisticsResult']['Datapoints']
    else
      raise "Connection Error"
    end
    return data
  end
  def list_metrics(options=nil)
    data = []
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn.list_metrics(options).body['ListMetricsResult']['Metrics']
    else
      raise "Connection Error"
    end
    return data
  end
  def describe_alarms(options={})
    data = []
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn.describe_alarms(options).body['DescribeAlarmsResult']['MetricAlarms']
    else
      raise "Connection Error"
    end
    return data
  end
  def describe_alarm_history(options={})
    data = []
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn.describe_alarm_history(options).body['DescribeAlarmHistoryResult']['AlarmHistoryItems']
    else
      raise "Connection Error"
    end
    return data
  end
  def put_metric_alarm(options)
    data = false
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn. put_metric_alarm(options)
      if data.status == 200
        data = true
      else
        data = false
      end
    else
      raise "Connection Error"
    end
    return data
  end
  def delete_alarms(alarm_names)
    data = false
    conn = @ec2_main.environment.mon_connection
    if conn != nil
      data = conn.delete_alarms(alarm_names)
      if data.status == 200
        data = true
      else
        data = false
      end
    else
      raise "Connection Error"
    end
    return data
  end
end