#
#  install postgresql on ubuntu
# Configure an admin (postgres) password,
# and setup the MD5 password authentication. 8.3.5 or higher is the recommended version.
# Additionally, make sure the postgresql-contrib modules is installed (UUID requires it).
# Once it is installed, and to make the database accessible from anywhere, so that external developers or yourself
# can access it easily with PgAdmin3, psql or any other development tool. Locate and edit the postgresql.conf file, 
# and uncomment the following line, assigning this new value:
#             listen_addresses='*'
#This makes the database be listening in all the interfaces available in your system and not only in localhost (default).
#Just for safety purposes, this assumes you have a firewall in your local LAN preventing outsiders to access the database. 
#

sudo apt-get install postgresql-8.3 postgresql-contrib-8.3

# Uncomment the following to set the postgres password

#sudo su - postgres -c psql
#alter role postgres with password 'new_password';
#\q
# rm postgresql from startup. 
rm /etc/rc2.d/S19postgresql-8.3
rm /etc/rc3.d/S19postgresql-8.3
rm /etc/rc5.d/S19postgresql-8.3
rm /etc/rc4.d/S19postgresql-8.3

rm /etc/rc0.d/K21postgresql-8.3
rm /etc/rc6.d/K21postgresql-8.3
rm /etc/rc1.d/K21postgresql-8.3



