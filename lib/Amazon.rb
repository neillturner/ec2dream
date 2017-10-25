require 'fog/aws'
require 'json'

class Amazon

  def initialize()
    @conn = {}
    @aws_conn = {}
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

  def awssdk_conn(type)
    begin
      require 'aws-sdk'
    rescue LoadError
      puts "ERROR: Install rubygem aws-sdk #{$!}"
      return
    end
    Aws.use_bundled_cert!
    if @aws_conn[type] == nil
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
      ENV['AWS_REGION'] = region
      begin
       if @access_key_id != nil and @access_key_id != ""
        case type
        when 'APIGateway'
          @aws_conn[type] = Aws::APIGateway::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'AppStream'
          @aws_conn[type] = Aws::AppStream::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ApplicationAutoScaling'
          @aws_conn[type] = Aws::ApplicationAutoScaling::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ApplicationDiscoveryService'
          @aws_conn[type] = Aws::ApplicationDiscoveryService::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Athena'
          @aws_conn[type] = Aws::Athena::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'AutoScaling'
          @aws_conn[type] = Aws::AutoScaling::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Batch'
          @aws_conn[type] = Aws::Batch::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Budgets'
          @aws_conn[type] = Aws::Budgets::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudDirectory'
          @aws_conn[type] = Aws::CloudDirectory::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudFormation'
          @aws_conn[type] = Aws::CloudFormation::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudFront'
          @aws_conn[type] = Aws::CloudFront::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudHSM'
          @aws_conn[type] = Aws::CloudHSM::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudSearch'
          @aws_conn[type] = Aws::CloudSearch::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudSearchDomain'
          @aws_conn[type] = Aws::CloudSearchDomain::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudTrail'
          @aws_conn[type] = Aws::CloudTrail::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudWatch'
          @aws_conn[type] = Aws::CloudWatch::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudWatchEvents'
          @aws_conn[type] = Aws::CloudWatchEvents::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CloudWatchLogs'
          @aws_conn[type] = Aws::CloudWatchLogs::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CodeBuild'
          @aws_conn[type] = Aws::CodeBuild::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CodeCommit'
          @aws_conn[type] = Aws::CodeCommit::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CodeDeploy'
          @aws_conn[type] = Aws::CodeDeploy::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CodePipeline'
          @aws_conn[type] = Aws::CodePipeline::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CodeStar'
          @aws_conn[type] = Aws::CodeStar::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CognitoIdentity'
          @aws_conn[type] = Aws::CognitoIdentity::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'CognitoIdentityProvider'
          @aws_conn[type] = Aws::CognitoIdentityProvider::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ConfigService'
          @aws_conn[type] = Aws::ConfigService::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'DataPipeline'
          @aws_conn[type] = Aws::DataPipeline::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'DatabaseMigrationService'
          @aws_conn[type] = Aws::DatabaseMigrationService::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'DirectConnect'
          @aws_conn[type] = Aws::DirectConnect::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'DirectoryService'
          @aws_conn[type] = Aws::DirectoryService::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'DynamoDB'
          @aws_conn[type] = Aws::DynamoDB::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'EC2'
          @aws_conn[type] = Aws::EC2::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ECR'
          @aws_conn[type] = Aws::ECR::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ECS'
          @aws_conn[type] = Aws::ECS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'EFS'
          @aws_conn[type] = Aws::EFS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'EMR'
          @aws_conn[type] = Aws::EMR::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ElastiCache'
          @aws_conn[type] = Aws::ElastiCache::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ElasticBeanstalk'
          @aws_conn[type] = Aws::ElasticBeanstalk::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ElasticLoadBalancing'
          @aws_conn[type] = Aws::ElasticLoadBalancing::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ALB'
          @aws_conn[type] = Aws::ElasticLoadBalancingV2::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ElasticTranscoder'
          @aws_conn[type] = Aws::ElasticTranscoder::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ElasticsearchService'
          @aws_conn[type] = Aws::ElasticsearchService::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Firehose'
          @aws_conn[type] = Aws::Firehose::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Glacier'
          @aws_conn[type] = Aws::Glacier::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'IAM'
          @aws_conn[type] = Aws::IAM::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ImportExport'
          @aws_conn[type] = Aws::ImportExport::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'KMS'
          @aws_conn[type] = Aws::KMS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Kinesis'
          @aws_conn[type] = Aws::Kinesis::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'KinesisAnalytics'
          @aws_conn[type] = Aws::KinesisAnalytics::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Lambda'
          @aws_conn[type] = Aws::Lambda::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'OpsWorks'
          @aws_conn[type] = Aws::OpsWorks::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Organizations'
          @aws_conn[type] = Aws::Organizations::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'RDS'
          @aws_conn[type] = Aws::RDS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
         when 'Redshift'
          @aws_conn[type] = Aws::Redshift::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Rekognition'
          @aws_conn[type] = Aws::Rekognition::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ResourceGroupsTaggingAPI'
          @aws_conn[type] = Aws::ResourceGroupsTaggingAPI::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Route53'
          @aws_conn[type] = Aws::Route53::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Route53Domains'
          @aws_conn[type] = Aws::Route53Domains::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'S3'
          @aws_conn[type] = Aws::S3::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SES'
          @aws_conn[type] = Aws::SES::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SMS'
          @aws_conn[type] = Aws::SMS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SNS'
          @aws_conn[type] = Aws::SNS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SQS'
          @aws_conn[type] = Aws::SQS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SSM'
          @aws_conn[type] = Aws::SSM::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'STS'
          @aws_conn[type] = Aws::STS::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SWF'
          @aws_conn[type] = Aws::SWF::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'ServiceCatalog'
          @aws_conn[type] = Aws::ServiceCatalog::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Shield'
          @aws_conn[type] = Aws::Shield::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'SimpleDB'
          @aws_conn[type] = Aws::SimpleDB::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Snowball'
          @aws_conn[type] = Aws::Snowball::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'States'
          @aws_conn[type] = Aws::States::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'StorageGateway'
          @aws_conn[type] = Aws::StorageGateway::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'Support'
          @aws_conn[type] = Aws::Support::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'WAF'
          @aws_conn[type] = Aws::WAF::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'WAFRegional'
          @aws_conn[type] = Aws::WAFRegional::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'WorkDocs'
          @aws_conn[type] = Aws::WorkDocs::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'WorkSpaces'
          @aws_conn[type] = Aws::WorkSpaces::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        when 'XRay'
          @aws_conn[type] = Aws::XRay::Client.new(access_key_id: @access_key_id, secret_access_key: @secret_access_key)
        else
          nil
          return
        end
       else
        case type
        when 'APIGateway'
          @aws_conn[type] = Aws::APIGateway::Client.new()
        when 'AppStream'
          @aws_conn[type] = Aws::AppStream::Client.new()
        when 'ApplicationAutoScaling'
          @aws_conn[type] = Aws::ApplicationAutoScaling::Client.new()
        when 'ApplicationDiscoveryService'
          @aws_conn[type] = Aws::ApplicationDiscoveryService::Client.new()
        when 'Athena'
          @aws_conn[type] = Aws::Athena::Client.new()
        when 'AutoScaling'
          @aws_conn[type] = Aws::AutoScaling::Client.new()
        when 'Batch'
          @aws_conn[type] = Aws::Batch::Client.new()
        when 'Budgets'
          @aws_conn[type] = Aws::Budgets::Client.new()
        when 'CloudDirectory'
          @aws_conn[type] = Aws::CloudDirectory::Client.new()
        when 'CloudFormation'
          @aws_conn[type] = Aws::CloudFormation::Client.new()
        when 'CloudFront'
          @aws_conn[type] = Aws::CloudFront::Client.new()
        when 'CloudHSM'
          @aws_conn[type] = Aws::CloudHSM::Client.new()
        when 'CloudSearch'
          @aws_conn[type] = Aws::CloudSearch::Client.new()
        when 'CloudSearchDomain'
          @aws_conn[type] = Aws::CloudSearchDomain::Client.new()
        when 'CloudTrail'
          @aws_conn[type] = Aws::CloudTrail::Client.new()
        when 'CloudWatch'
          @aws_conn[type] = Aws::CloudWatch::Client.new()
        when 'CloudWatchEvents'
          @aws_conn[type] = Aws::CloudWatchEvents::Client.new()
        when 'CloudWatchLogs'
          @aws_conn[type] = Aws::CloudWatchLogs::Client.new()
        when 'CodeBuild'
          @aws_conn[type] = Aws::CodeBuild::Client.new()
        when 'CodeCommit'
          @aws_conn[type] = Aws::CodeCommit::Client.new()
        when 'CodeDeploy'
          @aws_conn[type] = Aws::CodeDeploy::Client.new()
        when 'CodePipeline'
          @aws_conn[type] = Aws::CodePipeline::Client.new()
        when 'CodeStar'
          @aws_conn[type] = Aws::CodeStar::Client.new()
        when 'CognitoIdentity'
          @aws_conn[type] = Aws::CognitoIdentity::Client.new()
        when 'CognitoIdentityProvider'
          @aws_conn[type] = Aws::CognitoIdentityProvider::Client.new()
        when 'ConfigService'
          @aws_conn[type] = Aws::ConfigService::Client.new()
        when 'DataPipeline'
          @aws_conn[type] = Aws::DataPipeline::Client.new()
        when 'DatabaseMigrationService'
          @aws_conn[type] = Aws::DatabaseMigrationService::Client.new()
        when 'DirectConnect'
          @aws_conn[type] = Aws::DirectConnect::Client.new()
        when 'DirectoryService'
          @aws_conn[type] = Aws::DirectoryService::Client.new()
        when 'DynamoDB'
          @aws_conn[type] = Aws::DynamoDB::Client.new()
        when 'EC2'
          @aws_conn[type] = Aws::EC2::Client.new()
        when 'ECR'
          @aws_conn[type] = Aws::ECR::Client.new()
        when 'ECS'
          @aws_conn[type] = Aws::ECS::Client.new()
        when 'EFS'
          @aws_conn[type] = Aws::EFS::Client.new()
        when 'EMR'
          @aws_conn[type] = Aws::EMR::Client.new()
        when 'ElastiCache'
          @aws_conn[type] = Aws::ElastiCache::Client.new()
        when 'ElasticBeanstalk'
          @aws_conn[type] = Aws::ElasticBeanstalk::Client.new()
        when 'ElasticLoadBalancing'
          @aws_conn[type] = Aws::ElasticLoadBalancing::Client.new()
        when 'ALB'
          @aws_conn[type] = Aws::ElasticLoadBalancingV2::Client.new()
        when 'ElasticTranscoder'
          @aws_conn[type] = Aws::ElasticTranscoder::Client.new()
        when 'ElasticsearchService'
          @aws_conn[type] = Aws::ElasticsearchService::Client.new()
        when 'Firehose'
          @aws_conn[type] = Aws::Firehose::Client.new()
        when 'Glacier'
          @aws_conn[type] = Aws::Glacier::Client.new()
        when 'IAM'
          @aws_conn[type] = Aws::IAM::Client.new()
        when 'ImportExport'
          @aws_conn[type] = Aws::ImportExport::Client.new()
        when 'KMS'
          @aws_conn[type] = Aws::KMS::Client.new()
        when 'Kinesis'
          @aws_conn[type] = Aws::Kinesis::Client.new()
        when 'KinesisAnalytics'
          @aws_conn[type] = Aws::KinesisAnalytics::Client.new()
        when 'Lambda'
          @aws_conn[type] = Aws::Lambda::Client.new()
        when 'OpsWorks'
          @aws_conn[type] = Aws::OpsWorks::Client.new()
        when 'Organizations'
          @aws_conn[type] = Aws::Organizations::Client.new()
        when 'RDS'
          @aws_conn[type] = Aws::RDS::Client.new()
         when 'Redshift'
          @aws_conn[type] = Aws::Redshift::Client.new()
        when 'Rekognition'
          @aws_conn[type] = Aws::Rekognition::Client.new()
        when 'ResourceGroupsTaggingAPI'
          @aws_conn[type] = Aws::ResourceGroupsTaggingAPI::Client.new()
        when 'Route53'
          @aws_conn[type] = Aws::Route53::Client.new()
        when 'Route53Domains'
          @aws_conn[type] = Aws::Route53Domains::Client.new()
        when 'S3'
          @aws_conn[type] = Aws::S3::Client.new()
        when 'SES'
          @aws_conn[type] = Aws::SES::Client.new()
        when 'SMS'
          @aws_conn[type] = Aws::SMS::Client.new()
        when 'SNS'
          @aws_conn[type] = Aws::SNS::Client.new()
        when 'SQS'
          @aws_conn[type] = Aws::SQS::Client.new()
        when 'SSM'
          @aws_conn[type] = Aws::SSM::Client.new()
        when 'STS'
          @aws_conn[type] = Aws::STS::Client.new()
        when 'SWF'
          @aws_conn[type] = Aws::SWF::Client.new()
        when 'ServiceCatalog'
          @aws_conn[type] = Aws::ServiceCatalog::Client.new()
        when 'Shield'
          @aws_conn[type] = Aws::Shield::Client.new()
        when 'SimpleDB'
          @aws_conn[type] = Aws::SimpleDB::Client.new()
        when 'Snowball'
          @aws_conn[type] = Aws::Snowball::Client.new()
        when 'States'
          @aws_conn[type] = Aws::States::Client.new()
        when 'StorageGateway'
          @aws_conn[type] = Aws::StorageGateway::Client.new()
        when 'Support'
          @aws_conn[type] = Aws::Support::Client.new()
        when 'WAF'
          @aws_conn[type] = Aws::WAF::Client.new()
        when 'WAFRegional'
          @aws_conn[type] = Aws::WAFRegional::Client.new()
        when 'WorkDocs'
          @aws_conn[type] = Aws::WorkDocs::Client.new()
        when 'WorkSpaces'
          @aws_conn[type] = Aws::WorkSpaces::Client.new()
        when 'XRay'
          @aws_conn[type] = Aws::XRay::Client.new()
        else
          nil
          return
        end
       end
      rescue
        reset_connection
        puts "AWSSDK ERROR: on #{type} connection to amazon #{$!}"
        puts "check your keys in environment"
      end

    else
      @aws_conn[type]
    end
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
        # remove assume role support in favour of using fog credentials.
        #if @user_role == nil and @role_arn != nil and @role_arn != ""
        #  puts "Assuming Role #{@role_arn}"
        #  @access_key_id = $ec2_main.settings.get('AMAZON_ACCESS_KEY_ID')
        #  @secret_access_key = $ec2_main.settings.get('AMAZON_SECRET_ACCESS_KEY')
        #  @role_arn = $ec2_main.settings.get('AMAZON_ROLE_ARN')
        #  @session_token = nil
        #  @conn['STS'] = Fog::AWS::STS.new(:aws_access_key_id => @access_key_id, :aws_secret_access_key => @secret_access_key, :region => 'eu-west-1' )
        #  response = @conn['STS'].assume_role('admin',@role_arn)
        #  if response.status == 200
        #    @user_role = response.body
        #    #@user_role.each do |k, v|
        #    #  puts "*** #{k} #{v}"
        #    #end
        #    @access_key_id = @user_role['AccessKeyId']
        #    @secret_access_key = @user_role['SecretAccessKey']
        #    @session_token = @user_role['SessionToken']
        #  else
        #    puts "*** here ***"
        #    puts "ERROR: on sts connection to amazon #{response.status}"
        #    puts "check your keys in environment"
        #    return
        #  end
        #end
       if @access_key_id != nil and @access_key_id != ""
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
       else
        Fog.credential = @role_arn if @role_arn != nil or @role_arn != ""
        case type
        when 'AutoScaling'
          @conn[type] = Fog::AWS::AutoScaling.new(:region => region)
        when 'CDN'
        when 'Compute'
          @conn[type] = Fog::Compute.new(:provider=>'AWS', :region => region)
        when 'CDN'
          @conn[type] = Fog::CDN.new(:provider=>'AWS' )
        when 'CloudFormation'
          @conn[type] = Fog::AWS::CloudFormation.new(:region => region )
        when 'CloudWatch'
          @conn[type] = Fog::AWS::CloudWatch.new( :region => region)
        when 'DNS'
          @conn[type] = Fog::DNS.new(:provider=>'AWS',)
        when 'ElasticBeanstalk'
          @conn[type] = Fog::AWS::ElasticBeanstalk.new(:region => region)
        when 'ELB'
          @conn[type] = Fog::AWS::ELB.new(:region => region)
        when 'IAM'
          @conn[type] = Fog::AWS::IAM.new()
        when 'RDS'
          @conn[type] = Fog::AWS::RDS.new(:region => region )
        when 'S3'
          @conn[type] = Fog::Storage.new(:provider=>'AWS',:region => region)
        when 'SES'
          @conn[type] = Fog::AWS::SES.new()
        when 'SNS'
          @conn[type] = Fog::AWS::SNS.new()
        when 'SQS'
          @conn[type] = Fog::AWS::SQS.new()
        else
          nil
          return
        end
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
    @aws_conn = {}
  end
end

