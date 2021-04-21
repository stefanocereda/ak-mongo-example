MONGODB_SERVER_IP=$1

RECORDCOUNT=$2
LOAD_THREADS=$3
WORKLOAD=$4

echo Creating db at $1 with $2 records using $3 threads for workload $4

mongo --host $MONGODB_SERVER_IP ycsb --eval "db.dropDatabase();"
cd /home/ubuntu/ycsb-0.17.0
./bin/ycsb load mongodb-async -s -P workloads/workload$WORKLOAD -threads $LOAD_THREADS  -p recordcount=$RECORDCOUNT -p mongodb.url=mongodb://$MONGODB_SERVER_IP:27017
