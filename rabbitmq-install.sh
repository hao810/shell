#!/bin/bash
#centos 6.5 安装 rabbitmq
#关闭selinux和iptables
setenforce 0
chkconfig iptables off
service iptables stop
#安装预环境
yum -y install gcc readline-devel gcc-c++ zlib zlib-devel
#安装 Python-2.7.6
cd /root/tools
tar -xzvf Python-2.7.6.tgz &&  cd Python-2.7.6
./configure --prefix=/usr/local/python2.7
wait
make && make install
wait
mv /usr/bin/python /usr/bin/python2.6.6.old
ln -s /usr/local/python2.7/bin/python /usr/bin/python
sed -i 's/python/python2.6/g' /usr/bin/yum
#安装 Erlang
yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel perl
cd /root/tools
tar -xzvf otp_src_19.1.tar.gz && cd otp_src_19.1
./configure --prefix=/usr/local/erlang --with-ssl -enable-threads -enable-smmp-support -enable-kernel-poll --enable-hipe --without-javac
wait
make && make install 
wait
#安装 rabbitmq
yum install -y xmlto perl
cd /root/tools
tar xvf rabbitmq-server-generic-unix-3.6.5.tar
mv  rabbitmq_server-3.6.5 /opt/
cd /opt/ && mv rabbitmq_server-3.6.5 rabbitmq
# 安装 web插件管理界面
mkdir /etc/rabbitmq
cd /opt/rabbitmq/sbin
./rabbitmq-plugins enable rabbitmq_management
cd -
echo "[{rabbit, [{loopback_users, [admin]}]}]." >> /opt/rabbitmq/etc/rabbitmq/rabbitmq.config
chmod 777 /opt/rabbitmq/etc/rabbitmq/rabbitmq.config
# 设置环境变量
cat >> /etc/profile <<END
#set erlang environment
ERLANG_HOME=/usr/local/erlang
PATH=\$ERLANG_HOME/bin:\$PATH
export ERLANG_HOME
export PATH

#set rabbitmq environment
export PATH=\$PATH:/opt/rabbitmq/sbin

#set java environment
JAVA_HOME=/usr/local/java
JRE_HOME=/usr/local/java/jre
PATH=\$JAVA_HOME/bin:\$PATH:\$HOME/bin
CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JAVA_HOME
export JRE_HOME
export PATH
export CLASSPATH
END
source /etc/profile
