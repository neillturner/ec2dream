#
#  Call Modules and Classes based on up to 4 roles 
#
#  If the prefix parameter is set then it will go directly to the module for the role.
#  This allow a design pattern for modules where custom modules have a prefix (typically companyname) 
#  This separates them from standard library modules downloaded from puppetforge which should not be customized.
#  
#  Otherwise it will call the class in the role module first. i.e. role::<role_name>
#  
#  For example:
#   If prefix is set to mycompany 
#        it will go directly to the mycompany-base  module and runthe init class
#   Otherwise it will call the class role::base      
#
node default {
 Exec {
     path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
  }
     # check if roles defined in node hostname hiera file.
     $hiera_role1 = hiera('role::role_name1','')
     if $hiera_role1 != '' {
        notify {"*** Found heira role::role_name1 value ${hiera_role1} ignoring all facter role values ***": }
	    $role_name1 = hiera('role::role_name1','')
        $role_name2 = hiera('role::role_name2','')
        $role_name3 = hiera('role::role_name3','')
  	    $role_name4 = hiera('role::role_name4','')
	 }	
    # class { 'role': }
	# Or to do Direct Module Prefix 
	class { 'role' : prefix => 'mycompany' } 
 } 


 

 
