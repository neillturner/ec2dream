#
# EC2 Settings for shell powershell scripts
#
# location of EC2 and S3 .NET
[System.Reflection.Assembly]::LoadFrom("$pwd\ps1\Amazon.EC2.dll")
[Reflection.Assembly]::LoadFrom("$pwd\ps1\Affirma.ThreeSharp.dll")
[Reflection.Assembly]::LoadFrom("$pwd\ps1\Affirma.ThreeSharp.Wrapper.dll")
#
# This should already be set.
# $env:AMAZON_ACCESS_KEY_ID="<AMAZON_ACCESS_KEY_ID>" 
# $env:AMAZON_SECRET_ACCESS_KEY="<AMAZON_SECRET_ACCESS_KEY>"
# $env:S3_PREFIX="<insert prefix i.e. company name>"
# uncomment the next 2 lines if in EU region
# $env:AWS_CALLING_FORMAT="SUBDOMAIN"
# $env:EC2_URL="https://eu-west-1.ec2.amazonaws.com/"
# $env:EC2_PRIVATE_KEY="c:\xxxxxxxxxxxxxxxxxxxxx.pem"
# $env:EC2_CERT="c:\yyyyyyyyyyyyyyyyyyyyyyyyyy.pem"






