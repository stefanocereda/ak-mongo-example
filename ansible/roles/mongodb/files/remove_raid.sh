#!/bin/bash
sudo service mongod stop
sudo umount /dev/md0
sudo mdadm --stop /dev/md0
sudo mdadm --zero-superblock /dev/xvdf /dev/xvdg /dev/xvdh /dev/xvdi
sudo mkfs.xfs -f /dev/xvdf
sudo mkdir /mnt/mongo
sudo mount /dev/xvdf /mnt/mongo -o noatime
cd /mnt/mongo
sudo mkdir mongodb
sudo mkdir log
sudo chown -R mongodb *
sudo sed -i 's/\/var\/log\/mongodb\/mongod.log/\/mnt\/mongo\/log\/mongod.log/g' /etc/mongod.conf
sudo sed -i 's/\/var\/lib\/mongodb/\/mnt\/mongo\/mongodb/g' /etc/mongod.conf
sudo service mongod start
