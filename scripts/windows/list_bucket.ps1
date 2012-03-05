#
# List the Contents of a Bucket
#
Set-ExecutionPolicy RemoteSigned
. ./settings.ps1
$threeSharp = new-object Affirma.ThreeSharp.Wrapper.ThreeSharpWrapper($env:AMAZON_ACCESS_KEY_ID,$env:AMAZON_SECRET_ACCESS_KEY)
# this is just to show the methods
get-member -inputobject $threeSharp
# list bucket 
$res  = $threeSharp.ListBucket("<bucket name>")
format-XML -inputobject $res 