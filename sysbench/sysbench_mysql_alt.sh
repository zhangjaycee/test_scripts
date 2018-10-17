#!/bin/bash

SSD_DEV=/dev/vdb1
HDD_DEV=/dev/vdc1
MYSQL_DEV_PATH=/mnt/mysql-img    # /mnt/mysql-img/mysql-data

if [ $# -ne 2 ]
then
    echo "Usage: $0 [ssd/hdd] [zlib/lz4/nochange]"
    exit -1
fi


# stop mysql first
service mysql.server stop

# unmount all devices
umount $SSD_DEV
umount $HDD_DEV

if [ $1 = ssd ]
then 
    mount $SSD_DEV $MYSQL_DEV_PATH 
elif [ $1 = hdd ]
then
    mount $HDD_DEV $MYSQL_DEV_PATH
else
    echo the 1st para is not hdd/ssd, error!
    exit -1
fi

if [ $2 = lz4 ]
then
    echo "reinit lz4-mysql"
    cd /usr/local/mysql-lz4
elif [ $2 = zlib ]
then
    echo "reinit zlib-mysql"
    cd /usr/local/mysql
elif [ $2 = nochange ]
then
    service mysql.server start
    echo "only change dev to $1, mysql nochange, done..."
    exit -1
else
    echo the 2nd para is not zlib/lz4, error!
    exit -1
fi

# copy the new mysql.server to init.d dir
cp support-files/mysql.server /etc/init.d/mysql.server

# reinit
rm -rf /mnt/mysql-img/mysql-data
scripts/mysql_install_db --user=mysql
service mysql.server start
./bin/mysqladmin -u root password '1234' # user: root  pass: 1234
/usr/local/mysql/bin/mysql -uroot -p1234 -e "create database sbtest;"
/usr/local/mysql/bin/mysql -uroot -p1234 -e "create database sbtest_cmp;"
/usr/local/mysql/bin/mysql -uroot -p1234 -e "show databases;"

echo "[$1 $2] done!"
