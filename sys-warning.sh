#!/bin/bash
#监控系统负载与CPU、内存、硬盘，超出警戒值则发邮件告警。

#提取本服务器的IP地址信息
#IP=`ifconfig eth0 | grep "inet addr" | cut -f 2 -d ":" | cut -f 1 -d " "`  #centos6
IP=`ifconfig eth0 |grep -o -e 'inet [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'|grep -v "127.0.0"|awk '{print $2}'` #centos7

#提取当前时间
date=`date +"%Y-%m-%d"`

# 1、监控系统负载的变化情况，超出时发邮件告警：

#抓取cpu的总核数
cpu_num=`grep -c 'model name' /proc/cpuinfo`

#抓取当前系统15分钟的平均负载值
load_15=`uptime | awk '{print $12}'`

#计算当前系统单个核心15分钟的平均负载值，结果小于1.0时前面个位数补0。
average_load=`echo "scale=2;a=$load_15/$cpu_num;if(length(a)==scale(a)) print 0;print a" | bc`

#取上面平均负载值的个位整数
average_int=`echo $average_load | cut -f 1 -d "."`

#设置系统单个核心15分钟的平均负载的告警值为0.70(即使用超过70%的时候告警)。
load_warn=0.70

#当单个核心15分钟的平均负载值大于等于1.0（即个位整数大于0） ，直接发邮件告警；如果小于1.0则进行二次比较
if (($average_int > 0)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP服务器15分钟的系统平均负载为$average_load，超过警戒值1.0，请立即处理！！！" | mail -s "$IP 服务器系统负载严重告警！！！" $i
	done
else

#当前系统15分钟平均负载值与告警值进行比较（当大于告警值0.70时会返回1，小于时会返回0 ）
load_now=`expr $average_load \> $load_warn`

#如果系统单个核心15分钟的平均负载值大于告警值0.70（返回值为1），则发邮件给管理员
if (($load_now == 1)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP服务器15分钟的系统平均负载达到 $average_load，超过警戒值0.70，请及时处理。" | mail -s "$IP 服务器系统负载告警" $i
	done
else
echo "cpu负载正常 $load_now  $date" >> /var/log/sys-warning.log
fi

fi

# 2、监控系统cpu的情况，当使用超过80%的时候发告警邮件：

#取当前空闲cpu百份比值（只取整数部分）
#cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $5}' | cut -f 1 -d "."`  #centos6
cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $8}' | cut -f 1 -d "."`  #centos7

#设置空闲cpu的告警值为20%，如果当前cpu使用超过80%（即剩余小于20%），立即发邮件告警
if (($cpu_idle < 20)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP服务器cpu剩余$cpu_idle%，使用率已经超过80%，请及时处理。" | mail -s "$IP 服务器CPU告警" $i
	done
else
echo "cpu空闲率正常 $cpu_idle $date" >> /var/log/sys-warning.log
fi

# 3、监控系统内存的情况，当使用超过80%的时候发告警邮件：

#系统分配的内存总量
Mem_total=`free -m | grep Mem | awk '{print $2}'`

#当前剩余的内存大小
#Mem_free1=`free -m | grep Mem | awk '{print $4}'` #centos6
#Mem_cache=`free -m | grep Mem | awk '{print $7}'` #centos6
#Mem_free=`echo $Mem_free1 + $Mem_cache | bc`      #centos6
Mem_free=`free -m | grep Mem | awk '{print $7}'`  #centos7

#当前已使用的内存大小
Mem_used=`free -m | grep Mem | awk '{print $3}'`


#当前剩余内存所占总量的百分比，用小数来表示，要在小数点前面补一个整数位0
Mem_per=0`echo "scale=2;$Mem_free/$Mem_total" | bc`

#设置内存的告警值为20%(即使用超过80%的时候告警)。
Mem_warn=0.20

#当前剩余内存百分比与告警值进行比较（当大于告警值(即剩余20%以上)时会返回1，小于(即剩余不足20%)时会返回0 ）
Mem_now=`expr $Mem_per \> $Mem_warn`

#如果内存使用超过80%（即剩余小于20%，上面的返回值等于0），立即发邮件告警
if (($Mem_now == 0)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP服务器内存只剩下 $Mem_free M 未使用，剩余不足20%，使用率已经超过80%，请及时处理。" | mail -s "$IP 服务器内存告警" $i
	done
else
echo "内存使用正常 $Mem_per $Mem_used $Mem_free $date" >> /var/log/sys-warning.log
fi


# 4、监控系统硬盘根分区使用的情况，当使用超过80%的时候发告警邮件：

#取当前根分区（/dev/vda1 ）已用的百份比值（只取整数部分）
disk_vda1=`df -h | grep /dev/vda1 | awk '{print $5}' | cut -f 1 -d "%"`

#设置空闲硬盘容量的告警值为80%，如果当前硬盘使用超过80%，立即发邮件告警
if (($disk_vda1 > 80)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP 服务器 /根分区 使用率已经超过80%，请及时处理。" | mail -s "$IP 服务器硬盘告警" $i
	done
else
echo "硬盘使用正常 $disk_sda3 $date" >>  /var/log/sys-warning.log
fi

#取当前lvm分区（/dev/mapper/vg_data-lv_data ）已用的百份比值（只取整数部分）
disk_lvm=`df -h | grep /dev/mapper/vg_data-lv_data | awk '{print $5}' | cut -f 1 -d "%"`

#设置空闲硬盘容量的告警值为80%，如果当前硬盘使用超过80%，立即发邮件告警
if (($disk_lvm > 80)); then
	for i in zhanghao@fapiao.com shiyy@airchina.com churunlin2015@airchina.com marui2018@airchina.com gaoyb@fapiao.com
	do echo "$IP 服务器 /根分区 使用率已经超过80%，请及时处理。" | mail -s "$IP 服务器硬盘告警" $i
	done
else
echo "硬盘使用正常 $disk_sda3 $date" >>  /var/log/sys-warning.log
fi


