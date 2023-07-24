#!/bin/bash
adbVersion="5.7.0-rhel5-x86_64"
adbRPMVersion="5.7.0-217-rhel5.x86_64"


if [ "$EUID" -ne 0 ]; then 
  echo "[ERR] Please run as root"
  exit 999
fi

echo "[INFO] Checking if Centrify is installed"
centrifyVersion=$(dzinfo --version)
centrifyInstalled=$(echo $centrifyVersion | wc -l)
if [ $centrifyInstalled -ne 1 ]; then 
	echo "[ERR] Centrify is not installed on this host, cannot install Centrify ADBindProxy, exiting"
	exit 99
fi

echo "[INFO] Found Centrify installed, continuing." 

echo "[INFO] Checking if Centrify ADBindProxy version $adbVersion is installed"
adbInstalled=$(yum list installed CentrifyDC-adbindproxy|grep -c 'adbindproxy')

if [ $adbInstalled -ne 1 ]; then 
	echo "[INFO] AdBind Proxy not installed or not recent enough, downloading Centrify ADBindProxy from repo"
	wget "http://centrify-adbindproxy-$adbVersion.tgz" -nv -O "/tmp/centrify-adbindproxy-$adbVersion.tgz"

	retCode=$?
	if [ $retCode -ne 0 ]; then
		echo "[ERR] Error downloading Centrify ADBindProxy from Artifactory: $retCode"
		exit $retCode
	fi

	echo "[INFO] Extracting ADBindProxy archive"
	tar xvf "/tmp/centrify-adbindproxy-$adbVersion.tgz" --directory /tmp

	retCode=$?
	if [ $retCode -ne 0 ]; then
		echo "[ERR] Error extracting archive: $retCode"
		exit $retCode
	fi
fi

varSpaceUsed=$(df -h /var | tail -1 | awk '{print $5}' | awk -F% '{print $1}')
if [ $varSpaceUsed -gt 95 ]; then 
	echo "/var filesystem more than 95% in use, cleaning up yum packages to free space"
	yum clean all
fi

echo "[INFO] Installing Samba tools"
yum install samba samba-client samba-common samba-winbind -y

retCode=$?
if [ $retCode -ne 0 ]; then
    echo "[ERR] Error installing Samba tools: $retCode"
    exit $retCode
fi

echo "[INFO] Installing Centrify ADBindProxy"
yum install "/tmp/CentrifyDC-adbindproxy-$adbRPMVersion.rpm" -y

retCode=$?
if [ $retCode -ne 0 ] && [ $retCode -ne 1 ]; then
    echo "[ERR] Error installed Centrify ADBindProxy: $retCode";
    exit $retCode;
fi;

rm /var/centrify/tmp/adbindproxy.pl.rsp
echo "ADBINDPROXY_VERSION=5.7.0-217" > /var/centrify/tmp/adbindproxy.pl.rsp
echo "PLATFORM=RHEL" >> /var/centrify/tmp/adbindproxy.pl.rsp
echo "SAMBA_PATH=/usr" >> /var/centrify/tmp/adbindproxy.pl.rsp

echo "[INFO] Running ADBindProxy Setup"
/usr/share/centrifydc/bin/adbindproxy.pl --nonInteractive --responseFile /var/centrify/tmp/adbindproxy.pl.rsp --noTestShare

retCode=$?
if [ $retCode -ne 0 ]; then 
    echo "[ERR] Error configuring ADBindProxy : $retCode"
    exit $retCode
fi

rm /var/centrify/tmp/adbindproxy.pl.rsp

echo "[INFO] Checking if TCP Port 445 is open on firewall"
fwOpen=$(firewall-cmd --list-ports|grep -c '445/tcp')
if [ $fwOpen -ne 1 ]; then
	echo "Opening TCP Port 445 on host firewall"
	firewall-cmd --permanent --add-port=445/tcp

	retCode=$?
	if [ $retCode -ne 0 ]; then
		echo "[ERR] Error amending host firewall config: $retCode"
		exit $retCode
	fi

	echo "Reloading host firewall"
	firewall-cmd --reload

	retCode=$?
	if [ $retCode -ne 0 ]; then
		echo "[ERR] Error reloading host firewall: $retCode"
		exit $retCode
	fi
fi

echo "Restarting Centrify Samba"
systemctl restart centrifydc-samba

