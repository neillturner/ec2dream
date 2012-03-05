#
# Bundle windows instance
# Very much a first cut of the script. 
# EC2 interface needs to hide the XML with a wrapper
#

trap [Amazon.EC2.AmazonEC2Exception] {
  write-host
  write-error $("Error: " + $_.Exception.Message);
  exit
 }
 
function New-GenericList([type] $type)
{
  $base = [System.Collections.Generic.List``1]
  $qt = $base.MakeGenericType(@($type))
  New-Object $qt
}

Function help-message 
{
 Write-Host ""
 Write-Host "Usage: bundle.ps1  instance server-name s3_prefix"
 Write-Host ""
 Write-Host "instance:           Name of instance to bundle"
 Write-Host "server-name:        Name of server to bundle"
 Write-Host "s3_prefix:          Prefix of bundle stored in S3 bucket"
 Write-Host ""
 exit
}

$s = $env:EC2DREAM_HOME+"/ps1/settings.ps1"

. $s

# namespace of amazon tools
$namespace = 'ns=http://ec2.amazonaws.com/doc/2009-07-15/'
# debug to make true enter any value, to make false set to empty 
$debug = ""
# set if host to base unless specified as parameter
if ($args[0] -eq $null) {
 help-message
} else { 
  $instanceId = $args[0].ToLower()
}
if ($args[1] -eq $null) {
 help-message
} else { 
  $ec2_bundlename = $args[1].ToLower()
}
if ($args[2] -eq $null) {
 help-message
} else { 
  $s3_prefix = $args[2]
}

#
#issue bundle command
#
$today = Get-Date -format yyMMdd
$s3_bucket_name = $env:S3_AMI_BUCKET

Write-Host "Bundling $ec2_bundlename  $instanceId to Bucket $s3_bucket_name with Prefix $s3_prefix"
if ($Env:EC2_URL -eq $null -or $env:EC2_URL.length -eq 0) {
   $ec2 = new-object Amazon.EC2.PowerEC2Dream($Env:AMAZON_ACCESS_KEY_ID,$Env:AMAZON_SECRET_ACCESS_KEY)
} else {
   $ec2 = new-object Amazon.EC2.PowerEC2Dream($Env:AMAZON_ACCESS_KEY_ID,$Env:AMAZON_SECRET_ACCESS_KEY, $env:EC2_URL)
}
$res = $ec2.BundleInstance($instanceId, $s3_bucket_name, $s3_prefix, $env:AMAZON_ACCESS_KEY_ID, $env:AMAZON_SECRET_ACCESS_KEY)
$instance_id = $res["InstanceId"]
$bundle_id = $res["BundleId"]
Write-Host "*** Bundling $instance_id. Bundle Id is $bundle_id  Be Patient....."
$bundle_state = ""
[Array] $bundle_array = $bundle_id
$res = $ec2.DescribeBundleTasks($bundle_array)
foreach ($r in $res) {
   $bundle_state = $r["BundleState"]
}
while (($bundle_state -ne "complete") -and ($bundle_state -ne "failed")) {
   Write-Host "*** Waiting for Bundling to complete. Bundle State is $bundle_state"
   Start-Sleep -s 30
   $res = $ec2.DescribeBundleTasks($bundle_array)
   foreach ($r in $res) {
      $bundle_state = $r["BundleState"]
   }
}
Write-Host "*** Bundle State is $bundle_state"
#
# register image 
#
if ($bundle_state.Equals("failed")) {
    Write-Host "*** Error bundle failed"
}
if ($bundle_state.Equals("complete")) {
   Write-Host "Registering $s3_bucket_name/$s3_prefix.manifest.xml..."
   $res = $ec2.RegisterImage($s3_bucket_name+"/"+$s3_prefix+".manifest.xml")
   Write-Host "*** Registered Image $res"
}
Write-Host "*** Bundle Complete"

