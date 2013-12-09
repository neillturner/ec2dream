# Puppet Roles and Hiera Parameter Hierachy

This is a design pattern to implement roles like Chef and separate class parameters into 
a parameter hierachy also like chef.

Set up to 4 role_names in Facter for the server.
 -set up to 4 role_names in Facter 
 -the role class gets called from the site.pp 
 -the role::<role_name> classes called for each role and the classes executed
 -the class parameters are resolved in the hiera hierachy:
 
       nodes/%{hostname}
       roles/%{role_name1}
       roles/%{role_name2}
       roles/%{role_name3}
       roles/%{role_name4}
       modules/%{module_name}
       common 
	   
 -role parameters can be stored in the roles/%{role_name} and can be overriden for parameter 

values for the node,roles, module or common. parameters that are common to all roles can be stored in the common file  

This can be tested by running in masterless puppet
  
    export FACTER_role_name1=base
    export FACTER_role_name2=webserver
    puppet apply --modulepath ./modules manifests/site.pp
	
This will also be able to run in puppet master, just need to decide how to set the  FACTER_role_nameX 


NOTE: This still need so additional error checking and more testing.  	

