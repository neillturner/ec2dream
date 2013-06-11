aws = data_bag_item("aws", "main")

aws_ebs_volume node[:base][:volume] do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size 50
      device node[:base][:device]
      action [ :attach ]
    end


execute "sleep for 1 minute to allow elastic volume " do
    command "sleep 60"
    user "root"
    group "root"
end