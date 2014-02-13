# == Class: mycompany-base
#
# classes to run for the base role
# class parameters can be coded here or resolved via the hiera parameter hierachy 
#
class mycompany-base 
{

 class { 'ntp': }
 
}
