#
# Migrate windows instance from one bucket to another
# Very much a first cut of the script. 
#
#
# This script assumes Cloudberry Explorer is installed and defined to powershell via 
#     Add-PSSnapin CloudBerryLab.Explorer.PSSnapIn
#


Function help_message 
{
 Write-Host ""
 Write-Host "Usage: migrate.ps1  image-prefix source-bucket destination-bucket"
 Write-Host ""
 Write-Host "image-prefix:       Prefix of Image files to migrate"
 Write-Host "source-bucket:      bucket containing the image"
 Write-Host "destination-bucket: bucket where image is migrated"
 Write-Host ""
 exit
}

$s = $env:EC2DREAM_HOME+"/ps1/settings.ps1"

. $s

# check parameters
if ($args[0] -eq $null) {
 help_message
} else { 
  $image_prefix = $args[0]
}
if ($args[1] -eq $null) {
 help_message
} else { 
  $source_bucket = $args[1]
}
if ($args[2] -eq $null) {
 help_message
} else { 
  $destination_bucket = $args[2]
}

Write-Host "*** migrate.ps1 $image_prefix $source_bucket $destination_bucket"

$s3 = Get-CloudS3Connection -Key $Env:AMAZON_ACCESS_KEY_ID -Secret $Env:AMAZON_SECRET_ACCESS_KEY
$destination = $s3 | Select-CloudFolder -Path $destination_bucket
$image_prefix = $image_prefix + "*"
$s3 | Select-CloudFolder -Path $source_bucket | Copy-CloudItem -Destination $destination -Filter $image_prefix

$fld = $s3 | Select-CloudFolder -Path $destination_bucket
$items = $fld |Get-CloudItem -Filter $image_prefix

$items | Add-CloudItemPermission -UserName "ec2-bundled-images@amazon.com" -Read

Write-Host "*** Migrate Complete"
Write-Host "*** Image needs to be registered at the destination region before usage" 

