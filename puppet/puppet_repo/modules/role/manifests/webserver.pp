# == Class: role::webserver
#
# classes for the role webserver
# class parameters can be coded here or resolved via the hiera parameter hierachy  
#
class role::webserver {
 
 class { 'apache': }

   }
