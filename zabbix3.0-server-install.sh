#!/bin/bash
#安装nginx1.10.1
#下载地址 wget http://nginx.org/download/nginx-1.10.1.tar.gz
yum install  -y  net-snmp net-snmp-devel net-snmp-libs net-snmp-utils php-snmp
wait
service snmpd restart
yum -y install gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre* make gd-devel libjpeg-devel libpng-devel libxml2-devel bzip2-devel libcurl-devel
wait
useradd nginx -s /sbin/nologin -M
cd /root/tools
tar -xvf nginx-1.10.1.tar.gz -C /usr/src/
cd /usr/src/nginx-1.10.1
./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module --with-pcre
wait
make && make install
wait
#安装PHP
#下载地址 wget http://cn2.php.net/get/php-5.5.35.tar.gz/from/this/mirror
cd /root/tools
tar -xvf php-5.5.35.tar.gz -C /usr/src/
cd /usr/src/php-5.5.35
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-bz2 --with-curl --enable-ftp --enable-sockets --disable-ipv6 --with-gd --with-jpeg-dir=/usr/local --with-png-dir=/usr/local --with-freetype-dir=/usr/local --enable-gd-native-ttf --with-iconv-dir=/usr/local --enable-mbstring --enable-calendar --with-gettext --with-libxml-dir=/usr/local --with-zlib --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql=mysqlnd --enable-dom --enable-xml --enable-fpm --with-libdir=lib64 --enable-bcmath
wait
make && make install
wait
cp php.ini-production /usr/local/php/etc/php.ini
cd /usr/local/php/etc/
cp php-fpm.conf.default php-fpm.conf
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /usr/local/php/etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 16M/' /usr/local/php/etc/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/' /usr/local/php/etc/php.ini
sed -i 's&;date.timezone =&date.timezone = Asia/Shanghai&' /usr/local/php/etc/php.ini
#安装MySQL5.6.17
#下载地址 wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.17.tar.gz
yum -y remove mysql mysql-server
rm -f /etc/my.cnf
yum -y install ncurses ncurses-devel openssl-devel bison gcc gcc-c++ cmake make
wait
groupadd mysql
useradd -M -g mysql -s /sbin/nologin mysql
cd /root/tools
tar xvf mysql-5.6.17.tar.gz -C /usr/src/
cd /usr/src/mysql-5.6.17
cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql-5.6.17 \
-DSYSCONFDIR=/etc \
-DMYSQL_DATADIR=/usr/local/mysql-5.6.17/data \
-DINSTALL_MANDIR=/usr/share/man \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_READLINE=1 \
-DWITH_SSL=system \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1
wait
make && make install
wait
ln -s /usr/local/mysql-5.6.17 /usr/local/mysql
cd /usr/local/mysql
chown -R mysql:mysql .
 ./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data 
cp support-files/my-default.cnf /etc/my.cnf 
cp support-files/mysql.server /etc/rc.d/init.d/mysqld
chmod 755 /etc/rc.d/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
service mysqld start
mkdir /var/lib/mysql
ln -s /tmp/mysql.sock /var/lib/mysql/mysql.sock
echo "export PATH=\$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile
mysql << END
create database zabbix character set utf8;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
flush privileges;
END
mysqladmin -uroot password  "zabbix"
#安装zabbix-server
#下载地址 wget http://120.52.72.22/heanet.dl.sourceforge.net/c3pr90ntc0td/project/zabbix/ZABBIX%20Latest%20Stable/3.0.1/zabbix-3.0.1.tar.gz
groupadd zabbix
useradd zabbix -s /sbin/nologin -M -g zabbix
yum install mysql-devel  net-snmp-devel -y
cd /root/tools
tar zxf zabbix-3.0.1.tar.gz -C /usr/src/
cd /usr/src/zabbix-3.0.1
./configure --prefix=/usr/local/zabbix/ --enable-server --enable-agent --with-mysql --with-net-snmp --with-libcurl --with-libxml2
wait
make && make install
wait
mysql -uroot -pzabbix zabbix < database/mysql/schema.sql 
wait
mysql -uroot -pzabbix zabbix < database/mysql/images.sql 
wait
mysql -uroot -pzabbix zabbix < database/mysql/data.sql 
wait
mkdir -p /data/web/zabbix
mkdir -p /data/logs/zabbix
cp -rp frontends/php/* /data/web/zabbix/
cd /usr/local/nginx/conf
mkdir extra
cd /usr/local/nginx/conf/extra
cat  > zabbix.conf <<END
server {
listen 8027;
server_name zabbix.lifec.com;
access_log /data/logs/zabbix/zabbix.access.log;
index index.html index.php index.html;
root /data/web/zabbix;
location / {
       try_files \$uri \$uri/ /index.php?\$args;
} 
location ~ ^(.+.php)(.*)$ {
       fastcgi_split_path_info ^(.+.php)(.*)$;
       include fastcgi.conf;
       fastcgi_pass 127.0.0.1:9000;
       fastcgi_index index.php;
       fastcgi_param PATH_INFO \$fastcgi_path_info;
}
}
END
sed -i '/#gzip  on;/a\include extra/*.conf;\' /usr/local/nginx/conf/nginx.conf
sed -i 's/# DBHost=localhost/DBHost=localhost/' /usr/local/zabbix/etc/zabbix_server.conf
sed -i 's/# DBPassword=/DBPassword=zabbix/' /usr/local/zabbix/etc/zabbix_server.conf
cp /usr/src/zabbix-3.0.1/misc/init.d/tru64/zabbix_server /etc/init.d/
chmod +x /etc/init.d/zabbix_server
ln -s /usr/local/zabbix/sbin/* /usr/local/sbin/
ln -s /usr/local/zabbix/bin/* /usr/local/bin/
sed -i '1a\#chkconfig: 2345 10 90\n#description: zabbix_server' /etc/init.d/zabbix_server 
chkconfig --add zabbix_server
chkconfig zabbix_server on
service zabbix_server start
/usr/local/nginx/sbin/nginx
/usr/local/php/sbin/php-fpm
