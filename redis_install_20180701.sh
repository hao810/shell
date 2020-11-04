#/bin/bash
dq=`cd "$(dirname $0)";pwd`
gcc_check=`rpm -qa|grep ^gcc|awk -F "-" '{print$1}'`
zlib_check=`rpm -qa|grep -o "zlib-devel"`
curl_check=`rpm -qa|grep ^curl|awk -F "-" '{print$1}'`
curl_devel_check=`rpm -qa|grep -o "libcurl-devel"`
openssl_devel_check=`rpm -qa|grep -o "openssl-devel"`
perl_check=`rpm -qa|grep -o "perl-5"`
perl_devel_check=`rpm -qa|grep -o "perl-devel"`
cpio_check=`rpm -qa|grep ^cpio|awk -F "-" '{print$1}'`
expat_devel_check=`rpm -qa|grep -o "expat-devel"`
gettext_devel_check=`rpm -qa|grep -o "gettext-devel"`
make_check=`rpm -qa|grep ^make |awk -F "-" '{print$1}'`
libtool_check=`rpm -qa|grep ^libtool |awk -F "-" '{print$1}'`
automake_check=`rpm -qa|grep -o "automake"`
texinfo_check=`rpm -qa|grep -o "texinfo"`

if [[ ${gcc_check} == gcc ]] && [[ ${zlib_check} == "zlib-devel" ]] && [[ ${curl_check} == "curl" ]] && [[ ${curl_devel_check} == "libcurl-devel" ]] && [[ ${openssl_devel_check} == "openssl-devel" ]] && [[ ${perl_check} == "perl-5" ]] && [[ ${perl_devel_check} == "perl-devel" ]] && [[ ${cpio_check} == "cpio" ]] && [[ ${expat_devel_check} == "expat-devel" ]] && [[ ${gettext_devel_check} == "gettext-devel" ]] && [[ ${make_check} == "make" ]] && [[ ${libtool_check} == "libtool" ]] && [[ ${automake_check} == "automake" ]] && [[ ${texinfo_check} == "texinfo" ]]
then
        echo "envir is successful"
else
        echo "please install envir all yum install -y curl curl-devel zlib-devel openssl-devel perl perl-devel cpio expat-devel gettext-devel  gcc make libtool automake texinfo"
        exit 100
fi




install(){
sysctl_check=`cat /etc/sysctl.conf|grep -o "vm.overcommit_memory"`
if [[ $sysctl_check == "vm.overcommit_memory" ]]
then
        echo "sysctl is ok"
else
        echo "please optimization sysctl"
	read -p "Is optimization sysctl?(yes or no):" sysct
	if [ $sysct == yes ]
	then
		echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
		sysctl -p
		echo "sysctl is ok"
	else
		exit 100
	fi
fi


if [ -d "/app/redis" ]
then
	echo "dir /app/redis is already exist"
	exit 100
fi

mkdir /app
rm -rf $dq/redis-3.2.3
tar -xf $dq/redis-3.2.3.tar.gz -C $dq
mv $dq/redis-3.2.3 /app/redis

cd /app/redis && make

}


config(){
if [ -d "/app/server/redis/run" ]
then
        echo "dir /app/server/redis/run is already exist"
        exit 100
fi

mkdir -p /app/server/redis/run

echo "create redis.conf"
cat > /app/server/redis/redis_example.conf << EOF
daemonize yes
pidfile /app/server/redis/run/redis_example.pid
port example
timeout 0
tcp-keepalive 0
loglevel notice
logfile stdout
databases 16
save 900 1
save 300 10
save 60 10000
maxclients 30000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump_example.rdb
dir /app/server/redis/
slave-serve-stale-data yes
slave-read-only yes
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
EOF

echo "create redisstart.sh"
cat > /app/server/redis/startexample.sh << EOF-start
#!/bin/bash
/app/redis/src/redis-server /app/server/redis/redis_example.conf >> /dev/null &
/bin/sleep 5
/app/redis/src/redis-cli -p example flushall >> /dev/null &
EOF-start

echo "creater redisstop.sh"
cat > /app/server/redis/stopexample.sh << EOF-stop
#!/bin/bash
cd /app/server/redis
/app/redis/src/redis-cli -p example shutdown
echo "stop redis_example server"
EOF-stop
}

