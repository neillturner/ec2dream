# Install The MySQL Database Server
apt-get install mysql-server mysql-client -y

# Install The Apache Webserver And PHP
apt-get install apache2 apache2-doc apache2-mpm-prefork apache2-utils libexpat1 libapache2-mod-php5 php5-common php5-gd php5-idn php-pear php5-imap php5-mcrypt php5-mhash php5-mysql php5-sqlite php5-xmlrpc php5-xsl php5-curl -y



# Install php-imap, an optional sugar dependency for retrieving emails from external accounts
# apt-get install php-imap -y

# Change the memory limit to64M so we can upload decent sized files in Sugar
sed -i '/memory_limit/s/16M/64M/g' /etc/php5/apache2/php.ini
sed -i '/upload_max_filesize/s/2M/20M/g' /etc/php5/apache2/php.ini

#Restart apache to pickup the php.ini changes above
/etc/init.d/apache2 restart 

#Install SugarCRM
mkdir /var/www/sugarcrm
cd /tmp
wget http://www.sugarforge.org/frs/download.php/5961/SugarCE-5.2.0j.zip
unzip SugarCE-5.2.0j.zip
cd SugarCE-Full-5.2.0j/
mv * /var/www/sugarcrm/
chown -R www-data:www-data /var/www/sugarcrm
