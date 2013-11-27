# == Class: role
#
# This class takes the roles from the Facter variabe role_name1 to role_name4 and 
# either calls the role::role_nameX class
# or
#  if the prefix parameter is set then it will call directly the module for the role.
# This allow a design pattern for modules where custom modules have a prefix (typically companyname) 
# This separates them from standard library modules downloaded from puppetforge which should not be customized.
#  
#
# RESOVLING CLASS PARAMETERS 
# the role class parameters can be resolved from the hier role/<role_name>.yaml file
#
class role( $prefix  = undef )
 { 
  include stdlib
  if $role_name1 != '' and $prefix == undef {
     $role1 = "role::${role_name1}"
   } elsif $role_name1 != '' {
      $role1 = "${prefix}-${role_name1}"
   } else { 
  	 $role1 = 'role::base' 
  }
  if $role_name2 != '' and $prefix == undef {
      $role2 = "role::${role_name2}"
   } elsif $role_name2 != '' { 
     $role2 = "${prefix}-${role_name2}"  
   } else { 
 	 $role2 = '' 
  }   
  if $role_name3 != '' and $prefix == undef  {
      $role3 = "role::${role_name3}"
   } elsif $role_name3 != '' { 
     $role3 = "${prefix}-${role_name3}"	  
   } else { 
 	 $role3 = '' 
  }  
  if $role_name4 != '' and $prefix == undef  {
     $role4 = "role::${role_name4}"
   } elsif $role_name4 != '' { 
     $role4 = "${prefix}-${role_name4}" 
   } else { 
 	 $role4 = '' 
  }  
  $roles = [ $role1, $role2, $role3, $role4]
  if $prefix  != undef {  
     info ("*** Direct Module Prefix ${prefix} ***")
  } 	 
  info ("*** Roles ${role_name1} ${role_name2} ${role_name3} ${role_name4} ***")
  if $prefix  != undef {
     info ("*** Modules ${role1} ${role2} ${role3} ${role4} ***")
  } else { 
     info ("*** Classes ${role1} ${role2} ${role3} ${role4} ***")
  }
  # Require base first in case it does required setup
  if member($roles, 'role::base') {
    require role::base
  }
  if $prefix != undef and member($roles, "${prefix}-base") {
    $base_module = "${prefix}-base"
    require $base_module
  }
  include $roles
}
