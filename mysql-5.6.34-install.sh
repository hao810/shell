#!/bin/bash
#首先官方网站下载MySQL二进制发行版包
#安装依赖包
yum install -y libaio perl autoconf
wait
#创建mysql组以及mysql用户
groupadd mysql
useradd -r -g mysql -s /bin/nologin mysql
#将下载的二进制文件解压到 /usr/local 下面
cd /root/tools
mv mysql-5.6.34-linux-glibc2.5-x86_64.tar.gz /usr/local/
cd /usr/local/
tar -zxvf mysql-5.6.34-linux-glibc2.5-x86_64.tar.gz
wait
#创建mysql软连接到解压后的目录
ln -s mysql-5.6.34-linux-glibc2.5-x86_64 mysql
#修改mysql属主和属组
cd mysql
chown -R mysql.mysql .
#创建数据存储目录
mkdir -p /var/lib/mysql
chown -R mysql.mysql /var/lib/mysql
#执行数据脚本
scripts/mysql_install_db --user=mysql --datadir=/var/lib/mysql
#还原mysql安装目录下面的属主为root
chown -R root .
#将执行文件复制到init.d目录下
cp support-files/mysql.server /etc/init.d/mysqld
#复制配置文件到/etc/my.cnf
cp support-files/my-default.cnf /etc/my.cnf
#修改配置文件添加如下内容
echo "datadir = /var/lib/mysql" >>  /etc/my.cnf
echo "lower_case_table_names=1" >>  /etc/my.cnf
echo "character-set-server=utf8" >>  /etc/my.cnf
#添加环境变量
echo "export PATH=\$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile
#启动mysql
service mysqld start
#修改root密码
mysqladmin -uroot password  "123456"
