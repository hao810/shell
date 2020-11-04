#!//usr/bin/env bash
#禁用root登陆
useradd cheche
sed -i '/PermitRootLogin/cPermitRootLogin no' /etc/ssh/sshd_config

#服务优化
sudo systemctl stop firewalld.service
sudo systemctl disable --now firewalld NetworkManager iptables auditd microcode postfix tuned dnsmasq
setenforce 0
sudo sed -i '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config
#sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config

#swap
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

#优化内核参数 可参考https://blog.csdn.net/fangoooooooooooo/article/details/78091959
sudo \cp /etc/sysctl.conf /etc/sysctl.conf.`date +"%Y-%m-%d_%H-%M-%S"`
sudo tee /etc/sysctl.conf <<-'EOF'
kernel.printk = 4 4 1 7 
kernel.panic = 10 
kernel.sysrq = 0 
kernel.shmmax = 4294967296 
kernel.shmall = 4194304 
kernel.core_uses_pid = 1 
kernel.msgmnb = 65536 
kernel.msgmax = 65536 
vm.swappiness = 20 
vm.dirty_ratio = 80 
vm.dirty_background_ratio = 5 
fs.file-max = 2097152 
net.core.netdev_max_backlog = 262144 
net.core.rmem_default = 31457280 
net.core.rmem_max = 67108864 
net.core.wmem_default = 31457280 
net.core.wmem_max = 67108864 
net.core.somaxconn = 65535 
net.core.optmem_max = 25165824 
net.ipv4.neigh.default.gc_thresh1 = 4096 
net.ipv4.neigh.default.gc_thresh2 = 8192 
net.ipv4.neigh.default.gc_thresh3 = 16384 
net.ipv4.neigh.default.gc_interval = 5 
net.ipv4.neigh.default.gc_stale_time = 120 
net.netfilter.nf_conntrack_max = 10000000 
net.netfilter.nf_conntrack_tcp_loose = 0 
net.netfilter.nf_conntrack_tcp_timeout_established = 1800 
net.netfilter.nf_conntrack_tcp_timeout_close = 10 
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10 
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 20 
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 20 
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 20 
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 10 
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.tcp_slow_start_after_idle = 0 
net.ipv4.ip_local_port_range = 1024 65000 
net.ipv4.ip_no_pmtu_disc = 1 
net.ipv4.route.flush = 1 
net.ipv4.route.max_size = 8048576 
net.ipv4.icmp_echo_ignore_broadcasts = 1 
net.ipv4.icmp_ignore_bogus_error_responses = 1 
net.ipv4.tcp_congestion_control = htcp 
net.ipv4.tcp_mem = 65536 131072 262144 
net.ipv4.udp_mem = 65536 131072 262144 
net.ipv4.tcp_rmem = 4096 87380 33554432 
net.ipv4.udp_rmem_min = 16384 
net.ipv4.tcp_wmem = 4096 87380 33554432 
net.ipv4.udp_wmem_min = 16384 
net.ipv4.tcp_max_tw_buckets = 1440000 
net.ipv4.tcp_tw_recycle = 0 
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_max_orphans = 400000 
net.ipv4.tcp_window_scaling = 1 
net.ipv4.tcp_rfc1337 = 1 
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_synack_retries = 1 
net.ipv4.tcp_syn_retries = 2 
net.ipv4.tcp_max_syn_backlog = 16384 
net.ipv4.tcp_timestamps = 1 
net.ipv4.tcp_sack = 1 
net.ipv4.tcp_fack = 1 
net.ipv4.tcp_ecn = 2 
net.ipv4.tcp_fin_timeout = 10 
net.ipv4.tcp_keepalive_time = 600 
net.ipv4.tcp_keepalive_intvl = 30 
net.ipv4.tcp_keepalive_probes = 10 
net.ipv4.tcp_no_metrics_save = 1 
net.ipv4.ip_forward = 1 
net.ipv4.conf.all.accept_redirects = 0 
net.ipv4.conf.all.send_redirects = 0 
net.ipv4.conf.all.accept_source_route = 0 
net.ipv4.conf.all.rp_filter = 1
fs.file-max = 2048000
fs.nr_open = 2048000
fs.aio-max-nr = 1048576
fs.mqueue.msg_default = 10240
fs.mqueue.msg_max = 10240
fs.mqueue.msgsize_default = 8192
fs.mqueue.msgsize_max = 8192
fs.mqueue.queues_max = 256
EOF
sudo sysctl -p

# 增加文件描述符限制
sudo \cp /etc/security/limits.conf /etc/security/limits.conf.`date +"%Y-%m-%d_%H-%M-%S"`
sudo tee /etc/security/limits.conf <<-'EOF'
* soft    nofile  1024000
* hard    nofile  1024000
* soft    nproc   unlimited
* hard    nproc   unlimited
* soft    core    unlimited
* hard    core    unlimited
* soft    memlock unlimited
* hard    memlock unlimited
EOF

#update repo
yum -y install epel-release

#服务器加固
mkdir ~/.ssh
chmod 700 ~/.ssh
cat <<EOF>> ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAmtqD0IdgMQbd9lBlQsrDyax8q7xPvvS+Cver6lp6cMfhi4vBQX8olf+aE7eUqjQIYE1DXQ4QNjqh42qkdY2AZt3PaTB44CG8BprSsqbcARHlRmIMqx5o8d7I9dqHPb4gPjPScH9PY1kKJ6MQiJnoUawIXIyQD5vRabaJ5Xd9Lky/oTo3pyofLiaaINZpjJWX6LheoxWojziloJ0VGlKFKppS2N8oMnxyxpwE7y1tGW1taBsk2UcPFQ94qpkieiix1XfP6BbJiV/5p60ukIUwKPVpnNxYf97LOhk4W6JmngZLLcI3Ueuvzvxi2JruKplQPUgRcmGLLZQ3JS8qkF/DTQ== root@localhost
EOF
chmod 644 ~/.ssh/authorized_keys
sed -i 's/^HISTSIZE=1000/HISTSIZE=65535/' /etc/profile
cat <<EOF>> /etc/profile
export PROMPT_COMMAND='{ msg=\$(history 1|{ read x y;echo \$y; } );logger "[euid=\$(whoami)]":\$(who am i):[\`pwd\`]"\$msg";}'
EOF
source /etc/profile
chattr +a /var/log/messages
echo >/var/log/wtmp
echo > /var/log/btmp
echo > /var/log/lastlog
echo > /var/log/secure
echo > ~/.bash_history
echo > ~/.mysql_history
echo > /var/log/messages
history -c 