REM
REM  Customized pocketknife to run chef-solo on remote node 
REM
REM  chef_push  chef_node ec2_server_name [ssh_user]
REM  
REM  Env Variable EC2_SSH_PRIVATE_KEY private_key
REM  Env Variable EC2_CHEF_REPOSITORY  chef_repository 
REM
@echo on
erase  "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 
erase  "%EC2_CHEF_REPOSITORY%\nodes\ec2-*.compute-1.amazonaws.com.json" 
copy "%EC2_CHEF_REPOSITORY%\nodes\%1.json" "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 
cd %EC2_CHEF_REPOSITORY%
IF "%3"=="" (
 pocketknife -ivk "%EC2_SSH_PRIVATE_KEY%" %2
 
) else (
 pocketknife -ivk "%EC2_SSH_PRIVATE_KEY%" -s %3 %2 
)  
erase  "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 