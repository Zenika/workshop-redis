# Redis in Docker

This projet allow to test [Redis](https://redis.io) in master/replica and cluster.

You must have Docker installed to use this project.

## Build

To build, just run `./build.sh` script.

## Available configuration

### Redis Master/Replica

Master port `6000` in container `8600` out of container.

Slave port `6001` in container `8601` out of container.

Sentinels port `26000`, `26001`, `26002` only in container.

### Redis Cluster

Redis instance listen on `7000` to `7007` on container and `8700` to `8707` out of container.

## Run Redis in Master/Replica mode

To launch Redis, just run `./run.sh` script.

On container prompt:
```
$ /etc/init.d/redis.sh start master-slave
Starting redis master...
Starting redis slave...
Starting redis sentinels...
```

To see data on Redis, you can use a GUI client like [Medis](https://github.com/luin/medis) or [Redis Desktop Manager](https://redisdesktop.com/).

Now, run script on create data:
```
$ /redis/generate_redis_data.sh master-slave
```

You can you also `redis-cli`:
```
$ redis-cli -p 6000
127.0.0.1:6000> keys *
  1) "eJ1bcTbw8JjAcWbd2bEgkvFBgqoCkK7D"
  2) "qMVLPdnBatNG7j1XECWmjr7oOP9Lz4GS"
  3) "qGaGdPRRA9hoFO6QDMoKLlETjYycUjwz"
  ...
 97) "d5CKHGSi94yiQg0okIHDwe2WgN7QYiis"
 98) "nvLM1abc63ydHeoGRqCJ7pYcPrzd46TQ"
 99) "zZusCLj1d83McTx5Afpul4PPKvgMIrnW"
100) "iEQf0UYkfdaq1PmqiaPSLjKXQh4vG2UQ"
```

We can see that all data is on master.

### Shutdown master

Check that Redis instance that listen on `6000` port is master:
```
$ redis-cli -p 6000 info | grep -i 'role:'
role:master
```

Ok nice. Now, goto `/redis/master-slave/master/` and run `kill -s kill $(cat redis.pid)`.

Wait that slave set to master:
```
$ tail -f /redis/master-slave/slave/redis_slave.log
19:S 26 Oct 2018 16:53:15.160 * Connecting to MASTER 127.0.0.1:6000
19:S 26 Oct 2018 16:53:15.160 * MASTER <-> REPLICA sync started
19:S 26 Oct 2018 16:53:15.160 # Error condition on socket for SYNC: Connection refused
19:S 26 Oct 2018 16:53:16.164 * Connecting to MASTER 127.0.0.1:6000
19:S 26 Oct 2018 16:53:16.164 * MASTER <-> REPLICA sync started
19:S 26 Oct 2018 16:53:16.164 # Error condition on socket for SYNC: Connection refused
19:M 26 Oct 2018 16:53:17.090 # Setting secondary replication ID to d9c12feccb67807362ad01537d1eca91d1710cdd, valid up to offset: 610861. New replication ID is d5b66ee0fa30101b1bbc806100d4442d74924f64
19:M 26 Oct 2018 16:53:17.090 * Discarding previously cached master state.
19:M 26 Oct 2018 16:53:17.090 * MASTER MODE enabled (user request from 'id=3 addr=127.0.0.1:57004 fd=9 name=sentinel-sentinel-cmd age=992 idle=0 flags=x db=0 sub=0 psub=0 multi=3 qbuf=140 qbuf-free=32628 obl=36 oll=0 omem=0 events=r cmd=exec')
19:M 26 Oct 2018 16:53:17.093 # CONFIG REWRITE executed with success.
```

Check that Redis instance that listen on `6001` port is master:
```
$ redis-cli -p 6001 info | grep -i 'role:'
role:master
```

Now restart old master with `redis-server redis_master.cfg &` and check state. Wait one or two minutes:
```
$ redis-cli -p 6000 info | grep -i 'role:'
role:slave
```

Now old master is slave.

If you show config file of master `/redis/master-slave/master/redis_master.cfg`, you see now line `replicaof`, that disappear in slave configuration file:
```
# Generated by CONFIG REWRITE
replicaof 127.0.0.1 6001
```

### Replication

To illustrate synchronization between master and slave, restart container and restart master/slave.

First run this command:
```
$ redis-cli -p 6000 set toto 1 ; redis-cli -p 6000 bgsave ; kill -s kill $(cat /redis/master-slave/slave/redis.pid)
```

`set toto 1` create a data named `toto` with value `1`.

`bgsave` force Redis to save data on disk.

After, we kill slave.

Now, we stop master (to ensure data can be synchonize):
```
$ kill -s kill $(cat /redis/master-slave/master/redis.pid)
```

Now, restart slave and display data:
```
$ redis-server /redis/master-slave/slave/redis_slave.cfg &
$ redis-cli -p 6001 keys '*'
(empty list or set)
```

No data can be found, cause master don't have enough time to synchronize data with slave.

## Run Redis in Cluster mode

To run, just run `./run.sh` script.

On container prompt:
```
$ /etc/init.d/redis.sh start cluster
Wait 5 secondes to all cluster instances start
....>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 127.0.0.1:7003 to 127.0.0.1:7000
Adding replica 127.0.0.1:7004 to 127.0.0.1:7001
Adding replica 127.0.0.1:7005 to 127.0.0.1:7002
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
Can I set the above configuration? (type 'yes' to accept):
```

Enter `yes`.

```
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
....
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   slots: (0 slots) slave
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   slots: (0 slots) slave
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
* Starting MariaDB database server mysqld                                 [ OK ]
* Starting Apache httpd web server apache2
```

Now, run script on create data:
```
$ /redis/generate_redis_data.sh cluster
```

Look keys in first master cluster:
```
$ redis-cli -p 7000 keys '*'
 1) "TnbcVxQjPKNMEvhlKuscWfQKNDJiXM18"
 2) "t7rRJQBriPyfw7my4cUSNjdTdmZAyYcE"
 3) "5Vr9GYIcimtF9hETWl94WoFOChMhwCmK"
 ...
32) "cSli7q3j2iUpxGv6FoNMG3PDwl4vNrr4"
33) "6EE2F5ne29cxG383nivZ66fClvCouoke"
root@e1fe9f282d5c:/#
```

Look keys in second master cluster:
```
$ redis-cli -p 7001 keys '*'
 1) "3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF"
 2) "m62FmXaDOyzgDN1vZwp5I3FB31kgyTnx"
 ...
35) "yklLlMfdna53ewKqU6Ja4P9ofeAYYB4b"
36) "jXteDYAwLJMcJFrE5PJ2tHK7ZsCPCUio"
```

Look keys in third master cluster:
```
$ redis-cli -p 7002 keys '*'
 1) "PUN7AF51lADTYkI8Gd3RVwvr4RYsxmwd"
 2) "f0v95JRAfI2N4U3E47WBkeULjz7NWQCV"
 ...
30) "71pCSCo5O3a6Lyuq6aKJHUhW1bUZydEh"
31) "o3PxUH8dNZ0h8bJFjPuA0pKToOOBVCRS"
```

### Add a master node

We add a new master cluster node with command `redis-cli --cluster add-node 127.0.0.1:7006 127.0.0.1:7000`:
```
>>> Adding node 127.0.0.1:7006 to cluster 127.0.0.1:7000
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   slots: (0 slots) slave
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   slots: (0 slots) slave
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 127.0.0.1:7006 to make it join the cluster.
[OK] New node added correctly.
```

Check cluster:
```
$ redis-cli -p 7000 cluster nodes
3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005@17005 slave cde568ebf52c306b31ccc488d565a562e11e9d69 0 1540804897961 6 connected
d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004@17004 slave e967ab19a518a7080e61369e0d217f59a80da5ae 0 1540804897000 5 connected
36b21a7b5611758a4bd785d707508659b9ae5db1 127.0.0.1:7006@17006 master - 0 1540804896958 0 connected
c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003@17003 slave 07e9d6e898140c752e8edc16227a3fefc865ed13 0 1540804897560 4 connected
07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002@17002 master - 0 1540804896557 3 connected 10923-16383
cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001@17001 master - 0 1540804898062 2 connected 5461-10922
e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000@17000 myself,master - 0 1540804897000 1 connected 0-5460
```

We see cluster masters:
 - `127.0.0.1:7000`: with slots `0` to `5460`,
 - `127.0.0.1:7001`: with slots `5461` to `10922`,
 - `127.0.0.1:7002`: with slots `10923` to `16383`,
 - `127.0.0.1:7006`: with no slot.

### Add a cluster node

Add slave to out new master `127.0.0.1:7006` by using his id `36b21a7b5611758a4bd785d707508659b9ae5db1` (found in previous command).

Command is `redis-cli --cluster add-node 127.0.0.1:7007 127.0.0.1:7000 --cluster-slave --cluster-master-id 36b21a7b5611758a4bd785d707508659b9ae5db1`
```
>>> Adding node 127.0.0.1:7007 to cluster 127.0.0.1:7000
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   slots: (0 slots) slave
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   slots: (0 slots) slave
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
M: 36b21a7b5611758a4bd785d707508659b9ae5db1 127.0.0.1:7006
   slots: (0 slots) master
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Send CLUSTER MEET to node 127.0.0.1:7007 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 127.0.0.1:7006.
[OK] New node added correctly.
```

### Reshard data

Now we have A new node and slave but without slot. We must reshard data.

Look empty data:
```
$ redis-cli -c -p 7006 keys '*'
```

Run resharing with `redis-cli --cluster reshard 127.0.0.1:7000`

```
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   slots: (0 slots) slave
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   slots: (0 slots) slave
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
M: 36b21a7b5611758a4bd785d707508659b9ae5db1 127.0.0.1:7006
   slots: (0 slots) master
   1 additional replica(s)
S: 4c30c5aea626dbc6b07d152ec496757d03071f18 127.0.0.1:7007
   slots: (0 slots) slave
   replicates 36b21a7b5611758a4bd785d707508659b9ae5db1
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

Redis tell us number of slot (16384 / 4):
```
How many slots do you want to move (from 1 to 16384)? 4096
```

Redis tell us the id of new master:
```
What is the receiving node ID? 36b21a7b5611758a4bd785d707508659b9ae5db1
```

Now Redis ask to us where take data. We say all nodes.
```
Please enter all the source node IDs.
  Type 'all' to use all the nodes as source nodes for the hash slots.
  Type 'done' once you entered all the source nodes IDs.
Source node #1: all
```

After we see a very long logs:
```
Moving slot 12284 from 127.0.0.1:7002 to 127.0.0.1:7006:
Moving slot 12285 from 127.0.0.1:7002 to 127.0.0.1:7006:
Moving slot 12286 from 127.0.0.1:7002 to 127.0.0.1:7006:
Moving slot 12287 from 127.0.0.1:7002 to 127.0.0.1:7006:
```

Check cluster:
```
$ redis-cli -p 7000 cluster nodes
3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005@17005 slave cde568ebf52c306b31ccc488d565a562e11e9d69 0 1540805904572 6 connected
d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004@17004 slave e967ab19a518a7080e61369e0d217f59a80da5ae 0 1540805905000 5 connected
36b21a7b5611758a4bd785d707508659b9ae5db1 127.0.0.1:7006@17006 master - 0 1540805905573 7 connected 0-1364 5461-6826 10923-12287
4c30c5aea626dbc6b07d152ec496757d03071f18 127.0.0.1:7007@17007 slave 36b21a7b5611758a4bd785d707508659b9ae5db1 0 1540805905000 7 connected
c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003@17003 slave 07e9d6e898140c752e8edc16227a3fefc865ed13 0 1540805905273 4 connected
07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002@17002 master - 0 1540805906275 3 connected 12288-16383
cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001@17001 master - 0 1540805905000 2 connected 6827-10922
e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000@17000 myself,master - 0 1540805903000 1 connected 1365-5460
```

We see cluster masters:
 - `127.0.0.1:7000`: with slots `1365` to `5460`,
 - `127.0.0.1:7001`: with slots `6827` to `10922`,
 - `127.0.0.1:7002`: with slots `12288` to `16383`,
 - `127.0.0.1:7006`: with slots `0` to `1364` and `5461` to `6826` and `10923` to `12287`,

You can also use `redis-cli --cluster check 127.0.0.1:7000`:
```
127.0.0.1:7000 (e967ab19...) -> 66 keys | 4096 slots | 1 slaves.
127.0.0.1:7006 (36b21a7b...) -> 73 keys | 4096 slots | 1 slaves.
127.0.0.1:7002 (07e9d6e8...) -> 84 keys | 4096 slots | 1 slaves.
127.0.0.1:7001 (cde568eb...) -> 70 keys | 4096 slots | 1 slaves.
[OK] 293 keys in 4 masters.
0.02 keys per slot on average.
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: e967ab19a518a7080e61369e0d217f59a80da5ae 127.0.0.1:7000
   slots:[1365-5460] (4096 slots) master
   1 additional replica(s)
S: 3c16e7fd9ded7e00b39b04f526ce863bc832462e 127.0.0.1:7005
   slots: (0 slots) slave
   replicates cde568ebf52c306b31ccc488d565a562e11e9d69
S: d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad 127.0.0.1:7004
   slots: (0 slots) slave
   replicates e967ab19a518a7080e61369e0d217f59a80da5ae
M: 36b21a7b5611758a4bd785d707508659b9ae5db1 127.0.0.1:7006
   slots:[0-1364],[5461-6826],[10923-12287] (4096 slots) master
   1 additional replica(s)
S: 4c30c5aea626dbc6b07d152ec496757d03071f18 127.0.0.1:7007
   slots: (0 slots) slave
   replicates 36b21a7b5611758a4bd785d707508659b9ae5db1
S: c0c1965884be6be0d50faacb2461d3180093e147 127.0.0.1:7003
   slots: (0 slots) slave
   replicates 07e9d6e898140c752e8edc16227a3fefc865ed13
M: 07e9d6e898140c752e8edc16227a3fefc865ed13 127.0.0.1:7002
   slots:[12288-16383] (4096 slots) master
   1 additional replica(s)
M: cde568ebf52c306b31ccc488d565a562e11e9d69 127.0.0.1:7001
   slots:[6827-10922] (4096 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

### Find where a key is stored

You cannot get all keys from a Redis Cluster in one time.

You must connect to all master nodes and list keys by using Redis command `KEYS *`.

If you know name of key, you can find which node store this key.

If we take a key list above `3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF`
```
$ redis-cli -p 7002 -c CLUSTER KEYSLOT "3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF"
(integer) 1930
```
Note: we can use any master to run this command.

The slot is `1930`.

Now list all slots:
```
redis-cli -p 7002 -c CLUSTER SLOTS                                                                                                  
1) 1) (integer) 12288
   2) (integer) 16383
   3) 1) "127.0.0.1"
      2) (integer) 7002
      3) "07e9d6e898140c752e8edc16227a3fefc865ed13"
   4) 1) "127.0.0.1"
      2) (integer) 7003
      3) "c0c1965884be6be0d50faacb2461d3180093e147"
2) 1) (integer) 0
   2) (integer) 1364
   3) 1) "127.0.0.1"
      2) (integer) 7006
      3) "36b21a7b5611758a4bd785d707508659b9ae5db1"
   4) 1) "127.0.0.1"
      2) (integer) 7007
      3) "4c30c5aea626dbc6b07d152ec496757d03071f18"
3) 1) (integer) 5461
   2) (integer) 6826
   3) 1) "127.0.0.1"
      2) (integer) 7006
      3) "36b21a7b5611758a4bd785d707508659b9ae5db1"
   4) 1) "127.0.0.1"
      2) (integer) 7007
      3) "4c30c5aea626dbc6b07d152ec496757d03071f18"
4) 1) (integer) 10923
   2) (integer) 12287
   3) 1) "127.0.0.1"
      2) (integer) 7006
      3) "36b21a7b5611758a4bd785d707508659b9ae5db1"
   4) 1) "127.0.0.1"
      2) (integer) 7007
      3) "4c30c5aea626dbc6b07d152ec496757d03071f18"
5) 1) (integer) 1365
   2) (integer) 5460
   3) 1) "127.0.0.1"
      2) (integer) 7000
      3) "e967ab19a518a7080e61369e0d217f59a80da5ae"
   4) 1) "127.0.0.1"
      2) (integer) 7004
      3) "d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad"
6) 1) (integer) 6827
   2) (integer) 10922
   3) 1) "127.0.0.1"
      2) (integer) 7001
      3) "cde568ebf52c306b31ccc488d565a562e11e9d69"
   4) 1) "127.0.0.1"
      2) (integer) 7005
      3) "3c16e7fd9ded7e00b39b04f526ce863bc832462e"
```

Our slot is here:
```
5) 1) (integer) 1365
   2) (integer) 5460
   3) 1) "127.0.0.1"
      2) (integer) 7000
      3) "e967ab19a518a7080e61369e0d217f59a80da5ae"
   4) 1) "127.0.0.1"
      2) (integer) 7004
      3) "d763e2b00dcf9ccc2541dd3cfc06b37e9107b0ad"
```

Check on master:
```
$ redis-cli -p 7000 -c KEYS '*' | grep "3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF"
3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF
```
or (without `-c` or `--cluster` options):
```
$ redis-cli -p 7000 GET "3Cwx8lTaPt7fdj0AFd9uDUqoIPLA01iF"
36
```


Nice !