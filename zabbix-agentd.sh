#!/bin/bash
# Author:  xiaohuai <xiaohuai@xiaohuai.org>
# Blog:  http://www.xiaohuai.com/
# By V_v
#zabbix server 端IP 地址
SERVER="192.168.3.40"
#zabbix 版本号，也就是源码包.tar.gz前面的部分
VER="3.0.1"
useradd zabbix
yum -y install -y gcc gcc-c++ make 
#wget -c http://jaist.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$VER/zabbix-$VER.tar.gz #需要改为你自己的下载地址
tar xvf zabbix-$VER.tar.gz
cd zabbix-$VER
./configure --prefix=/usr/local/zabbix --enable-agent
make && make install
#该版本zabbix不需要make，直接make install,也可以make一下也没什么问题，其它版本请酌情修改。
echo "Installation completed !"
mkdir /var/log/zabbix
chown zabbix.zabbix /var/log/zabbix
cp misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
chmod 755 /etc/init.d/zabbix_agentd
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g" /etc/init.d/zabbix_agentd

ln -s /usr/local/zabbix/etc /etc/zabbix
ln -s /usr/local/zabbix/bin/zabbix_get /usr/bin/
ln -s /usr/local/zabbix/bin/zabbix_sender /usr/bin/
ln -s /usr/local/zabbix/sbin/zabbix_agent /usr/sbin/
ln -s /usr/local/zabbix/sbin/zabbix_agentd /usr/sbin/

echo "zabbix-agent 10050/tcp #Zabbix Agent" >> /etc/services
echo "zabbix-agent 10050/udp #Zabbix Agent" >> /etc/services
echo "zabbix-trapper 10051/tcp #Zabbix Trapper" >> /etc/services
echo "zabbix-trapper 10051/udp #Zabbix Trapper" >> /etc/services

sed -i "s/Server\=127.0.0.1/Server=$SERVER/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive\=127.0.0.1/ServerActive=$SERVER:10051/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s#tmp/zabbix_agedtd.log#var/log/zabbix/zabbix_agentd.log#g" /etc/zabbix/zabbix_agentd.conf
sed -i "s#UnsafeUserParameters=0#UnsafeUserParameters=1#g" /etc/zabbix/zabbix_agentd.conf
sed -i "s%# Include=/usr/local/etc/zabbix_agentd.userparams.conf%Include=/etc/zabbix/zabbix_agentd.conf.d/%g" /etc/zabbix/zabbix_agentd.conf

chkconfig zabbix_agentd on
service zabbix_agentd start
