hostname
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260924-102324/LT-002/randrw256k --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/old-before/meta.json.gz
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.120.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/read-before/fio.json --readonly --rw=randread --iodepth=1 --rate=8M --time_based=1 --runtime=120 --randrepeat=1 --randseed=270927 --log_avg_msec=1000 --write_bw_log=/RESULTS/20260927-LT002-C1/read-before/bw --write_lat_log=/RESULTS/20260927-LT002-C1/read-before/lat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.120.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/read-during/fio.json --readonly --rw=randread --iodepth=1 --rate=8M --time_based=1 --runtime=120 --randrepeat=1 --randseed=270927 --log_avg_msec=1000 --write_bw_log=/RESULTS/20260927-LT002-C1/read-during/bw --write_lat_log=/RESULTS/20260927-LT002-C1/read-during/lat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.0.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.1.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.2.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.3.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.4.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.5.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.6.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.7.0
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260924-102324/LT-002/randrw256k --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/old-after/meta.json.gz
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.120.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/read-after/fio.json --readonly --rw=randread --iodepth=1 --rate=8M --time_based=1 --runtime=120 --randrepeat=1 --randseed=270927 --log_avg_msec=1000 --write_bw_log=/RESULTS/20260927-LT002-C1/read-after/bw --write_lat_log=/RESULTS/20260927-LT002-C1/read-after/lat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.0.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-00/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.1.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-01/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.2.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-02/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.3.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-03/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.4.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-04/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.5.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-05/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.6.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-06/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260924-102324/LT-002/randrw256k/lt.7.0 --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/old-verify-07/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-layout/fio.json --rw=write --bs=4M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --rate=,16M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-layout-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-1-write/fio.json --rw=randwrite --io_size=8G --rate=,16M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --randrepeat=1 --randseed=270928
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-1-before/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-1-after/meta.json.gz
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-1-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-2-write/fio.json --rw=randwrite --io_size=8G --rate=,16M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --randrepeat=1 --randseed=270929
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-2-before/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-2-after/meta.json.gz
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-2-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-3-write/fio.json --rw=randwrite --io_size=8G --rate=,16M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --randrepeat=1 --randseed=270930
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-3-before/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
nice -n 15 ionice -c 2 -n 7 /tmp/juicefs-1.4.1-patched compact --threads 1 /TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C1 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C1/cycle-3-after/meta.json.gz
fio --name=lt002-c1 --filename=/TEST_MOUNT/TEST_SUBTREE/20260927-LT002-C1/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C1/cycle-3-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
