REM
REM  Customized pocketknife to run chef-solo on remote node 
REM
REM  chef_push  chef_node ec2_server_name 
REM  
REM  Env Variable EC2_CHEF_REPOSITORY  chef_repository
REM  Env Variable EC2_CHEF_PARAMETERS  chef_parameters
REM  To set a chef version to install add -j 11.4.2 to the end of the pocketknife command 
REM
@echo on
erase  "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 
erase  "%EC2_CHEF_REPOSITORY%\nodes\ec2-*.compute-1.amazonaws.com.json" 
copy "%EC2_CHEF_REPOSITORY%\nodes\%1.json" "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 
cd %EC2_CHEF_REPOSITORY%
pocketknife %EC2_CHEF_PARAMETERS% %2
REM if "%3"=="" (
REM  pocketknife -ivk "%EC2_SSH_PRIVATE_KEY%" %2
REM  
REM ) else (
REM  if "%4"=="" (
REM    pocketknife -ivk "%EC2_SSH_PRIVATE_KEY%" -s %3 %2
REM  ) else (
REM    echo "WARNING: ssh tunnel to localhost port %4%"
REM    pocketknife -ivk "%EC2_SSH_PRIVATE_KEY%" -s %3 -l %4 %2
REM  )  
REM )  
erase  "%EC2_CHEF_REPOSITORY%\nodes\%2.json" 