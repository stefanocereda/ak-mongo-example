# Our goal
In the following we will see how to conduct a performance test on a database and check whether performance theory stands the test of practice, how to detect what is limiting performance and how to remove bottlenecks.

# Infrastructure setup
To do this, we need to create an infrastructure composed by three components:
* a master machine to collect data and orchestrate the experiments
* a server machine running the MongoDB database
* a client machine running the YCSB program, which we use to simulate load on the database
We do not want to create everything manually, so we use ansible to automate the setup.

## Master node
Let's start by manually creating a master instance on Amazon. We will use this machine to manage all our infrastructure and we do not need much resources, so we can use a t2.micro running ubuntu 20.04.
Take note of your private key location and of the master node public ip from AWS, then use the following commands to install ansible on the newly created instance:
```
ssh -i [your_private_key] ubuntu@[master_ip]
# Here we are on the master node
sudo apt update
sudo apt install -y ansible
exit
```

And copy your private key from your pc to the new instance. In this way the master node will be able to connect to the two other instances:
```
scp -i [your_private_key]  [your_private_key] ubuntu@[master_ip]:.ssh/id_rsa
```

## YCSB and MongoDB nodes
Now go on AWS and create two other instances: the client and the master node. For both of them we use c4.large instances, on the server one we use a larger disk: 15GB.
Notice that we could use ansible also to automate the instance creation process.
Start by copying the ansible directory (close to this readme) to the master node, then insert the public and private addresses of the new instances in the hosts file:
```
scp -i [your_private_key] -r ./ansible ubuntu@[master_ip]:
ssh -i [your_private_key] ubuntu@[master_ip]
cd ansible
nano hosts  # even better, vim hosts
```

We can now use ansible to automatically install some tools on the three machines:
```
ansible-galaxy install cloudalchemy.prometheus
ansible-galaxy install cloudalchemy.node_exporter
ansible-galaxy install cloudalchemy.grafana
ansible-playbook -i hosts deploy.yml
```
And type yes when asked (three times).

# Let's run some performance tests
We can now use YCSB to inject some load into MongoDB and use the collected metrics to check some performance laws.
We will also use the grafana dashboard to analise some metrics collected through the prometheus node exporter.
To run the test, we use ansible again:
```
ansible-playbook -i hosts run_tests.yaml
```
After a while (~1 hour), a log file will be available on the master node:
```
cat test_log.txt
```
In the following we analise the collected data.
The tests are doing the following:
* Run a short test (30 seconds) with 10 users looking for the maximum throughput
* Run many short tests targeting for lower throughputs (from 100 ops/sec to 5000 ops/sec)
* Run many short tests varying the number of connected users (from 1 to 100)
* Run a long test (1 hour) with 10 users looking for the maximum throughput

## Is Lazowska right?
We start by looking at the results of the first three tests, and use the collected data to empirically show the effect of some performance laws.

* From the first test, we obtain a maximum throughput X_max = 4016 ops/sec.
* We use the second test to see how the response time varies with the throughput (N=XR-Z).
* From the third test, we obtain the bounds on X and R.

You can look at the mongo.ods file for the analysis, but the takeaway message is that the theory is indeed correct, and it can help in making predictions.


## A longer test
As we said, after the initial short tests we run a longer one. In this test we are not only interested in the *average* throughput obtain during the whole test, but we are interested in how stable is the throughput.
As the test proceeds we observe that, after a while (~ half an hour), the throughput _drammatically_ drops.

At this point we recognize that we have a performance problem, and use the monitoring platform we installed with ansible to understand what is the problem: http://3.22.116.66:3000/d/rYdddlPWk/node-exporter-full?orgId=1&from=1618989229211&to=1618994400198&var-prometheus=prometheus&var-job=mongodb-server&var-node=MongoDB&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B

By looking at the high iowait time in the CPU basic graph, we start to suspect a problem in the disk.
We then move to the Storage Disk panel, and observe a drop in the disk IOPS and R/W values.
At this point we immediately detect our mistake: we are running our DBMS on an Amazon instance with a burstable amount of IOPS, meaning that we can substain high IO rates for a certain amount of time, but then they will be reduced.
(Notice, however, that we need to already have this piece of information in order to detect the problem.)

At this point we decide to move the database to a much faster disk, which is not burstable. While we're at it, we also decide to use a RAID-0, which should give use much higher performance.


## Adding a RAID-0
Let's create four 10GB SSD (gp3) disks on Amazon and attach them to our MongoDB machine.
We use the disks to create a RAID-0 and format the disk with XFS, wich is the usually suggested filesystem for databases.
We can use the ansible playbook run_tests_raid.yaml to create the raid, format it, recreate the dataset and launch again the tests:
```
ansible-playbook -i hosts run_tests_raid.yaml
cat test_raid_log.txt
```

With the 4-disk RAID, we see that the database has become slower (X_max=3467), but at least the throughput is stable.
Looking at the grafana dashboard, we do not see any sudden change in the metrics:
http://3.22.116.66:3000/d/rYdddlPWk/node-exporter-full?orgId=1&from=1618994250466&to=1618998649012&var-prometheus=prometheus&var-job=mongodb-server&var-node=MongoDB&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B
Hoewer, we see that we still have a very high iowait.


## Removing the RAID
At this point, we try to remove the RAID and use a single disk:
```
ansible-playbook -i hosts run_tests_noraid.yaml
cat test_noraid_log.txt
```
The throughput is stable, and equal to the one we had with the RAID!


## Changing the filesystem
We still are not happy with performance. We thus look at mongodb configuration suggestions:
https://docs.mongodb.com/manual/administration/production-notes/
Where we discover that:
> When running MongoDB in production on Linux, you should use Linux kernel version 2.6.36 or later, with either the XFS or EXT4 filesystem. If possible, use XFS as it generally performs better with MongoDB.

So far we have used an XFS filesystem, let's see if they are right and move our database to EXT4:
```
ansible-playbook -i hosts run_tests_ext4.yaml
cat test_ext4_log.txt
```


Ouch! MongoDB production notes are wrong! Or maybe the optimal configuration depends on you workload?
Let's find out with https://www.akamas.io/
