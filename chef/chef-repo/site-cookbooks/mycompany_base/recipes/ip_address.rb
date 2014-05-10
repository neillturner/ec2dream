aws = data_bag_item("aws", "main")

aws_elastic_ip "set elastic ip address" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  ip node[:base][:ip_address]  
  action :associate
end

execute "sleep for 1 minute to allow elastic ip address to associate" do
    command "sleep 60"
    user "root"
    group "root"
end