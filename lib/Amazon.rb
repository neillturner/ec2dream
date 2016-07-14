require 'fog/aws'
require 'json'

class Amazon

  def initialize()
    @conn = {}
    data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_config.json")
    @config = JSON.parse(data)
    @session_token = nil
    @user_role = nil
    @access_key_id = $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')
    @secret_access_key = $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY')
    @role_arn = $ec2_main.settings.get('AMAZON_ROLE_ARN')
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
         if @user_role == nil and @role_arn != nil and @role_arn != ""
           puts "Assuming Role #{@role_arn}"
           @access_key_id = $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')
           @secret_access_key = $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY')
           @role_arn = $ec2_main.settings.get('AMAZON_ROLE_ARN')
           @session_token = nil
           @conn['STS'] = Fog::AWS::STS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key )
           response = @conn['STS'].assume_role('admin',@role_arn)
           if response.status == 200
             @user_role = response.body
             #@user_role.each do |k, v|
             #  puts "*** #{k} #{v}"
             #end
             @access_key_id = @user_role['AccessKeyId']
             @secret_access_key = @user_role['SecretAccessKey']
             @session_token = @user_role['SessionToken']
           else
             puts "ERROR: on sts connection to amazon #{response.status}"
             puts "check your keys in environment"
             return
           end
        end
        case type
        when 'AutoScaling'
          @conn[type] = Fog::AWS::AutoScaling.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'CDN'
        when 'Compute'
          @conn[type] = Fog::Compute.new(:provider=>'AWS',:aws_access_key_id =>  @access_key_id, :aws_secret_access_key => @secret_access_key , :region => region, :aws_session_token => @session_token )
        when 'CDN'
          @conn[type] = Fog::CDN.new(:provider=>'AWS',:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
          #@conn[type] = Fog::AWS::CDN.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key )
        when 'CloudFormation'
          @conn[type] = Fog::AWS::CloudFormation.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'CloudWatch'
          @conn[type] = Fog::AWS::CloudWatch.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'DNS'
          @conn[type] = Fog::DNS.new(:provider=>'AWS',:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
          #@conn[type] = Fog::AWS::DNS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
        when 'ElasticBeanstalk'
          @conn[type] = Fog::AWS::ElasticBeanstalk.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'ELB'
          @conn[type] = Fog::AWS::ELB.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'IAM'
          @conn[type] = Fog::AWS::IAM.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
        when 'RDS'
          @conn[type] = Fog::AWS::RDS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token )
        when 'S3'
          @conn[type] = Fog::Storage.new(:provider=>'AWS',:aws_access_key_id =>  @access_key_id, :aws_secret_access_key => @secret_access_key, :region => region, :aws_session_token => @session_token)
        when 'SES'
          @conn[type] = Fog::AWS::SES.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
        when 'SNS'
          @conn[type] = Fog::AWS::SNS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
        when 'SQS'
          @conn[type] = Fog::AWS::SQS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :aws_session_token => @session_token )
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
    puts "Amazon.reset_connection"
    @user_role = nil
    @conn = {}
  end
end

