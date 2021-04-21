#!/bin/bash
sudo service mongod stop
sudo umount /mnt/mongo
sudo mkfs.ext4 /dev/xvdf
sudo mkdir /mnt/mongo
sudo mount /dev/xvdf /mnt/mongo -o noatime
cd /mnt/mongo
sudo mkdir mongodb
sudo mkdir log
sudo chown -R mongodb *
sudo sed -i 's/\/var\/log\/mongodb\/mongod.log/\/mnt\/mongo\/log\/mongod.log/g' /etc/mongod.conf
sudo sed -i 's/\/var\/lib\/mongodb/\/mnt\/mongo\/mongodb/g' /etc/mongod.conf
sudo service mongod start
