name             'mycompany_webserver'
description      'Installs/Configures apache webserver'
maintainer       'mycompany'
maintainer_email 'infrastructure.team@mycompany.com'
license          'All rights reserved'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
depends          'apache2'
depends          'aws'
