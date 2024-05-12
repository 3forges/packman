disk on server:

```bash
ubuntu@myserver:~/cubefs_decoderleco$ sudo df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           2.4G  2.3M  2.4G   1% /run
/dev/sda1        45G   16G   30G  35% /
tmpfs            12G     0   12G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda15       98M  6.3M   92M   7% /boot/efi
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/51acd0596da000e41128a45a2a05effeea54cbe4ed1d73c11d4b6deba235b241/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/b829ca3136e0c525bc3b12fa75fa9d4b391e010c681c09e1dc1777c835d2cf57/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/47be2bae763ac43ff2564d18766264dfdaadb5c4bbbae6a699837dd1e70266a2/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/256400ab29fbec2a6c44d6ee9e0e75fd1428cc151b5b1b19ccc23b85b0a9c0fe/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/a27b516c08ccc641bea0080fbdea167dcb9a5f83e0630048ad91f2bcab6dd6a2/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/6c0fedb11a8f4f9e5f07465eed490510d5557f2e0fa780446ed9354087ddc3c8/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/2e08dea8d2bad7e900b70f946d430cd0fab67695b2a406ab828ff3762e0cc771/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/04962b2991a7b052a445d71d38c1ccb39b1d48bba0e2deed6806fbe1077611ba/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/4e7a421732dc9d58d3ebfa7a15f72d5691ad2c03e377fd2dd3ea4f6aa48d82f1/merged
overlay          45G   16G   30G  35% /var/lib/docker/overlay2/bd1eafe4fde4b99e1c03d25532e54669f178e5277b4df7b78a3e8cad9cce03a5/merged
tmpfs           2.4G  4.0K  2.4G   1% /run/user/1001
ubuntu@myserver:~/cubefs_decoderleco$ sudo fdisk -l
Disk /dev/loop0: 49.12 MiB, 51503104 bytes, 100592 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop1: 26.23 MiB, 27500544 bytes, 53712 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop2: 35.21 MiB, 36921344 bytes, 72112 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 46.58 GiB, 50010783744 bytes, 97677312 sectors
Disk model: BlockVolume
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 1048576 bytes
Disklabel type: gpt
Disk identifier: 6B2FA711-55F7-4CAD-B59A-45A2932A8201

Device      Start      End  Sectors  Size Type
/dev/sda1  206848 97677278 97470431 46.5G Linux filesystem
/dev/sda15   2048   204800   202753   99M EFI System

Partition table entries are not in disk order.

```


no arm64 support for CubeFS for now:

```
WARN[0000] /home/ubuntu/cubefs_decoderleco/docker/docker-compose.yml: `version` is obsolete
[+] Running 4/4
 ✔ nginx Pulled                                                                                                                                                                3.6s
   ✔ f338bc35613f Pull complete                                                                                                                                                0.7s
   ✔ 7b930194d9b2 Pull complete                                                                                                                                                1.6s
   ✔ 5231e32866d4 Pull complete                                                                                                                                                0.5s
[+] Running 39/39
 ✔ Container docker-metanode4-1                                                                                                                               Started          0.8s
 ✔ Container docker-master2-1                                                                                                                                 Started          0.8s
 ✔ Container docker-datanode3-1                                                                                                                               Started          0.8s
 ✔ Container docker-lcnode2-1                                                                                                                                 Started          0.8s
 ✔ Container docker-metanode1-1                                                                                                                               Started          0.8s
 ✔ Container docker-metanode2-1                                                                                                                               Started          0.8s
 ✔ Container docker-objectnode3-1                                                                                                                             Started          0.8s
 ✔ Container docker-datanode2-1                                                                                                                               Started          0.8s
 ✔ Container docker-datanode1-1                                                                                                                               Started          0.8s
 ✔ Container docker-console1-1                                                                                                                                Started          0.8s
 ✔ Container docker-master3-1                                                                                                                                 Started          0.8s
 ✔ Container docker-lcnode1-1                                                                                                                                 Started          0.8s
 ✔ Container docker-objectnode2-1                                                                                                                             Started          0.8s
 ✔ Container docker-lcnode3-1                                                                                                                                 Started          0.8s
 ✔ Container docker-datanode4-1                                                                                                                               Started          0.8s
 ✔ Container docker-objectnode1-1                                                                                                                             Started          0.8s
 ✔ Container docker-master1-1                                                                                                                                 Started          0.8s
 ✔ Container docker-metanode3-1                                                                                                                               Started          0.8s
 ✔ Container docker-nginx-1                                                                                                                                   Started          0.8s
 ! console1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                     0.0s
 ! metanode3 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! lcnode2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ! datanode4 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! datanode2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! metanode1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! metanode4 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! metanode2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! objectnode2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                  0.0s
 ! objectnode1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                  0.0s
 ! master2 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ! lcnode3 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ! objectnode3 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                  0.0s
 ! master1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ! master3 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ! datanode1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! datanode3 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                    0.0s
 ! lcnode1 The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
 ✔ Container docker-servers-1                                                                                                                                 Started          0.0s
 ! servers The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested                      0.0s
ubuntu@myserver:~/cubefs_decoderleco$

```