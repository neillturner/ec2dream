#
#  Can set up to 4 roles by setting the a custom Facter variable role_name1 to role_name4  
#  e.g. before running puppet 
#         export FACTER_role_name1=base
#         export FACTER_role_name2=webserver
#
node default {
  Exec {
     path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
  }
  class { 'role' : } 
} 


 

 
