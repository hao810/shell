#!/bin/bash
 
DIR=/etc
#################################################################
##/etc/login.defs
##PASS_MAX_DAYS
echo "正在修改/etc/login.defs..."
sleep 1
max=`cat $DIR/login.defs |grep ^PASS_MAX_DAYS |awk '{print $2}'`
if [ $max != 90 ];then
    sed -i '/^PASS_MAX_DAYS/s/'"$max"'/90/g' $DIR/login.defs
fi
 
##PASS_MIN_DAYS
min=`cat $DIR/login.defs |grep ^PASS_MIN_DAYS |awk '{print $2}'`
if [ $min != 0 ];then
    sed -i '/^PASS_MIN_DAYS/s/'"$min"'/0/g' $DIR/login.defs
fi
 
##PASS_MIN_LEN
len=`cat $DIR/login.defs |grep ^PASS_MIN_LEN |awk '{print $2}'`
if [ $len != 8 ];then
    sed -i '/^PASS_MIN_LEN/s/'"$len"'/8/g' $DIR/login.defs
fi


##PASS_WARN_AGE
warn=`cat $DIR/login.defs |grep ^PASS_WARN_AGE | awk '{print $2}'`
if [ $warn != 7 ];then
    sed -i '/^PASS_WARN_AGE/s/'"$warn"'/7/g' $DIR/login.defs
fi


###########################################################

echo "正在修改系统命令行保存条目..."
sleep 1
cat /etc/profile |grep ^HISTSIZE > /dev/null
if [ $? == 0 ];then
    sed -i 's/^HISTSIZE=[0-9]\{1,4\}/HISTSIZE=30/g' /etc/profile
fi
cat /etc/profile |grep ^HISTFILESIZE > /dev/null
if [ $? == 1 ];then
    echo "HISTFILESIZE=30" >> /etc/profile
fi
 
###############################################


echo "正在修改密码设置策略..."
sed -i "14i password requisite pam_cracklib.so retry=3 difok=3 minlen=10 ucredit=-1 lcredit=-2 dcredit=-1 ocredit=-1" /etc/pam.d/system-auth


#########################################################################


echo "设置终端超时时间"
echo export TMOUT=300 >> /etc/profile
source /etc/profile


#########################################################################

echo "正在启用审计策略..."
echo -e "-w /etc/group -p wa -k CFG_group\n-w /etc/passwd -p wa -k CFG_passwd\n-w /etc/gshadow -k CFG_gshadow\n-w /etc/shadow -k CFG_shadow" >> /etc/audit/audit.rules
service auditd restart

##########################################################################################

echo "限制用户登录次数"
sed -i '2i auth required pam_tally2.so deny=3 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/login
sed -i '2i auth required pam_tally2.so deny=3 unlock_time=300 even_deny_root root_unlock_time=300' /etc/pam.d/sshd