go_redis(){
stty erase '^H'
read -p "your redis port:" r_port
port_check=`ls /app/server/redis/|grep $r_port`
if [[ $r_port == $port_check ]]
then
	echo "$r_port is use"
	exit 100
fi

cp /app/server/redis/redis_example.conf /app/server/redis/redis_${r_port}.conf
cp /app/server/redis/startexample.sh /app/server/redis/start${r_port}.sh
cp /app/server/redis/stopexample.sh /app/server/redis/stop${r_port}.sh

sed -i "s/example/${r_port}/g" /app/server/redis/redis_${r_port}.conf
sed -i "s/example/${r_port}/g" /app/server/redis/start${r_port}.sh
sed -i "s/example/${r_port}/g" /app/server/redis/stop${r_port}.sh

sh /app/server/redis/start${r_port}.sh

sleep 3

netstat -lanput|grep "$r_port"
}


cronolog_install(){
rm -rf $dq/cronolog-1.6.2
tar -xf  $dq/cronolog-1.6.2.tar.gz -C $dq

cd $dq/cronolog-1.6.2 && ./configure && make && make install

}

twemproxy_install(){
rm -rf $dq/twemproxy
tar -xf  $dq/twemproxy.tar.gz -C  /app/server/

cd /app/server/twemproxy && autoreconf -fvi && ./configure --enable-debug=log && make && make install

nutcracker -V

}

twemproxy_config(){

if [ -d /app/server/twemproxy/log ]
then
	echo "dir /app/server/twemproxy/log is exist"
else
	mkdir -p /app/server/twemproxy/log
fi

stty erase '^H'
read -p "Input your redis ip1:" redis_ip1
read -p "Input your redis ip2:" redis_ip2
read -p "Input your redis ip3:" redis_ip3

cat > /app/server/twemproxy/conf/nutcracker.yml << EOF-twemproxy
clstuer1:
  listen: 0.0.0.0:6379
  hash: fnv1a_64
  distribution: ketama
  auto_eject_hosts: true
  timeout: 400
  redis: true
  server_retry_timeout: 2000
  server_failure_limit: 1
  servers:
   - ${redis_ip1}:6380:1 server1
   - ${redis_ip2}:6381:1 server2
   - ${redis_ip3}:6382:1 server3
EOF-twemproxy


cat > /app/server/twemproxy/startTwemProxy.sh << EOF-starttwe
#!/bin/sh
PROXY_HOME="/app/server/twemproxy"
cd /app/server/twemproxy
./src/nutcracker -v 6 2>&1 | /usr/local/sbin/cronolog /app/server/twemproxy/log/twemproxy_%Y_%m_%d.log >> /dev/null &
EOF-starttwe

chmod +x /app/server/twemproxy/startTwemProxy.sh
sh /app/server/twemproxy/startTwemProxy.sh

cat > /app/server/twemproxy/stopTwemProxy.sh << EOF-stoptwe
#!/bin/sh
PROXY_HOME="/app/server/twemproxy"
cd /app/server/twemproxy
kill -9 `ps -ef|grep nutcracker|grep -v grep |awk '{print $2}'`
EOF-stoptwe
chmod +x /app/server/twemproxy/stopTwemProxy.sh


}

xwindows(){
cat<<EOF
#########################################################
#       Please input the number that you need           #
#       1.redis_install                                 #
#       2.redis_config                                  #
#       3.redis_go                                	#
#       4.cronolog_install                              #
#       5.twemproxy_install                             #
#       6.twemproxy_config                              #
#       7.exit                                          #
#########################################################
EOF
stty erase '^H'
read -p "you choose:" choose


case $choose in
1)
        install
        xwindows
        ;;
2)
        config
        xwindows
	;;
3)
	go_redis
	xwindows
	;;
4)
	cronolog_install
	xwindows
	;;
5)
	twemproxy_install
	xwindows
	;;
6)
	twemproxy_config
	xwindows
	;;
7)
	exit
	;;
esac
}

xwindows
#install
#config
