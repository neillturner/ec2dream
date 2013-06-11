  #!/usr/bin/ruby
  # bundle.rb
  #  Bundle instance store instance 
  
  require 'rubygems'
  require 'right_aws'
  require 'net/http'
  require 'date'
  # for redhat, centos
  #require '/root/settings'
  # for ubuntu
  require '/home/ubuntu/settings'
  
  def print_message(message)
     puts message+"\n"
     #system('logger '+message+"\n") 
  end 
  
    def run(command)
    print_message(command)
    system(command)
  end   
 
  options = {}
  #
  # Set parameters (or pass in the command line via
  # server_name=<servername>&s3_ami_bucket=<s3_ami_bucket>&amazon_account_id=<amazon_account_id>&cert_filename=<cert_filename>&private_key_filename=<private_key_filename>&amazon_image_type=<i386 or x86_64>
  # or inline below 
  #
  #options['server_name'] = <servername>    Use dashes in name instead of underscores
  #options['s3_ami_bucket'] = <s3_ami_bucket>
  #options['amazon_account_id'] = <amazon_account_id>
  #options['cert_filename'] = <cert_filename>    Use full path
  #options['private_key_filename'] <private_key_filename>    Use full path
  #options['amazon_image_type'] = <i386 or x86_64>
  #options['location']  = <US or EU or us-west-1 or ap-southeast-1>
  
  # default amazon access settings
  options['accesskey'] = Settings.AMAZON_PUBLIC_KEY
  options['secretaccesskey'] = Settings.AMAZON_PRIVATE_KEY
  options['region'] = Settings.REGION
  
  print_message("bundle.rb - Bundle an image for an instance store instance")
  
  # look for command line arguments
  args = Array.new
  i = 0
  ARGV.each do|a|
    args[i]=a
    i+1
  end
  if args[0] != nil and args[0] != ""
     args[0].split('&').each do |param|
       k,v = param.split('=')
       if args[0] != nil and args[0] != ""
          options[k.downcase] = v
       end   
     end
  end 
    
  url = 'http://169.254.169.254/latest/meta-data/instance-id'
  @instance_id = Net::HTTP.get_response(URI.parse(url)).body
  
  # Remove any old image.
  
  run("rm -rf /mnt/bundle")
  run("mkdir /mnt/bundle")
  # folders to exclude from bundling
  exclude_list="-e /mnt"  

  # Create the EC2 Bundle
  run("ec2-bundle-vol #{exclude_list} -d /mnt/bundle -c #{options['cert_filename']} -k #{options['private_key_filename']} -u #{options['amazon_account_id']} -r #{options['amazon_image_type']}")
  # Upload the EC2 Bundle to S3
  today = DateTime.now
  s3_bucket_name="#{options['s3_ami_bucket']}/#{options['server_name']}-#{today.strftime("%y%m%d")}"
  run("ec2-upload-bundle -b #{s3_bucket_name} -m /mnt/bundle/image.manifest.xml -a #{options['accesskey']} -s #{options['secretaccesskey']} --location #{options['location']}")
  # 
  # need to manually register image using console or EC2Dream admin for #{s3_bucket_name}/image.manifest.xml"
  # 
 
 
