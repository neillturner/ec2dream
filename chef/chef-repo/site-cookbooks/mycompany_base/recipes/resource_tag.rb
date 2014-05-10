aws = data_bag_item("aws", "main")

aws_resource_tag node['ec2']['instance_id'] do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    tags({"Name" => "#{node[:base][:tag_name]}"})
    action :add
end
