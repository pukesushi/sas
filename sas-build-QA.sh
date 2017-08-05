#Need to expand
 ga016a726 -> df -hP|grep mapper
Filesystem                                                                                                       Size  Used Avail Use% Mounted on
/dev/mapper/vgsystem-root                                                                                         12G  9.5G  1.8G  85% /
/dev/mapper/vgdata-data                                                                                           34G   29G  3.7G  89% /data
/dev/mapper/vgsystem-home                                                                                         20G  1.9G   17G  10% /home
/dev/mapper/vgtools-BESClient                                                                                   1008M   58M  900M   6% /opt/BESClient
/dev/mapper/vgtools-ca                                                                                          1008M  213M  745M  23% /opt/CA
/dev/mapper/vgsystem-tmp                                                                                         6.0G  215M  5.4G   4% /tmp
/dev/mapper/vgtools-ecotools                                                                                    1008M   34M  924M   4% /usr/ecotools
/dev/mapper/vgtools-openv                                                                                         20G  8.4G   11G  45% /usr/openv
/dev/mapper/vgsystem-var                                                                                          15G  8.7G  5.4G  62% /var
/dev/mapper/vgdata-lvoraclnt                                                                                     2.0G  1.5G  436M  78% /u001
/dev/mapper/vgdata-lvdb2                                                                                         1.5G  792M  644M  56% /opt/ibm/db2
/dev/mapper/vgdata-lvpm                                                                                          217M  159M   48M  77% /opt/pm
/dev/mapper/vgdata-lvrtm                                                                                         9.9G  858M  8.6G   9% /opt/rtm
/dev/mapper/vgtools-lvsplunk                                                                                     4.8G  3.6G  1.1G  78% /usr/splunk
/dev/mapper/vgtools-lvbeeline                                                                                    4.8G  1.1G  3.5G  24% /usr/local/hive
/dev/mapper/vgtools-lvtivoli                                                                                     4.8G   23M  4.6G   1% /opt/tivoli
/dev/mapper/vgtools-lvlansd                                                                                      2.0G   68M  1.9G   4% /lansd
/dev/mapper/vgtools-lv_itm                                                                                       9.8G  1.1G  8.3G  11% /usr/ITM

#Set Swappiness

#server list
NC006QAAF8C NC006QAAF8D NC006QAAF8E NC006QAAF8F NC006QAAF90 NC006QAAF91 NC006QAAF92 NC006QAAF93 NC006QAAF94 NC006QAAF95 NC006QAAF96 NC006QAAF97 NC006QAAF98

echo "#sshd config">>/etc/ssh/sshd_config;
echo "Match User \"root\" Host \"NC006QAAF8C*, NC006QAAF8D*, NC006QAAF8E*, NC006QAAF8F*, NC006QAAF90*, NC006QAAF91*, NC006QAAF92*, NC006QAAF93*, NC006QAAF94*, NC006QAAF95*, NC006QAAF96*, NC006QAAF97*, NC006QAAF98*\"">>/etc/ssh/sshd_config;
echo "        PermitRootLogin yes">>/etc/ssh/sshd_config;
echo "Match User \"root\" Address \"10.7.137.137, 10.7.137.136, 10.7.137.135, 10.7.137.134, 10.7.137.133, 10.7.137.132, 10.7.137.131, 10.7.137.130, 10.7.137.129, 10.7.137.128, 10.7.137.127, 10.7.137.126, 10.7.137.125\"">>/etc/ssh/sshd_config;
service sshd restart

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Start of Build Script
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#!/bin/bash

#Name: SAS-UCS-QA-config
#Author: Jeff German
#Version: 1.0


#remove old data
#####LOOK AT THIS AGAIN
sed -i 's/\/dev\/mapper\/vgdata-data/#\/dev\/mapper\/vgdata-data/g' /etc/fstab
umount /data
yes|lvremove /dev/vgdata/data
yes|vgremove /dev/mapper/vgdata
yes|pvremove /dev/sda5

#delete large data
fdisk /dev/sda <<EOF
d
5

w
EOF

#this does not work must reboot
#reboot here
#partx -d /dev/sda
-----------------------------------------------------------------
#After reboot
#create smaller data
fdisk /dev/sda <<EOF
n

+50G
t
5
8e
w
EOF

#force finding new partition
partx -a /dev/sda

#create new data VG
pvcreate /dev/sda5
vgcreate vgdata /dev/sda5
lvcreate -n data -L10G /dev/mapper/vgdata
mkfs.ext4 /dev/mapper/vgdata-data
#####END LOOK AT AGAIN

#create new partition to add to vgsystem
fdisk /dev/sda <<EOF
n

+65G
t
6
8e
w
EOF

#add new partition to vgsystem

#reboot
#force finding new partition
partx -a /dev/sda

#add new partition to vgsystem
pvcreate /dev/sda6

#Add new disk to VG
vgextend vgsystem /dev/sda6

#Extend lvs 
lvextend -r -L16G /dev/mapper/vgsystem-root
lvextend -r -L20G /dev/mapper/vgsystem-home
lvextend -r -L15G /dev/mapper/vgsystem-var


#create new partition to add to vgdata - - Fix this in prod
fdisk /dev/sda <<EOF
n

+10G
t
7
8e
w
EOF

