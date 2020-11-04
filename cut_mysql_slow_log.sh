#!/bin/bash

time=`date -d yesterday +"%Y-%m-%d"`
user="root"
host="10.9.245.1"
passwd="Liu"
#提前创建好一个存放目录：/opt/mysql/log/slowlog/
mv /opt/mysql/log/slow.log /opt/mysql/log/slowlog/slow-$time.log
mysqladmin -u$user -h$host -p$passwd  --socket=/opt/mysql/run/mysql.sock flush-logs slow
