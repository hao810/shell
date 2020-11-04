#/bin/bash

gcc_check=`rpm -qa|grep ^gcc|grep -v gcc-c++|awk -F "-" '{print$1}'`
zlib_check=`rpm -qa|grep -o zlib-devel`
ndir=`cd "$(dirname $0)";pwd`
if [[ $gcc_check == gcc ]] && [[ $zlib_check == "zlib-devel" ]]
then
	echo "envir is successful"
else
	echo "please install gcc zlib-devel"
	exit 100
fi


group_check=`cat /etc/group|grep mfs |awk -F ":" '{print$1}'`
user_check=`cat /etc/passwd|grep mfs|awk -F ":" '{print$1}'`
if [[ $group_check != mfs ]]
then
        echo "group mfs is not exist,so create it now..."
        groupadd mfs
        echo "group mfs is create finish"
fi

if [[ $user_check != mfs ]]
then
        echo "user mfs is not exist,so create it now..."
        useradd -g mfs mfs
        echo 'mfs' | passwd --stdin mfs
        echo "user mfs is create finish"
fi

if [ -d /opt/server/mfs ]
then
	echo "dir /opt/server/mfs is ok"
else
	echo "dir /opt/server/mfs is not exist"
	mkdir -p /opt/server/mfs
	chmod 755 -R /opt/server
	echo "dir /opt/server is create"
fi



mfs_master(){
rm -rf $ndir/moosefs-2.0.88
tar -xf $ndir/moosefs-2.0.88-1.tar.gz -C $ndir
cd $ndir/moosefs-2.0.88 && ./configure --prefix=/opt/server/mfs --with-default-user=mfs --with-default-group=mfs --localstatedir=/opt/server/mfs/data --disable-mfschunkserver --disable-mfsmount

sleep 5

make && make install

sleep 5

cd /opt/server/mfs/etc/mfs

cp mfsmaster.cfg.dist mfsmaster.cfg
cp mfsmetalogger.cfg.dist mfsmetalogger.cfg
cp mfsexports.cfg.dist mfsexports.cfg

cp /opt/server/mfs/data/mfs/metadata.mfs.empty /opt/server/mfs/data/mfs/metadata.mfs


/opt/server/mfs/sbin/mfsmaster start
sleep 3
/opt/server/mfs/sbin//mfscgiserv
}

mfs_back(){
rm -rf $ndir/moosefs-2.0.88
tar -xf $ndir/moosefs-2.0.88-1.tar.gz -C $ndir
cd $ndir/moosefs-2.0.88 && ./configure --prefix=/opt/server/mfs --with-default-user=mfs --with-default-group=mfs --localstatedir=/opt/server/mfs/data --disable-mfschunkserver --disable-mfsmount
sleep 5
cd $ndir/moosefs-2.0.88 && make && make install

sleep 3

cd /opt/server/mfs/etc/mfs && cp mfsmetalogger.cfg.dist mfsmetalogger.cfg


stty erase '^H'
read -p "Input your master hostname:" master_n
sed -i '/^MASTER_HOST/s/^/#/' /opt/server/mfs/etc/mfs/mfsmetalogger.cfg
echo "MASTER_HOST = $master_n" >> /opt/server/mfs/etc/mfs/mfsmetalogger.cfg

/opt/server/mfs/sbin/mfsmetalogger start

}

mfs_chunk(){

read -p "Are you create mfshdd dir and remember it?(yes or no):" hddpd
if [[ $hddpd == yes ]]
then
	echo "ok"
else
	"Please mount your mfshdd"
	exit 100
fi


rm -rf $ndir/moosefs-2.0.88
tar -xf $ndir/moosefs-2.0.88-1.tar.gz -C $ndir
cd $ndir/moosefs-2.0.88 && ./configure --prefix=/opt/server/mfs --with-default-user=mfs --with-default-group=mfs --localstatedir=/opt/server/mfs/data --disable-mfsmaster
sleep 5

cd $ndir/moosefs-2.0.88 && make && make install

sleep 5

cd /opt/server/mfs/etc/mfs && cp mfschunkserver.cfg.dist mfschunkserver.cfg &&  cp mfshdd.cfg.dist mfshdd.cfg

stty erase '^H'
read -p "Please input your mfshdd dir:" mfshdddir
read -p "Input your master hostname:" master_n

chown mfs:mfs $mfshdddir
chmod 770 $mfshdddir

cp  /opt/server/mfs/etc/mfs/mfshdd.cfg  /opt/server/mfs/etc/mfs/mfshdd.cfg.bak
echo "$mfshdddir" > /opt/server/mfs/etc/mfs/mfshdd.cfg

sed -i '/^MASTER_HOST/s/^/#/' /opt/server/mfs/etc/mfs/mfschunkserver.cfg
echo "MASTER_HOST = $master_n" >> /opt/server/mfs/etc/mfs/mfschunkserver.cfg

/opt/server/mfs/sbin/mfschunkserver start


}

mfs_mount(){
fuse_check=`rpm -qa|grep -o "fuse-libs"`
fuse_name=`rpm -qa|grep fuse-libs`
if [[ $fuse_check == "fuse-libs" ]]
then
	echo "you hava install fuse,removing it now"
	rpm -e --nodeps $fuse_name
else
	echo "not install fuse ok"
fi

rm -rf $ndir/fuse-2.9.3
tar -xf $ndir/fuse-2.9.3.tar.gz -C $ndir
cd fuse-2.9.3 && ./configure && make && make install

yum -y install fuse-devel

fuse_devel_check=`rpm -qa|grep -o "fuse-devel"`
if [[ $fuse_devel_check == "fuse-devel" ]]
then
	echo "fuse-devel is ok"
else
	echo "fuse-devel is not ok"
	exit 100
fi

export PKG_CONFIG_PATH=/opt/server/lib/pkgconfig:$PKG_CONFIG_PATH
rm -rf $ndir/moosefs-2.0.88
tar -xf $ndir/moosefs-2.0.88-1.tar.gz -C $ndir
cd moosefs-2.0.88 && ./configure --prefix=/opt/server/mfs --with-default-user=mfs --with-default-group=mfs --localstatedir=/opt/server/mfs/data --disable-mfsmaster --enable-mfsmount && make && make install


mkdir -p /opt/data/z-cmp/shareddata
chmod 755 -R /opt/data
chown mfs.mfs -R /opt/server/mfs/


read -p "Input your master hostname:" master_n
/opt/server/mfs/bin/mfsmount /opt/data/z-cmp/shareddata -H $master_n

}



xwindows(){
cat<<EOF
#########################################################
#       Please input the number that you need           #
#       1.mfs-master                                    #
#       2.mfs-back                                      #
#       3.mfs-chunk                                	#
#       4.mfs-mount                                 	#
#       5.exit                                         #
#########################################################
EOF
stty erase '^H'
read -p "you choose:" choose


case $choose in
1)
        mfs_master
        xwindows
        ;;
2)
	mfs_back
	xwindows
	;;
3)
	mfs_chunk
	xwindows
	;;
4)
	mfs_mount
	xwindows
	;;
6)
	exit
	;;
esac
}

xwindows