retCode=$?
if [ $retCode -ne 0 ]; then
    echo "[ERR] Error restarting Centrify Samba: $retCode"
    exit $retCode
fi

echo "[INFO] Checking Samba Configuration"

matches="$(grep -c 'security = ADS' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'security = ADS' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'security = ADS' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'security = ADS' to the Global section of /etc/samba/smb.conf"
fi

FQDNADDomain="$(adinfo | grep 'Joined to domain' | awk '{print $4}'|tr [:lower:] [:upper:])"
echo "[INFO] AD Domain FQDN = $FQDNADDomain"

matches=$(grep -c "realm = $FQDNADDomain" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'realm = $FQDNADDomain' to the Global section of /etc/samba/smb.conf"
fi

ADDomain=$(echo "$FQDNADDomain" | awk -F. '{print $1}')
echo "[INFO] AD Domain = $ADDomain"

matches=$(grep -c "workgroup = $ADDomain" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'workgroup = $ADDomain' to the Global section of /etc/samba/smb.conf"
fi

NetbiosName=$(adinfo | grep 'Local host name' | awk '{print $4}')
echo "[INFO] NetbiosName = $NetbiosName"

matches=$(grep -c "netbios name = $NetbiosName" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'netbios name = $NetbiosName' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'machine password timeout = 0' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'machine password timeout = 0' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'passdb backend = tdbsam:/var/lib/samba/private/passdb.tdb' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'passdb backend = tdbsam:/var/lib/samba/private/passdb.tdb' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'kerberos method = secrets and keytab' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'kerberos method = secrets and keytab' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'server signing = auto' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'server signing = auto' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'client ntlmv2 auth = yes' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'client ntlmv2 auth = yes' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'client use spnego = yes' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'client use spnego = yes' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'template shell = /bin/bash' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'template shell = /bin/bash' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'winbind use default domain = Yes' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'winbind use default domain = Yes' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'winbind enum users = No' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'winbind enum users = No' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'winbind enum groups = No' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'winbind enum groups = No' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'winbind nested groups = Yes' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'winbind nested groups = Yes' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'idmap cache time = 0' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'idmap cache time = 0' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'idmap cache time = 0' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'idmap cache time = 0' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c '\ignore syssetgroups error = No' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'ignore syssetgroups error = No' to the Global section of /etc/samba/smb.conf"
fi

matches=$(grep -c "idmap config \* : backend  = tdb" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'idmap config * : backend = tdb' to the Global section of /etc/samba/smb.conf"
fi

matches=$(grep -c "idmap config \* : range = 1000 - 200000000" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'idmap config * : range = 1000 - 200000000' to the Global section of /etc/samba/smb.conf"
fi

matches=$(grep -c "idmap config \* : base_tdb = 0" /etc/samba/smb.conf)

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'idmap config * : base_tdb = 0' to the Global section of /etc/samba/smb.conf"
fi

matches="$(grep -c 'enable core files = false' /etc/samba/smb.conf)"

if [ $matches == 0 ]; then
    echo "[ERR] Please add 'enable core files = false' to the Global section of /etc/samba/smb.conf"
fi

echo "[INFO] Finished checking Samba config"

attshare=$(grep -c "/path/" /etc/samba/smb.conf)

if [ $attshare == 0 ]; 	then 
	echo "[INFO] Backing up Samba config to /etc/samba/smb.conf.$(date +%F)"
	cp /etc/samba/smb.conf /etc/samba/smb.conf.$(date +%F)

	echo "[INFO] Adding ATTACHMENTS DLP share to samba config"

	echo "
	[ATTACHMENTS]
		comment="attachments"
		path=/path/
		valid dom\acct
		read only=yes
	" >> /etc/samba/smb.conf

	echo "Restarting Centrify Samba"
	systemctl restart centrifydc-samba

	retCode=$?
	if [ $retCode -ne 0 ]; then
		echo "[ERR] Error restarting Centrify Samba: $retCode"
		exit $retCode
	fi
fi

if [ $attshare -gt 0 ]; then
	echo "[INFO] A share is already configured for the path /path/ - please check it is configured as follows in /etc/samba/smb.conf:"
	echo "
	[ATTACHMENTS]
		comment="attachments"
		path=/path/
		valid users=dom\acct
		read only=yes"
fi

echo "[INFO] Setting permissions on /path/ - this may take a few minutes to complete"
chmod -R o+r /path/
chmod -R o+rx /path/

echo "[INFO] Setup complete"
exit 0