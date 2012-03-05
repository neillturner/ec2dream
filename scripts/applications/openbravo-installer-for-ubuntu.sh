#
# This is an install from the Canonical partner repository
#
sudo apt-get update
sudo apt-get install openbravo-erp

# disable the start at boot time
update-rc.d -f openbravo-erp remove

#
# To install postgresql on a separate server to openbravo
#
# 1. install postgresql on a separate server 
# 2. change the openbravo server to use the postgresql server by 
# editing /opt/OpenbravoERP-2.50/openbravo-erp/config/Openbravo.properties as follows:
#
# a. Replace localhost with the IP address of the PostgreSQL server.
#
#          bbdd.url=jdbc:postgresql://localhost:5432
#
# b. set the password for the postgres database super user.
#
#          bbdd.systemPassword=postgres
#
# 3. on the openbravo server recompile using the new PostreSQL server:
#
#          cd /opt/OpenbravoERP-2.50/openbravo-erp/
#          ant install.source
#
# 4. You can remove in Tomcat server the /etc/init.d/openbravo-erp-postgresql file
#    and also all the lines in /etc/init.d/openbravo-erp that contain "/etc/init.d/openbravo-erp-postgresql".
#
##