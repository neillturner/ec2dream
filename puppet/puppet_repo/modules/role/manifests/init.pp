# == Class: role
#
# This class takes the roles from the Facter variabe role_name1 to role_name4 and 
# calls the role::role_nameX class 
#
# RESOVING CLASS PARAMETERS 
# the role class parameters can be resolved from the hier role/<role_name>.yaml file
#
class role { 
  include stdlib
  if $role_name1 != '' {
     $role1 = "role::${role_name1}"
   } else { 
 	 $role1 = 'role::base' 
  }
  if $role_name2 != '' {
     $role2 = "role::${role_name2}"
   } else { 
 	 $role2 = '' 
  }   
  if $role_name3 != '' {
     $role3 = "role::${role_name3}"
   } else { 
 	 $role3 = '' 
  }  
  if $role_name4 != '' {
     $role4 = "role::${role_name4}"
   } else { 
 	 $role4 = '' 
  }  
  $roles = [ $role1, $role2, $role3, $role4] 
  info ("*** Roles ${role1} ${role2} ${role3} ${role4} ****")
  # Require base first in case it does required setup
  if member($roles, 'role::base') {
    require role::base
  }
  include $roles
}
