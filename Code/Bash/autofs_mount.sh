#!/bin/bash
 
# Setting Variables
SVCUSERNAME=$arg1
SVCPASSWORD=$arg2
SHAREENV=$arg3
SHARENAME="myapp"
 
# Install dependencies
yum -y install cifs-utils
yum -y install autofs
yum -y install keyutils
yum -y install krb5-workstation krb5-libs
 
# Generate keytab using Centrify
adkeytab --adopt --user ${SVCUSERNAME} --local -w ${SVCPASSWORD} --keytab /etc/${SVCUSERNAME}.keytab -V ${SVCUSERNAME} -p ${SVCPASSWORD} -f
 
# Request kerberos ticket
/usr/share/centrifydc/kerberos/bin/kinit ${SVCUSERNAME} -kt /etc/${SVCUSERNAME}.keytab
 
# Configure autofs for cifs mountpoints
echo "/cifs /etc/auto.cifs" >> /etc/auto.master
 
# Configure share to automount using the kerberos ticket
echo "${SHARENAME}       -fstype=cifs,noperm,cruid=0,uid=999,gid=999,forceuid,forcegid,sec=krb5   ://pgweuwpfil002.pgds.local/DATA/${SHARENAME}/${SHAREENV}" >> /etc/auto.cifs
 
# Enable rpcbind and autofs services and start them
systemctl enable rpcbind
systemctl enable autofs
systemctl start rpcbind
systemctl start autofs
 
# Reload autofs config
systemctl reload autofs
 
# Refresh Kerberos ticket every 6 hours
(crontab -l; echo "0 */6 * * *       /usr/share/centrifydc/kerberos/bin/kinit ${SVCUSERNAME} -kt /etc/${SVCUSERNAME}.keytab")|awk '!x[$0]++'|crontab -
