#!/bin/bash
clear
stty erase '^?'

echo -n "Do you want to update your Ubuntu packages? (Y/n): "
read upgrade
if [ -z "$upgrade" ]
then
upgrade=y
fi

for lang in `apt-cache pkgnames language-pack-gnome- | grep -i base`
do
array=( "${array[@]}" "$lang" )
done
element_count=${#array[@]}
# Special syntax to extract number of elements in array.
index=0
while [ "$index" -lt "$element_count" ]
do    # List all the elements in the array.
  echo $index.${array[$index]}
  #    ${array[index]} also works because it's within ${ ... } brackets.
  let "index+=1"
done
langnumber=200
array[$langnumber]="language-pack-gnome-es-base"
while [ $langnumber -ge $element_count -o $langnumber -lt 0 ]
do
echo
echo "---------------------------------------------------------"
echo "Please enter the number of your language pack            "
echo "Press ENTER for default one (language-pack-gnome-es-base)"
echo "---------------------------------------------------------"
read langnumber
if [ -z "$langnumber" ]
then
array[0]="language-pack-gnome-es-base"
break
fi
echo
done
LANGTOINSTALL=${array[$langnumber]}
echo "Your selected language pack to install is" $LANGTOINSTALL
echo

echo "---------------------------------------------------------------------"
echo "Modifying /etc/hosts file. Enter your IP address: "
echo "Press ENTER for default one (127.0.1.1)"
read ipaddr
if [ -z "$ipaddr" ]
then
ipaddr=127.0.1.1
fi
echo "\"your IP address is\" = $ipaddr"
echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
echo "Enter DNS name for your URL: "
echo "Press ENTER for default one (magentoshop.com)"
read url
if [ -z "$url" ]
then
url=magentoshop.com
fi
echo "\"your URL is\" = "$url""
echo "---------------------------------------------------------------------"

echo -n "Magento Admin Username (Default=admin): "
read adminuser
if [ -z "$adminuser" ]
then
adminuser=admin
fi
echo -n "Magento Admin Password (Default=password): "
read adminpass
if [ -z "$adminpass" ]
then
adminpass=password
fi
echo -n "Magento Admin First Name: "
read adminfname
echo -n "Magento Admin Last Name: "
read adminlname
echo -n "Magento Admin Email Address: "
read adminemail
echo -n "Include Sample Data in Magento? (Y/n) "
echo -n "Press ENTER for default one (Yes)"
read sample
if [ -z "$sample" ]
then
sample=y
fi

if [ "$upgrade" = "y" ]; then
sudo apt-get update -y
sudo apt-get upgrade -y
fi
# uncomment to install language
# sudo apt-get -y install $LANGTOINSTALL
sudo apt-get install php-pear -y
sudo apt-get install php5-dev -y
sudo apt-get install libmysqlclient15-dev -y
sudo apt-get install make -y
sudo pecl install pdo

#sudo sed -i 's/\(^;[[:space:]]*extension=modulename.extension\)/\1\nextension=pdo.so/g' /etc/php5/cli/php.ini
#sudo vi /etc/php5/cli/php.ini
#    configuration option "php_ini" is not set to php.ini location
#    You should add "extension=pdo.so" to php.ini

sudo apt-get install php5-mysql -y

#sudo sed -i 's/\(^;[[:space:]]*extension=modulename.extension\)/\1\nextension=pdo_mysql.so/g' /etc/php5/cli/php.ini
    #Modificar límite de memoria en php.ini:
    #memory_limit = 32M      ; Maximum amount of memory a script may consume (32MB)
    #memory_limit = 50M
sudo sed -i 's/\(^memory_limit.*\)/#\1\nmemory_limit = 70M/g' /etc/php5/cli/php.ini

sudo pecl install pdo_mysql

#sudo vi /etc/php5/cli/php.ini
#    configuration option "php_ini" is not set to php.ini location
#    You should add "extension=pdo_mysql.so" to php.ini

sudo apt-get install php5-mcrypt -y
sudo apt-get install php5-curl -y
sudo apt-get install php5-gd -y
sudo apt-get install apache2 -y
sudo apt-get install mysql-server -y

#$ mysql -h localhost -u root -pmysqlpassword
#mysql> CREATE DATABASE magentodb;
#mysql> show databases;
#mysql> use magentodb;
#mysql> CREATE USER magentodbadmin@localhost IDENTIFIED BY 'magentodbpasswd';
#mysql> grant all privileges on magentodb.* to magentodbadmin@localhost ;

clear
stty erase '^?'
echo "---------------------------------------------------------------------"
echo "Enter again your MySQL \"root\" Administrator Password: "
echo "---------------------------------------------------------------------"
read mysqlpassword


mysql -h localhost -uroot -p$mysqlpassword -e "CREATE DATABASE magentodb;"
mysql -h localhost -uroot -p$mysqlpassword -e "show databases;"
mysql -h localhost -uroot -p$mysqlpassword -e "CREATE USER magentodbadmin@localhost IDENTIFIED BY 'magentodbpasswd';"
mysql -h localhost -uroot -p$mysqlpassword -e "grant all privileges on magentodb.* to magentodbadmin@localhost;"

#echo "To install Magento, you will need a blank database ready with a user assigned to it."
#echo
#echo -n "Do you have all of your database information? (y/n) "
#read dbinfo
#if [ "$dbinfo" = "y" ]; then
#echo
#echo -n "Database Host (usually localhost): "
#read dbhost
dbhost=localhost
#echo -n "Database Name: "
#read dbname
dbname=magentodb
#echo -n "Database User: "
#read dbuser
dbuser=magentodbadmin
#echo -n "Database Password: "
#read dbpass
dbpass=magentodbpasswd


#sudo vi /etc/hosts
#    IP    magento.com
#ADD TEXT TO THE END OF FILE:
#sed '$a\Add Text to end' /etc/apache2/apache2.conf
#sudo sed -i "$a\IP myurl.com" /etc/hosts
# Con variable:
sudo sed -i "\$a\\$ipaddr $url" /etc/hosts

sudo apt-get install libapache2-mod-php5 php5-common php5-cgi -y
sudo a2enmod ssl
sudo a2ensite default-ssl
sudo a2enmod rewrite
sudo a2enmod suexec
sudo a2enmod include

#sudo vi /etc/apache2/apache2.conf
#        ServerName  localhost
sudo sed -i "s/\(^ServerRoot.*\)/\1\nServerName localhost/g" /etc/apache2/apache2.conf

#Forcing Apache to redirect HTTP traffic to HTTPS
sudo sed -i "s/\(ServerAdmin.*\)/\1\nServerName $url\nRedirect \/ https:\/\/$url\//g" /etc/apache2/sites-available/default
sudo sed -i "s/\(ServerAdmin.*\)/\1\nServerName $url/g" /etc/apache2/sites-available/default-ssl


echo "######################################################################################################################"
echo " The installation process will stop here with the following warning if you launch the script through a SSH session:"
echo "           \"This command may affect the current SSH connections. Do you want to continue (y | n)?\""
echo " SOLUTION: Press \"y\" to complete the rest of the process"
echo "######################################################################################################################"
# FIREWALL:
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

#sudo vi sudo vi /etc/php5/apache2/php.ini
#    extension=pdo.so
#    extension=pdo_mysql.so
#    Modificar límite de memoria en php.ini:
    #memory_limit = 16M      ; Maximum amount of memory a script may consume (32MB)
#    memory_limit = 50M
sudo sed -i 's/\(.*extension=modulename.extension\)/\1\nextension=pdo.so/g' /etc/php5/apache2/php.ini
sudo sed -i 's/\(.*extension=modulename.extension\)/\1\nextension=pdo_mysql.so/g' /etc/php5/apache2/php.ini
sudo sed -i 's/\(^memory_limit.*\)/#\1\nmemory_limit = 50M/g' /etc/php5/apache2/php.ini
sudo /etc/init.d/apache2 restart

sudo mkdir -p /var/www/magento
cd /var/www/magento

if [ "$sample" = "y" ]; then
echo
echo "Now installing Magento with sample data..."
echo
echo "Downloading packages..."
echo
sudo wget http://www.magentocommerce.com/downloads/assets/1.3.2.3/magento-1.3.2.3.tar.gz
sudo wget http://www.magentocommerce.com/downloads/assets/1.2.0/magento-sample-data-1.2.0.tar.gz
echo
echo "Extracting data..."
echo
sudo tar -zxvf magento-1.3.2.3.tar.gz
sudo tar -zxvf magento-sample-data-1.2.0.tar.gz
echo
echo "Moving files..."
echo
sudo mv magento-sample-data-1.2.0/media/* magento/media/
sudo mv magento-sample-data-1.2.0/magento_sample_data_for_1.2.0.sql magento/data.sql
sudo mv magento/* magento/.htaccess .
echo
echo "Setting permissions..."
echo
sudo chmod o+w var var/.htaccess app/etc
sudo chmod -R o+w media
echo
echo "Importing sample products..."
echo
mysql -h $dbhost -u $dbuser -p$dbpass $dbname < data.sql
echo
echo "Initializing PEAR registry..."
echo
sudo ./pear mage-setup .
echo
echo "Downloading packages..."
echo
sudo ./pear install magento-core/Mage_All_Latest
echo
echo "Cleaning up files..."
echo
sudo rm -rf downloader/pearlib/cache/* downloader/pearlib/download/*
sudo rm -rf magento/ magento-sample-data-1.2.0/
sudo rm -rf magento-1.3.2.3.tar.gz magento-sample-data-1.2.0.tar.gz
sudo rm -rf index.php.sample .htaccess.sample php.ini.sample LICENSE.txt STATUS.txt data.sql
echo
echo "Installing Magento..."
echo

sudo php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "$dbhost" \
--db_name "$dbname" \
--db_user "$dbuser" \
--db_pass "$dbpass" \
--url "$url" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--use_secure_admin "no" \
--admin_firstname "$adminfname" \
--admin_lastname "$adminlname" \
--admin_email "$adminemail" \
--admin_username "$adminuser" \
--admin_password "$adminpass"

echo
echo "Finished installing Magento"
echo

else
echo "Now installing Magento without sample data..."
echo
echo "Downloading packages..."
echo

sudo wget http://www.magentocommerce.com/downloads/assets/1.3.2.3/magento-1.3.2.3.tar.gz
echo
echo "Extracting data..."
echo

sudo tar -zxvf magento-1.3.2.3.tar.gz
echo
echo "Moving files..."
echo

sudo mv magento/* magento/.htaccess .
echo

echo "Setting permissions..."
echo

sudo chmod o+w var var/.htaccess app/etc
sudo chmod -R o+w media

echo
echo "Initializing PEAR registry..."
echo
sudo ./pear mage-setup .
echo
echo "Downloading packages..."
echo
sudo ./pear install magento-core/Mage_All_Latest

echo
echo "Cleaning up files..."
echo

sudo rm -rf downloader/pearlib/cache/* downloader/pearlib/download/*
sudo rm -rf magento/ magento-1.3.2.3.tar.gz
sudo rm -rf index.php.sample .htaccess.sample php.ini.sample LICENSE.txt STATUS.txt

echo
echo "Installing Magento..."
echo

sudo php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "$dbhost" \
--db_name "$dbname" \
--db_user "$dbuser" \
--db_pass "$dbpass" \
--url "$url" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--use_secure_admin "no" \
--admin_firstname "$adminfname" \
--admin_lastname "$adminlname" \
--admin_email "$adminemail" \
--admin_username "$adminuser" \
--admin_password "$adminpass"
echo
echo "Finished installing Magento"
fi

sudo chown -R www-data:www-data /var/www/magento/
sudo /etc/init.d/apache2 restart
clear
echo "#########################################################################################################################################"
echo "MySQL \"root\" Administrator Password: $mysqlpassword"
echo "MySQL Database Name for Magento = magentodb"
echo "MySQL Database Administrator for Magento = magentodbadmin"
echo "MySQL Database Administrator's Password for Magento = magentodbpasswd"
echo
echo "Magento Admin Username = $adminuser "
echo "Magento Admin Password = $adminpass "
echo "Magento Admin First Name: $adminfname"
echo "Magento Admin Last Name: $adminlname"
echo "Magento Admin Email Address: $adminemail"
echo
echo "Magento default locale = en_US"
echo "Magento default timezone = America/Los_Angeles"
echo "Magento default currency = USD"
echo
echo
echo "Add \"$url\" to your DNS System!"
echo "Check your Magento URL with a browser: http://$url/magento"
echo
echo "Magento Translations can be found at http://www.magentocommerce.com/langs"
echo "Example of how to install the Spanish (Spain) translation with modern theme (Full package Download):"
echo "        sudo apt-get install unzip -y"
echo "        unzip es_ES_modern_full_package.zip  "
echo "        sudo cp -r app/locale/es_ES/ /var/www/magento/app/locale/"
echo "        sudo cp -r app/design/frontend/default/modern/locale/es_ES/ /var/www/magento/app/design/frontend/default/default/locale/"
echo "        sudo chown -R www-data.www-data /var/www/magento/app"
echo "          Refresh Magento Cache from Magento Admin Panel -> System-> Cache Management"
echo
echo "#########################################################################################################################################"