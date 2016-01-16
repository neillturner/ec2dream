require 'fog'
require 'json'

class Amazon

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_config.json")
    @config = JSON.parse(data)
  end

  def api
    'aws'
  end

  def name
    'amazon'
  end

  def config
    @config
  end

  def conn(type)
    #Fog.mock!
    if @conn[type] == nil
      start_time = Time.new
      ec2_url = $ec2_main.settings.get('EC2_URL')
      region = "us-east-1"
      if ec2_url != nil and ec2_url.length>0
        sa = (ec2_url).split"."
        if sa.size>1
          region = (sa[1])
          if region == "ec2"
            region = sa[0][8..-1]
          end
        end
        if region == "amazonaws"
          region = "us-east-1"
        end
      end
      begin
        case type
        when 'AutoScaling'
          @conn[type] = Fog::AWS::AutoScaling.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'Compute'
          @conn[type] = Fog::Compute.new(:provider=>'AWS',:aws_access_key_id =>  $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') , :region => region)
          #$ec2_main.log.write("conn = Fog::Compute.new(:provider=>'AWS',:aws_access_key_id =>  #{$ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')}, :aws_secret_access_key => #{$ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY')} , :region => #{region})")
          #@conn[type]
        when 'CDN'
          @conn[type] = Fog::CDN.new(:provider=>'AWS',:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
          #@conn[type] = Fog::AWS::CDN.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
        when 'CloudFormation'
          @conn[type] = Fog::AWS::CloudFormation.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'CloudWatch'
          @conn[type] = Fog::AWS::CloudWatch.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'DNS'
          @conn[type] = Fog::DNS.new(:provider=>'AWS',:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
          #@conn[type] = Fog::AWS::DNS.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
        when 'ElasticBeanstalk'
          @conn[type] = Fog::AWS::ElasticBeanstalk.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'ELB'
          @conn[type] = Fog::AWS::ELB.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'IAM'
          @conn[type] = Fog::AWS::IAM.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
        when 'RDS'
          @conn[type] = Fog::AWS::RDS.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region )
        when 'SES'
          @conn[type] = Fog::AWS::SES.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
        when 'SNS'
          @conn[type] = Fog::AWS::SNS.new(:aws_access_key_id => $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key => $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY') )
        else
          nil
          return
        end
      rescue
        reset_connection
        puts "ERROR: on #{type} connection to amazon #{$!}"
        puts "check your keys in environment"
      end

    else
      @conn[type]
    end
  end

  def reset_connection
    @conn = {}
  end
end

