#!/bin/bash

MONGODB_SERVER_IP={{ mongodb_fqdn }}
RECORDCOUNT=3000000  # number of records
WORKLOAD='a'  # workload type
LOAD_THREADS=10
RUN_THREADS=16  # number of threads to use (= number of users N)
DURATION=30  # duration of test in seconds
RECORDCOUNT=3000000

cd "$(dirname "${0}")" || exit

db_records=$(cat db_records)
if [[ $RECORDCOUNT != "$db_records" ]]; then
        echo "Populating the database..."
        bash ./create_db.sh $MONGODB_SERVER_IP $RECORDCOUNT $LOAD_THREADS $WORKLOAD
        echo $RECORDCOUNT > db_records
fi

cd /home/ubuntu/ycsb-0.17.0 || exit

# Test 1, find the maximum throughput
echo "##########"
echo Running test for X_max
./bin/ycsb run mongodb-async -s -P workloads/workload$WORKLOAD -threads $RUN_THREADS  -p recordcount=$RECORDCOUNT -p operationcount=$RECORDCOUNT -p maxexecutiontime=$DURATION -p mongodb.url=mongodb://$MONGODB_SERVER_IP:27017 2>&1

# Test 2, use lower target throughputs
for TGT_X in 100 200 300 500 1000 2000 3000 5000; do
	echo "##########"
        echo Running test for X=$TGT_X
        ./bin/ycsb run mongodb-async -s -P workloads/workload$WORKLOAD -threads $RUN_THREADS  -p recordcount=$RECORDCOUNT -p operationcount=$RECORDCOUNT -p maxexecutiontime=$DURATION -target $TGT_X -p mongodb.url=mongodb://$MONGODB_SERVER_IP:27017 2>&1
done

# Test 3, vary the number of users
for N in 1 2 3 4 5 10 20 30 50 100; do
	echo "##########"
        echo Running test for N=$N
        ./bin/ycsb run mongodb-async -s -P workloads/workload$WORKLOAD -threads $N  -p recordcount=$RECORDCOUNT -p operationcount=$RECORDCOUNT -p maxexecutiontime=$DURATION -p mongodb.url=mongodb://$MONGODB_SERVER_IP:27017 2>&1
done

# Test 4, run for a longer time
DURATION=3600
echo "##########"
echo Running longer test
./bin/ycsb run mongodb-async -s -P workloads/workload$WORKLOAD -threads $RUN_THREADS  -p recordcount=$RECORDCOUNT -p operationcount=${RECORDCOUNT}00 -p maxexecutiontime=$DURATION -p mongodb.url=mongodb://$MONGODB_SERVER_IP:27017 2>&1
