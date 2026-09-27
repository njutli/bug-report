sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n env CEPH_ADMIN_SOCKET=none CEPH_LOG_FILE=none /RESULTS/20260927-LT002-C2/juicefs-lt002-idle-candidate mount -d --cache-size 0 --max-uploads 150 --backup-meta 0 --compact-interval 0 --subdir /TEST_SUBTREE/20260927-LT002-C2 --metrics 127.0.0.1:9569 --log=/RESULTS/20260927-LT002-C2/client-off.log -o allow_other,default_permissions tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/mnt
findmnt -n -M /RESULTS/20260927-LT002-C2/mnt -o ID,TARGET,SOURCE,FSTYPE
ps -eo pid=,ppid=,args=
findmnt -n -M /RESULTS/20260927-LT002-C2/mnt -o ID,TARGET,SOURCE,FSTYPE
sudo -n cat /RESULTS/20260927-LT002-C2/mnt/.config
ps -eo pid=,ppid=,args=
sudo -n readlink /proc/996038/exe
sudo -n readlink /proc/996063/exe
fio --name=lt002-c1 --filename=/RESULTS/20260927-LT002-C2/mnt/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C2/layout/fio.json --rw=write --bs=4M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --rate=,16M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/RESULTS/20260927-LT002-C2/mnt/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C2/layout-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/layout-meta/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/RESULTS/20260927-LT002-C2/mnt/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C2/overwrite/fio.json --rw=randwrite --numjobs=16 --size=64M --offset_increment=64M --io_size=512M --rate=,1M --verify=crc32c --verify_interval=256K --do_verify=0 --end_fsync=1 --randrepeat=1 --randseed=270927
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
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/off-idle-start/meta.json.gz
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
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/off-idle-end/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/off-confirm-00/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
findmnt -n -M /RESULTS/20260927-LT002-C2/mnt -o ID,TARGET,SOURCE,FSTYPE
sudo -n cat /RESULTS/20260927-LT002-C2/mnt/.config
ps -eo pid=,ppid=,args=
sudo -n readlink /proc/996038/exe
sudo -n readlink /proc/996063/exe
sudo -n /usr/bin/fusermount3 -u /RESULTS/20260927-LT002-C2/mnt
ps -eo pid=,ppid=,args=
sudo -n readlink /proc/996038/exe
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/off-unmounted/meta.json.gz
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/off-unmounted-recheck/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n env CEPH_ADMIN_SOCKET=none CEPH_LOG_FILE=none /RESULTS/20260927-LT002-C2/juicefs-lt002-idle-candidate mount -d --cache-size 0 --max-uploads 150 --backup-meta 0 --compact-interval 15s --subdir /TEST_SUBTREE/20260927-LT002-C2 --metrics 127.0.0.1:9569 --log=/RESULTS/20260927-LT002-C2/client-on.log -o allow_other,default_permissions tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/mnt
findmnt -n -M /RESULTS/20260927-LT002-C2/mnt -o ID,TARGET,SOURCE,FSTYPE
sudo -n cat /RESULTS/20260927-LT002-C2/mnt/.config
ps -eo pid=,ppid=,args=
sudo -n readlink /proc/1001283/exe
sudo -n readlink /proc/1001308/exe
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/on-observe-00/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/on-observe-01/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/on-observe-02/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
/tmp/juicefs-1.4.1-patched dump --threads 1 --subdir /TEST_SUBTREE/20260927-LT002-C2 --skip-trash tikv://STORAGE_A:2379,STORAGE_B:2379,STORAGE_C:2379/test-volume /RESULTS/20260927-LT002-C2/on-observe-03/meta.json.gz
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
fio --name=lt002-c1 --filename=/RESULTS/20260927-LT002-C2/mnt/cycle.dat --filesize=1G --size=1G --numjobs=1 --ioengine=libaio --direct=1 --bs=256K --iodepth=4 --fallocate=none --allow_file_create=0 --group_reporting --verify_state_save=0 --verify_state_load=0 --verify_dump=0 --lat_percentiles=1 --percentile_list=95:99:99.9 --output-format=json --output=/RESULTS/20260927-LT002-C2/final-verify/fio.json --readonly --rw=read --verify=crc32c --verify_interval=256K --verify_only=1 --verify_fatal=1 --rate=32M
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
findmnt -n -M /RESULTS/20260927-LT002-C2/mnt -o ID,TARGET,SOURCE,FSTYPE
sudo -n cat /RESULTS/20260927-LT002-C2/mnt/.config
ps -eo pid=,ppid=,args=
sudo -n readlink /proc/1001283/exe
sudo -n readlink /proc/1001308/exe
sudo -n /usr/bin/fusermount3 -u /RESULTS/20260927-LT002-C2/mnt
ps -eo pid=,ppid=,args=
ss -lnt
findmnt -n -M /TEST_MOUNT -o ID,TARGET,SOURCE,FSTYPE
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin -s --format json
sudo -n ceph --conf /etc/ceph/ceph.conf --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin df detail --format json
