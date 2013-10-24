REM
REM  Customized pocketknife to run puppet apply on remote node 
REM
REM  puppet_push  
REM  
REM  Env Variable EC2_PUPPET_REPOSITORY  puppet_repository
REM  Env Variable EC2_PUPPET_PARAMETERS  puppet_parameters
REM
@echo on
cd %EC2_PUPPET_REPOSITORY%
echo pocketknife_puppet %EC2_PUPPET_PARAMETERS%
pocketknife_puppet %EC2_PUPPET_PARAMETERS%


