#
# Describe
#
Set-ExecutionPolicy RemoteSigned
. ./ps1/settings.ps1
 $ec2 = new-object Amazon.EC2.PowerEC2Dream($env:AMAZON_ACCESS_KEY_ID,$env:AMAZON_SECRET_ACCESS_KEY)
 $res = $ec2.DescribeInstances()
 write-host $res[0].Keys
 write-host 
 foreach ($r in $res)
 {
     write-host $r.Values 
 }