node default {
Exec {
    path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
}
 
include apache
 
#a2mod { "Enable proxy mod":
#    name => "proxy",
#    ensure => "present"
#}
 
#a2mod { "Enable proxy_http mod":
#    name => "proxy_http",
#    ensure => "present"
#}
 
#apache::vhost::proxy { "my-site":
#    servername => "my-site.com",
#    port => 80,
#    dest => "http://localhost:9015",
#    vhost_name => "my-site"
#}
}

 

 