echo "Sleeping 10"
sleep 10
#force finding new partition
partx -a /dev/sda
sleep 10

#add new partition to vgsystem
pvcreate /dev/sda7
echo "Sleeping 10"
sleep 10

#Add new disk to VG
vgextend vgdata /dev/sda7

#DB File systems etc

#Assumes vgdata exists
lvcreate -n db2lv -L10G vgdata
mkfs.ext4 /dev/vgdata/db2lv
#fstab
cp /etc/fstab /etc/fstab.`date +%F`
echo "/dev/vgdata/db2lv       /opt/ibm/db2            ext4    defaults        1 2" >>/etc/fstab
mkdir -p /opt/ibm/db2
/bin/mount /opt/ibm/db2

#Assumes vgdata exists
lvcreate -n db2homelv -L10G vgdata
mkfs.ext4 /dev/vgdata/db2homelv
#fstab
cp /etc/fstab /etc/fstab.`date +%F`
echo "/dev/vgdata/db2homelv       /db2home            ext4    defaults        1 2" >>/etc/fstab
mkdir -p /db2home
/bin/mount /db2home

#/opt/eti
mkdir /opt/eti
cd /opt/eti
wget --ignore-tags=img,th -nc -i http://bimon-dev.suntrust.com/repo/config/dime/dell/opt/eti/
chmod 755 /opt/eti/*
rm -f /opt/eti/index.*

#Assumes vgdata exists
lvcreate -n oraclntlv -L4G vgdata
mkfs.ext4 /dev/vgdata/oraclntlv
#fstab
cp /etc/fstab /etc/fstab.`date +%F`
echo "/dev/vgdata/oraclntlv       /u001            ext4    defaults        1 2" >>/etc/fstab
#sed -i 's/vgdata\/lvoraclnt/datavg\/oraclntlv/g' /etc/fstab
mkdir -p /u001
/bin/mount /u001
groupadd dba
useradd -c "Oracle Account" -g dba -u 9900079 -d /home/oracle -s /bin/ksh oracle
chown oracle:dba /u001

#Still waiting on answer
#Network

for i in $(ip a|grep mtu|egrep -v 'lo|bond0' |cut -d: -f 2|cut -d@ -f 1)
     do
        cp /etc/sysconfig/network-scripts/ifcfg-$i /root/ifcfg-$i$(date +%F-%H%M%S)
    done

cp /etc/resolv.conf /root/resolv.conf$(date +%F-%H%M%S)
cp /etc/sysconfig/network /root/network$(date +%F-%H%M%S)

for i in $(ip a|grep mtu|egrep -v 'lo|bond0' |cut -d: -f 2|cut -d@ -f 1)
	do
        sed -i 's/\"//g' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i 's/NM_CONTROLLED=yes/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=none/g' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i '/DNS1="10.6.220.20"/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i '/DNS2="10.4.220.20"/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i '/GATEWAY="10.7.136.1"/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i '/HOSTNAME=/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
        sed -i 's/NM_CONTROLLED="yes"/NM_CONTROLLED=no/g' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i '/NM_CONTROLLED=no/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i '/TYPE=Vlan/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i '/TYPE=vlan/d' /etc/sysconfig/network-scripts/ifcfg-"$i"
		sed -i 's/VLAN="yes"/VLAN=yes/g' /etc/sysconfig/network-scripts/ifcfg-"$i"
		echo "USERCTL=no" >> /etc/sysconfig/network-scripts/ifcfg-"$i"
		

    done
#Create LLT VLAN File
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/ifcfg-eth2.115 -o /etc/sysconfig/network-scripts/ifcfg-eth2.115
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/ifcfg-eth3.22 -o /etc/sysconfig/network-scripts/ifcfg-eth3.22

#Disable eth1
sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth1

#QA Only
#Add NETWORK to VLAN file with IPs
if [ -e /etc/sysconfig/network-scripts/ifcfg-eth4.115 ]
then
	echo "NETWORK=`route|grep 172|awk '{ print $1 }'`" >> /etc/sysconfig/network-scripts/ifcfg-eth4.115
	sed -i '/TYPE=Ethernet/d' /etc/sysconfig/network-scripts/ifcfg-eth4.115
fi

if [ -e /etc/sysconfig/network-scripts/ifcfg-eth0.980 ]
then
	echo "NETWORK=`route|grep 10.|awk '{ print $1 }' |grep -v default |grep -v 172`" >> /etc/sysconfig/network-scripts/ifcfg-eth0.980
	sed -i '/TYPE=Ethernet/d' /etc/sysconfig/network-scripts/ifcfg-eth0.980
fi

if [ -e /etc/sysconfig/network-scripts/ifcfg-eth4.160 ]
then
	echo "NETWORK=`route|grep 172|awk '{ print $1 }'`" >> /etc/sysconfig/network-scripts/ifcfg-eth4.160
	sed -i '/TYPE=Ethernet/d' /etc/sysconfig/network-scripts/ifcfg-eth4.160
if

#Must leave VLAN Interfaces
#cat /etc/sysconfig/network-scripts/ifcfg-eth0.980 |egrep 'IP|NET' >>/etc/sysconfig/network-scripts/ifcfg-eth0
#mv /etc/sysconfig/network-scripts/ifcfg-eth0.980 /root

#cat /etc/sysconfig/network-scripts/ifcfg-eth4.115 |egrep 'IP|NET' >>/etc/sysconfig/network-scripts/ifcfg-eth4
#mv /etc/sysconfig/network-scripts/ifcfg-eth4.115 /root
#

	curl http://bimon-dev.suntrust.com/repo/config/resolv.conf-nonprod -o /etc/resolv.conf
	echo "GATEWAY=10.7.136.1"  >> /etc/sysconfig/network

####Divide Script here.
######

#/data/build must exist
mkdir -p /data/build
curl http://bimon-dev.suntrust.com/repo/config/SAS/software/data-build.tgz -o /data/data-build.tgz
cd /data
tar zxvf ./data-build.tgz
rm -rf /data/data-build.tgz

#splunk
lvcreate -n splunklv -L5G vgdata
mkfs.ext4 /dev/vgdata/splunklv
#fstab
cp /etc/fstab /etc/fstab.`date +%F`
echo "/dev/vgdata/splunklv       /usr/splunk            ext4    defaults        1 2" >>/etc/fstab
mkdir -p /usr/splunk
/bin/mount /usr/splunk

groupadd splunk
useradd -c "Splunk Account" -g splunk uzspkda0

mkdir /tmp/splunk
mount -o vers=3 ga016d061:/swdepot /tmp/splunk/

cd /usr/splunk
tar -zxvf /tmp/splunk/splunk/splunkforwarder-6.6.1-aeae3fe0c5af-Linux-x86_64.tgz
chown -R uzspkda0 /usr/splunk
chgrp -R splunk /usr/splunk
/usr/splunk/splunkforwarder/bin/splunk start --accept-license
/usr/splunk/splunkforwarder/bin/splunk stop
cd /usr/splunk/splunkforwarder/etc/apps
tar -xvf /tmp/splunk/splunk/apps/sti_prod_ds_phone_home.tar 
chown -R uzspkda0 sti_prod_ds_phone_home
/usr/splunk/splunkforwarder/bin/splunk enable boot-start -user uzspkda0
chown -R uzspkda0 /usr/splunk
chgrp -R splunk /usr/splunk
/etc/init.d/splunk start


#CA7
chkconfig --del S99_CA7_R11_3
rm -f /etc/init.d/S99_CA7_R11_3
/data/build/ca7/CA_7_agent.11.3/RedHat/setup.bin
cp /usr/CA/WA_Agent_R11_3/cybagent-GA016A5CA.init /etc/init.d/cybagent
chkconfig --add /etc/init.d/cybagent
chkconfig cybagent off
chmod 755 /etc/init.d/cybagent
sed -i 's/AGENTNAME=GA016A5CA/AGENTNAME=$(hostname -s)/g' /usr/CA/WA_Agent_R11_3/agentparm.txt

#/usr/CA/WA_Agent_R11_3/ca71spool

sed -i 's/spooldir=\/usr\/CA\/WA_Agent_R11_3\/spool/spooldir=\/usr\/CA\/WA_Agent_R11_3\/ca71spool/g' /usr/CA/WA_Agent_R11_3/agentparm.txt


sed -i "s/GA016A5CA/$(hostname -s)/g" /etc/init.d/cybagent


#Zabbix
mkdir -p /data/zabbix/zabbix-agent
curl http://bimon-dev.suntrust.com/repo/zabbix/agent/linux/installzabbix.sh -o /data/zabbix/zabbix-agent/installzabbix.sh
curl http://bimon-dev.suntrust.com/repo/zabbix/agent/linux/zabbix-2.4.0-1.el6.x86_64.rpm -o /data/zabbix/zabbix-agent/zabbix-2.4.0-1.el6.x86_64.rpm
curl http://bimon-dev.suntrust.com/repo/zabbix/agent/linux/zabbix-agent-2.4.0-1.el6.x86_64.rpm -o /data/zabbix/zabbix-agent/zabbix-agent-2.4.0-1.el6.x86_64.rpm
echo "Sleeping 10"
sleep 10
chmod 755 /data/zabbix/zabbix-agent/installzabbix.sh
/data/zabbix/zabbix-agent/installzabbix.sh

#Java
curl http://bimon-dev.suntrust.com/repo/config/SAS/software/jdk-6u24-linux-x64-rpm.bin -o /data/build/jdk-6u24-linux-x64-rpm.bin
chmod 755 /data/build/jdk-6u24-linux-x64-rpm.bin
/data/build/jdk-6u24-linux-x64-rpm.bin -noregister

#FTP client and server
yum -y install ftp 
yum -y install vsftpd

#httpd
yum -y install httpd

#PCP
yum -y install pcp 

#numaTop
yum -y install numatop

#Tuned
yum -y install tuned

#config
#Misc
chkconfig autofs off
chkconfig cups off
chkconfig haldaemon off



#sudoers
    cp /etc/sudoers /etc/sudoers$(date +%F-%H%M%S)
    curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/sudoers -o /etc/sudoers

chkconfig cups off

#Locate
	cp -p /etc/updatedb.conf /etc/updatedb.conf-$(date +%F-%H%M%S)
	curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/updatedb.conf -o /etc/updatedb.conf
	
#limits.conf
	cp -p /etc/security/limits.conf /etc/security/limits.conf-$(date +%F-%H%M%S)
	curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/limits.conf -o /etc/security/limits.conf
	
#kernel Params
	cp -p /etc/sysctl.conf /etc/sysctl.conf-$(date +%F-%H%M%S)
	curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/sysctl.conf -o /etc/sysctl.conf
	
#Sysstat config
	cp  -p /etc/sysconfig/sysstat  /etc/sysconfig/sysstat-$(date +%F-%H%M%S)
	curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/sysstat -o /etc/sysconfig/sysstat
#selinux
    cp /etc/sysconfig/selinux /etc/sysconfig/selinux-$(date +%F-%H%M%S)
    curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/selinux -o /etc/sysconfig/selinux
	
#Tuning
		
#Tuned
		chkconfig tuned on
		#chkconfig ktune on
		service tuned start
		#service ktune start 
		tuned-adm profile enterprise-storage

yum -y install cpupowerutils
yum -y install 

#Mount options
#Add noatime to all vxfs mounts
		
#Add noatime to all ext4 mounts
		cp -p /etc/fstab /etc/fstab-$(date +%F-%H%M%S)
		sed -i 's/defaults/defaults,noatime/g' /etc/fstab

#fix fstab
sed -i 's/#\/dev\/mapper\/vgdata-data/\/dev\/mapper\/vgdata-data/g' /etc/fstab

#Access.conf
curl http://bimon-dev.suntrust.com/repo/config/SAS/qa/access.conf -o /etc/security/access.conf

#Fix Swap
swapoff -v /dev/vgsystem/swap 
lvresize /dev/vgsystem/swap -L 32g
mkswap /dev/vgsystem/swap
swapon /dev/vgsystem/swap

#Do this before adding CIFS etc to fstab
#fix data
cp -p /etc/fstab /etc/fstab-$(date +%F-%H%M%S)
mkdir /data_ie
umount /data
sed -i 's/\/data/\/data_ie/g' /etc/fstab
mount /data_ie

#setup/usr/local/bin
cd /usr/local/bin
wget --ignore-tags=img,th -nc -i http://bimon-dev.suntrust.com/repo/config/SAS/common/usr/local/bin/
chmod 755 /usr/local/bin/*
rm -f /usr/local/bin/index.*

#/etc/profile.d/profile.sas.sh
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/profile.sas.sh -o /etc/profile.d/profile.sas.sh

#root crontab
#Copy root crontab from each like server
#nc006qaaf94 = done

#Set quotas on home only on nc006qaaf94

#Copy user crontab from each like server
rsync -avzh -e ssh /var/spool/cron root@nc006qaaf94:/var/spool

#/root/KT_refresh.sh
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/KT_refresh.sh -o /root/KT_refresh.sh

#sync home directories
rsync --dry-run -avzh -e ssh /home root@nc006vdevae19:/

#Add CIFS NFS to /etc/fstab
cp -p /etc/fstab /etc/fstab-$(date +%F-%H%M%S)
#---cifs\nfs-------

cat <<EOF >>/etc/fstab

##########
#cifs
##########
//GA016A502/DORSSHARE           /dorsshare      cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//GA016D267/Projects /Projects cifs gid=auditsvc,forcegid,dir_mode=0770/*,file_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//GA016D267/Restricted\040Access /Restricted_Access cifs gid=auditsvc,forcegid,dir_mode=0770/*,file_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f3a/ds_shared            /ds_shared      cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Ga016f004/RATeam_New          /RATeam_New     cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f006/NMON_DATA/NMON_data /NMON_DATA      cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs                      /corp           cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/corporate_shared     /corporate_shared       cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f00a/controllers_shared  /controllers_shared     cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016vw085/wwwroot_GLQuery    /wwwroot_GLQuery_085    cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016vw088/wwwroot_GLQuery    /wwwroot_GLQuery_088    cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Ga016f004/eis_01/ga016/EFM/RATeam             /eis_01 cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_02/VA018/F20/Data/Shared   /Mortgage_02    cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_03/VA018/F20_b             /Mortgage_03    cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_02/Va018/F20/Data/      /Mortgage_Va018 cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Commercial_03/va017/f18/Cwcomm/Shared/Cisadhoc   /Cisadhoc       cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/Dfs/Corporate_Shared/ga016/F07/Corp_AQALR_A/RMIT         /RMIT           cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/Dfs/Corporate_Shared/ga016/F07/Corp_AQALR_B/RMIT_B       /RMIT_B         cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f004/Marketing_01/GA090/MARKET /MARKET   cifs    dir_mode=0777,file_mode=0777,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_04/VA018/F18/Shared/EnterpriseReporting /EnterpriseReporting cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/Dfs/Corporate_Shared/ga016/F07/Corp_AQALR_C/RISK\040ANALYTICS /RISK_ANALYTICS cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/Dfs/Corporate_Shared/Ga016/F07/Corp_AQALR_D/Cb_retail\040credit\040risk\040mgmt/Consumer\040Banking\040Risk      /Consumer_Banking_Risk  cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/mortgage_06/va019/f01/Everyone/Credit\040Analytics\040Reporting\040and\040Modeling/Loss_Model           /Loss_Model             cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp.suntrust.com/Dfs/Corporate_Shared/Ga030/F41/Shared/Commercial\040PMO                     /Commercial_PMO         cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/EIS_Shared/GA040/F24/SHARED/LOSSPRVNT/Fraud\040Countermeasures/Infosys\040Reporting  /Infosys_Reporting      cifs    gid=frdanal,forcegid,dir_mode=0770/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f004/marketing_01/GA090/MARKET/PRODUCT\040MANAGEMENT/Pricing/Deposit\040Pricing          /DepositPricing         cifs    dir_mode=0777,file_mode=0777,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/corporate_shared/ga030/F44/Shared /F44_Shared cifs    dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_06/va019/F02/Share/Share/Everyone /Share_Everyone cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/Corporate_Shared/GA030/F44 /GA030_F44 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f004/Corporate_01/VA018/F19/Compliance/Fairlending/RECORDS/LEG1000/SASDATA /LEG1000_SASDATA cifs gid=fairbank,forcegid,dir_mode=0770/*,file_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Ga016f009/wim/Shared/PAM/PAM_Research/Active-Records/ /Active-Records cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/Corporate_Shared/GA016/F07/Corp_AQALR_A/CORP\040RISK\040MGMT\040GENERAL\040INFO/CORP\040RETAIL\040CRED\040RISK\040MGMT /CORP_RETAIL_CRED_RISK_MGMT cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/Corporate_Shared/GA080/F01/Corporate_Shared/Shared/RECORDS/Leasing\040Group/Staffing /Staffing cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_05/va018/f17 /F17 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_04/va018/f18 /F18 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_02/va018/f19 /F19 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_02/VA018/F20/DATA/SHARED /F20 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_03/Va018/F20_b/Sas /F20_B cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/Mortgage_01/va019/F01 /F01 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/mortgage_06/va019/F01 /F01B cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Mortgage_06/va019/f02 /F02 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/retail_SHARED/Ga016/F3a_02/consumer\040lending\040operations /consumer_lending_operations cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//VA018a29/Dealer/RECORDS/Risk_Database /Risk_Database cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/Commercial_03/VA017/F18/Cwcomm/Shared/Cisadhoc /Commercial_03_c cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Ga016f006/NMON_DATA_TMP /NMON_DATA_TMP cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016a5e7/AssetCenterPCData  /AssetCenterPCData cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016k0d0/Corporate_01/GA030/F40 /F40_Shared cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/Corporate_Shared/Ga016/F07/Corp_AQALR_D/ /Corp_AQALR_D cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/DFS/Marketing_shared/GA016/F121/Marketing_shared /DF121_MktShr cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//GA016D267/G_DRIVE /auditsvc02 cifs uid=uzassa0,gid=auditsvc,forcegid,dir_mode=0770/*,file_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/mortgage_01/va019/F01/CreditRisk/Private /F01/CreditRisk/Private cifs gid=crm,forcegid,dir_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k002/mortgage_01/va019/F01/CreditRisk/Partner /F01/CreditRisk/Partner cifs gid=crm,forcegid,dir_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016vsql052/dime  /ga016vsql052_dime cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/EIS_Shared/STOLI/GA/CKV/SHARED/F01/STOLI_All /STOLI_All cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016a5e7/AssetCenterPCData/ /a016a5e7_AssetCenterPCData cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Ga016f3a/Eis_shared/ /Ga016f3a_Eis_shared cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016d2f6/26/ /ga016d2f6_26 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016d2f6/23/ /ga016d2f6_23 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016nh05/TAD_PROD_MEDIA/SAS_SCOPES /ga016a4ec_SAS_SCOPES cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//va018k00b/mortgage_06/va019/F02/Share/Share/MORTGAGE\040MARKETING /MORTGAGE_MARKETING cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016nh05/TAD_PROD_MEDIA/SAS_Scopes /SAS_Scopes cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016va679/ampm_tm1 /ampm_tm1 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/dfs/EIS_Shared/STOLI/GA/NSH/SHARED/F31/MIS_Analytics /F31_MIS_Analytics cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016at6/erdm/Prod /erdm_prod cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/Corporate_Shared/Ga016/F07/Corp_AQALR_D/Operational\040Risk\040and\040Compliance\040MIS/Records/ADM1000/SAS_Data /ADM1000_SAS_DATA cifs gid=critrmit,dir_mode=0770/*,file_mode=0770/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//GA016A744/SAS_Depot /mnt cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/DFS/Corporate_Shared/GA016/F07/Corp_AQALR_D/MIS\040REPORTING/FR\040Y-14QM /CCAR_FRY14QM_01 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/DFS/Corporate_Shared/GA016/F07/Corp_AQALR_D/MIS\040REPORTING/RMIT\040-\040External\040Reporting/FED\040Data\040Collection /CCAR_FRY14QM_02 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/DFS/Corporate_Shared/GA016/F07/Corp_AQALR_C/RISK\040ANALYTICS/#FRY\04014\040Q\040Submissions /CCAR_FRY14QM_03 cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f007/Data_Batch_Prod /HEX_Data_Batch_PROD cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//corp/dfs/retail_SHARED/Ga016/F3a_02/RETAIL_SHARED/AQCP/WBCS\040Admin/WBCS\040Analytics/REPORTING   /REPORTING       cifs    dir_mode=0777,file_mode=0777,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//Corp/DFS/Corporate_Shared/GA040/F24/REPOS/CORPCOMM/14_CorpComm\040Services/Communication\040Tool   /Communication_Tool       cifs    dir_mode=0777,file_mode=0777,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016nh05/Enterprise_Shares/WBIO_Shared   /WBIO_Shared    cifs  gid=cis,forcegid,dir_mode=0770,file_mode=0770,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016vsqlffc/dime  /ga016vsqlffc_dime cifs dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850 0 0
//ga016f004/Enterprise_Intelligence/F-DRIVE/Inetpub/seds.suntrust.com/ADHOC             /ADHOC         cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850     00
//ga016f004/Enterprise_Intelligence/E-DRIVE             /E-DRIVE               cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850         0               0
//ga016f004/Enterprise_Intelligence/F-DRIVE/Inetpub/seds.suntrust.com/ADHOC/EDW         /EDW           cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850     00
//ga016f004/Enterprise_Intelligence/F-DRIVE             /F-DRIVE               cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850         0               0
//ga016f004/Enterprise_Intelligence/F-DRIVE/Inetpub             /INETPUB               cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850         0           0
//ga016f004/Enterprise_Intelligence/Q-DRIVE             /Q-DRIVE               cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850         0               0
//ga016f004/Enterprise_Intelligence/F-DRIVE/Inetpub/seds.suntrust.com/SEDS              /SEDS          cifs            dir_mode=0777/*,file_mode=0777/*,credentials=/etc/samba/creds/corp-creds.txt,iocharset=iso8859-8,codepage=cp850     00

#######
#NFS
#######

#NFS mounts
NC006f004:/SAS_QA       /sas_users      nfs     nfsvers=3       0 0
NC006VQAAF6C:/trillium          /trillium       nfs     nfsvers=3       0 0
#nc006qaa226:/trillium          /trillium       nfs     nfsvers=3       0 0
NC006VQAAF6C:/workspace         /workspace      nfs     nfsvers=3       0 0
nc006f007:/SAS_QA       /sas_qa         nfs     nfsvers=3               0 0
nc006f007:/SAS_CIS_QA   /sas_cis_nas            nfs     nfsvers=3               0 0
nc006f007:/SAS_WHLSL_QA       /sas_whlsl_nas    nfs     nfsvers=3               0 0
NC006P5XSA54:/flashstart /flashcopy     nfs     nfsvers=3       0 0
10.4.86.253:/export/sas_data  /data     nfs     rw,bg,hard,nointr,tcp,vers=3,actimeo=0 0 0

EOF

#make cifs\nfs directories
/dorsshare
/Projects
/Restricted_Access
/ds_shared
/RATeam_New
/NMON_DATA
/corp
/corporate_shared
/controllers_shared
/wwwroot_GLQuery_085
/wwwroot_GLQuery_088
/eis_01
/Mortgage_02
/Mortgage_03
/Mortgage_Va018
/Cisadhoc
/RMIT
/RMIT_B
/MARKET
/EnterpriseReporting
/RISK_ANALYTICS
/Consumer_Banking_Risk
/Loss_Model
/Commercial_PMO
/Infosys_Reporting
/DepositPricing
/F44_Shared
/Share_Everyone
/GA030_F44
/LEG1000_SASDATA
/Active-Records
/CORP_RETAIL_CRED_RISK_MGMT
/Staffing
/F17
/F18
/F19
/F20
/F20_B
/F01
/F01B
/F02
/consumer_lending_operations
/Risk_Database
/Commercial_03_c
/NMON_DATA_TMP
/AssetCenterPCData
/F40_Shared
/Corp_AQALR_D
/DF121_MktShr
/auditsvc02
/F01/CreditRisk/Private
/F01/CreditRisk/Partner
/ga016vsql052_dime
/STOLI_All
/a016a5e7_AssetCenterPCData
/Ga016f3a_Eis_shared
/ga016d2f6_26
/ga016d2f6_23
/ga016a4ec_SAS_SCOPES
/MORTGAGE_MARKETING
/SAS_Scopes
/ampm_tm1
/F31_MIS_Analytics
/erdm_prod
/ADM1000_SAS_DATA
/mnt
/CCAR_FRY14QM_01
/CCAR_FRY14QM_02
/HEX_Data_Batch_PROD
/REPORTING
/Communication_Tool
/WBIO_Shared
/ga016vsqlffc_dime
/ADHOC
/E-DRIVE
/EDW
/F-DRIVE
/INETPUB
/Q-DRIVE
/SEDS

#make nfs directories

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
END of Build Script
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#--------------------------------------------------------------------------------------
#Notes for cluster add
#--------------------------------------------------------------------------------------
#Add node to CFS
cfsmntadm modify /egb32 add NC006QAAF94=cluster
for i in `cat cfsfix.sh`; do cfsmntadm modify $i add NC006QAAF94=cluster; done
cfsmount /egb32  nc006qaaf8c
for i in `cat cfsfix.sh`; do cfsmount $i  NC006QAAF94; done


#Nic Issue
#Change NIC to local and not global

#Softlinks
ln -s /ega01/atm01 /atm01
ln -s /ega01/auditsvc01 /auditsvc01
ln -s /CIG6/backup /backup
ln -s /ega01/bice01 /bice01
ln -s /D9/bio01 /bio01
ln -s /D10/bio02 /bio02
ln -s /D10/bio03 /bio03
ln -s /D11/bio04 /bio04
ln -s /D11/bio05 /bio05
ln -s /D12/bio06 /bio06
ln -s /D12/bio07 /bio07
ln -s /D13/bio08 /bio08
ln -s /D13/bio09 /bio09
ln -s /D14/bio10 /bio10
ln -s /data_ie/build_root/movefiles /build
ln -s /dev/vx/.dmp/c /c
ln -s /egb27/cbanly /cbanly
ln -s /egb32/cbanly01 /cbanly01
ln -s /egb01/cbasset01 /cbasset01
ln -s /egb05/cbidanaly01 /cbidanaly01
ln -s /C1/ccarchive /ccarchive
ln -s /C01/ccat01 /ccat01
ln -s /C01/ccat02 /ccat02
ln -s /C02/ccat03 /ccat03
ln -s /C02/ccat04 /ccat04
ln -s /C1/ccdata /ccdata
ln -s /C2/ccdatamth /ccdatamth
ln -s /C2/ccdataqtr /ccdataqtr
ln -s /C3/ccforecast /ccforecast
ln -s /C3/ccmodels /ccmodels
ln -s /C4/ccreporting /ccreporting
ln -s /egb11/ccrrisk01 /ccrrisk01
ln -s /C4/ccsource /ccsource
ln -s /C5/ccuser21d /ccuser21d
ln -s /C5/ccuser7d /ccuser7d
ln -s /egb30/cdp /cdp
ln -s /ega01/cis01 /cis01
ln -s /egb13/corptreas01 /corptreas01
ln -s /egb14/corptreas02 /corptreas02
ln -s /egb15/corptreas03 /corptreas03
ln -s /egb16/corptreas04 /corptreas04
ln -s /egb17/corptreas05 /corptreas05
ln -s /egb18/corptreas06 /corptreas06
ln -s /egb20/corptreas07 /corptreas07
ln -s /egb21/corptreas08 /corptreas08
ln -s /egb19/corptreas09 /corptreas09
ln -s /ebg23/corptreas10 /corptreas10
ln -s /ebg24/corptreas11 /corptreas11
ln -s /egb26/corptreas12 /corptreas12
ln -s /egb27/corptreas13 /corptreas13
ln -s /egb28/corptreas14 /corptreas14
ln -s /egb29/corptreas15 /corptreas15
ln -s /egb01/cpmo01 /cpmo01
ln -s /dors09 /cqdata18
ln -s /dors10 /cqdata19
ln -s /dors11 /cqdata20
ln -s /dors12 /cqdata21
ln -s /dors13 /cqdata22
ln -s /egb01/critrmit01 /critrmit01
ln -s /egb12/crm01 /crm01
ln -s /egb25/crm02 /crm02
ln -s /DEC1/decanl01 /decanl01
ln -s /DEC1/decanl02 /decanl02
ln -s /CIG6/dext /dext
ln -s /D1/dors01 /dors01
ln -s /D1/dors02 /dors02
ln -s /D2/dors03 /dors03
ln -s /D2/dors04 /dors04
ln -s /D3/dors05 /dors05
ln -s /D3/dors06 /dors06
ln -s /D4/dors07 /dors07
ln -s /D4/dors08 /dors08
ln -s /D5/dors09 /dors09
ln -s /D5/dors10 /dors10
ln -s /D6/dors11 /dors11
ln -s /D6/dors12 /dors12
ln -s /D7/dors13 /dors13
ln -s /D7/dors14 /dors14
ln -s /D8/dors15 /dors15
ln -s /D8/dors16 /dors16
ln -s /D9/dors17 /dors17
ln -s /egb01/dpricing01 /dpricing01
ln -s /egb22/dpricing02 /dpricing02
ln -s /CIG6/dw1 /dw1
ln -s /egb33/ecrrisk01 /ecrrisk01
ln -s /egb34/ecrrisk02 /ecrrisk02
ln -s /saswork /egwork
ln -s /egb09/eminer_projects/ /eminer_projects
ln -s /CIG6/extracts /extracts
ln -s /egb01/fairbank01 /fairbank01
ln -s /ega01/finance01 /finance01
ln -s /FRD1/fraud01 /fraud01
ln -s /FRD1/fraud02 /fraud02
ln -s /FRD2/fraud03 /fraud03
ln -s /FRD2/fraud04 /fraud04
ln -s /egb31/fraud05 /fraud05
ln -s /F1/fs001 /fs001
ln -s /F1/fs002 /fs002
ln -s /F2/fs003 /fs003
ln -s /F2/fs004 /fs004
ln -s /F3/fs005 /fs005
ln -s /F3/fs006 /fs006
ln -s /F4/fs007 /fs007
ln -s /F4/fs008 /fs008
ln -s /F5/fs009 /fs009
ln -s /F5/fs010 /fs010
ln -s /F6/fs011 /fs011
ln -s /F6/fs012 /fs012
ln -s /F7/fs013 /fs013
ln -s /F7/fs014 /fs014
ln -s /CIG6/gsdata /gsdata
ln -s /CIG6/gshist /gshist
ln -s /egb22/hmrsec/ /hmrsec
ln -s /egb22/hmrsups/ /hmrsups
ln -s /CIG6/index /index
ln -s /CIG6/intranet /intranet
ln -s /D15/mbio11 /mbio11
ln -s /A1/mcdima01 /mcdima01
ln -s /A1/mcdima02 /mcdima02
ln -s /A2/mcdima03 /mcdima03
ln -s /A2/mcdima04 /mcdima04
ln -s /A3/mcdima05 /mcdima05
ln -s /A3/mcdima06 /mcdima06
ln -s /A4/mcdima07 /mcdima07
ln -s /A4/mcdima08 /mcdima08
ln -s /A5/mcdima09 /mcdima09
ln -s /A5/mcdima10 /mcdima10
ln -s /A6/mcdima11 /mcdima11
ln -s /A6/mcdima12 /mcdima12
ln -s /CIG6/modeling /modeling
ln -s /egb01/mtg01 /mtg01
ln -s /egb06/mvgroup01 /mvgroup01
ln -s /egb02/opsanaly01 /opsanaly01
ln -s /egb02/opsanaly02 /opsanaly02
ln -s /egb03/opsanaly03 /opsanaly03
ln -s /egb01/perfmgt01 /perfmgt01
ln -s /egb10/prism01 /prism01
ln -s /egb04/prism02 /prism02
ln -s /CIG1/prodtemp /prodtemp
ln -s /egb03/radix01 /radix01
ln -s /egb01/risk01 /risk01
ln -s /CIG6/rrm /rrm
ln -s /R1/rskanl01 /rskanl01
ln -s /R1/rskanl02 /rskanl02
ln -s /R2/rskanl03 /rskanl03
ln -s /R2/rskanl04 /rskanl04
ln -s /R3/rskanl05 /rskanl05
ln -s /R3/rskanl06 /rskanl06
ln -s /R4/rskanl07 /rskanl07
ln -s /R4/rskanl08 /rskanl08
ln -s /R5/rskanl09 /rskanl09
ln -s /R5/rskanl10 /rskanl10
ln -s /R6/rskanl11 /rskanl11
ln -s /R6/rskanl12 /rskanl12
ln -s /egb07/rskgroup01 /rskgroup01
ln -s /sasdata /SAS01
ln -s /egb06/sasadm01 /sasadm01
ln -s /CIG2/sasdata /sasdata
ln -s /egb35/sas_stats /sas_stats
ln -s /egb04/seds01 /seds01
ln -s /egb04/seds02 /seds02
ln -s /CIG2/source /source
ln -s /SPDS_QA_data /SPDS_data
ln -s /SPDS_data/index /SPDS_index
ln -s /SPDS_data/meta /SPDS_meta
ln -s /sasworkprd/spds_work /SPDS_work
ln -s /egb05/stewqc01 /stewqc01
ln -s /egb01/stoli01 /stoli01
ln -s /CIG6/trandata /trandata
ln -s /egb01/treas01 /treas01
ln -s /CIG3/userdata /userdata
ln -s /CIG5/userperm /userperm
ln -s /CIG6/vintage /vintage
ln -s /CIG6/wext /wext
ln -s /egb07/whlsl01 /whlsl01
ln -s /wmig/wholesale /wholesale
ln -s /CIG1/prodtemp /worksort

#Sas scripts
mkdir /opt/sas-scripts
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/sas-scripts/CreateHomeDir.sh -o /opt/sas-scripts/CreateHomeDir.sh
curl http://bimon-dev.suntrust.com/repo/config/SAS/common/sas-scripts/DeleteHomeDir.sh -o /opt/sas-scripts/DeleteHomeDir.sh



#Need to research for UCS
#DMP IO Policy
#		vxdmpadm setattr enclosure san_vc0 iopolicy=round-robin
		
#HBA Queue Depth
#		touch  /etc/modprobe.d/qla2xxx.conf
#		echo "options qla2xxx ql2xmaxqdepth=128"  >>/etc/modprobe.d/qla2xxx.conf
#		cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.$(date +%m-%d-%H%M%S).bak 
#		dracut -f -v --add multipath 
#		
#		echo "Initramfs updated, you must reboot"

#Fibre information
cat /sys/class/fc_host/host1/port_name

#Patching Veritas
#Get http://bimon-dev.suntrust.com/repo/vertias/vrts/vrts6.2/SASPatches/

/data/SASPatches/MR/rhel6_x86_64/installmr -require /data/SASPatches/cpi-Patch-6.2.1.1100/patches/CPI_6.2.1_P11.pl -patch_path /data/SASPatches/sfha-rhel6_x86_64-Patch-6.2.1.300

"rpm -Uvh /data/build/VRTSvxfen-6.2.1.200-RHEL6.x86_64.rpm"

rpm -Uvh /data/build/VRTSvxfs-6.2.1.302-RHEL6.x86_64.rpm

disk=$(vxdisk -o alldgs list|grep NBdg|awk '{print$1}');
echo $disk;
vxdisk list $disk |egrep "hostid|udid|NBdg"

for i in $(vxdisk -o alldgs list|grep -v shared|grep -v fence|grep -v -)
do
	vxdisk list $i |egrep "hostid|udid|NBdg"
done
