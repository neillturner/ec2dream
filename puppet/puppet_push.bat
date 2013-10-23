REM
REM  Customized pocketknife to run puppet apply on remote node 
REM
REM  puppet_push  puppet_manifest ec2_server_name [ssh_user]
REM  
REM  Env Variable EC2_SSH_PRIVATE_KEY private_key
REM  Env Variable EC2_PUPPET_REPOSITORY  puppet_repository
REM
@echo on
cd %EC2_PUPPET_REPOSITORY%
if "%3"=="" (
 pocketknife_puppet -ivk "%EC2_SSH_PRIVATE_KEY%" -m %1 %2
 
) else (
 if "%4"=="" (
   pocketknife_puppet -ivk "%EC2_SSH_PRIVATE_KEY%" -m %1 -s %3 %2
 ) else (
   echo "WARNING: ssh tunnel to localhost port %4%"
   pocketknife_puppet -ivk "%EC2_SSH_PRIVATE_KEY%" -m %1 -s %3 -l %4 %2
 )  
)

