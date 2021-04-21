# MongoDB setup as per https://docs.mongodb.com/manual/installation/

# We start by setting up the instance following the instructions at: https://docs.mongodb.com/manual/administration/production-notes/

# adjust ulimit according to https://docs.mongodb.com/manual/reference/ulimit/
echo "*	soft	fsize unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	hard	fsize unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	soft	cpu unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	hard	cpu unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	soft	as unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	hard	as unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	soft	memlock unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	hard	memlock unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	soft	nofile 64000" | sudo tee -a /etc/security/limits.conf
echo "*	hard	nofile 64000" | sudo tee -a /etc/security/limits.conf
echo "*	soft	rss unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	hard	rss unlimited" | sudo tee -a /etc/security/limits.conf
echo "*	soft	nproc 64000" | sudo tee -a /etc/security/limits.conf
echo "*	hard	nproc 64000" | sudo tee -a /etc/security/limits.conf

# we have no swap
# readeahead 8/32 -> 16
echo 16 | sudo tee /sys/block/xvda/queue/read_ahead_kb

# add the repositories for official mongodb
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# configure mongodb
sudo sed -i s/127.0.0.1/0.0.0.0/g /etc/mongod.conf

# Start MongoDB
sudo systemctl start mongod
