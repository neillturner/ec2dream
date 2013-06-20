REM
REM  vagrant up command 
REM
REM  vagant_up <directory> <command>
REM  
REM  <directory> is directory of Vagrantfile
REM  <command> is command for vagrant i.e. up or destroy
REM
@echo on
set VAGRANT_LOG=debug
cd "%1"
vagrant %2
