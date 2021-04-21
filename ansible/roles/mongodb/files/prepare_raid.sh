#!/bin/bash
sudo service mongod stop
sudo mdadm -Cv /dev/md0 --level=0 -n 4 /dev/xvdf /dev/xvdg /dev/xvdh /dev/xvdi
sudo mkfs.xfs /dev/md0
sudo mkdir /mnt/mongo
sudo mount /dev/md0 /mnt/mongo -o noatime
cd /mnt/mongo
sudo mkdir mongodb
sudo mkdir log
sudo chown -R mongodb *
sudo sed -i 's/\/var\/log\/mongodb\/mongod.log/\/mnt\/mongo\/log\/mongod.log/g' /etc/mongod.conf
sudo sed -i 's/\/var\/lib\/mongodb/\/mnt\/mongo\/mongodb/g' /etc/mongod.conf
sudo service mongod start
