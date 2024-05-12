#!/bin/bash

# ---- if minio needed

# sudo docker run -d \
#    -p 0.0.0.0:9000:9000 \
#    -p 0.0.0.0:9001:9001 \
#    --name minio \
#    -v ~/minio/data:/data \
#    -e "MINIO_ROOT_USER=ROOTNAME" \
#    -e "MINIO_ROOT_PASSWORD=CHANGEME123" \
#    quay.io/minio/minio server /data --console-address ":9001"

# 0./ connect the minio to the KIND cluster docker network :

export minio_container_name="minio"
docker network connect "kind" "${minio_container_name}"




sudo mkdir -p /juicefs_data/disk
sudo chown $USER: -R /juicefs_data

mkdir -p ~/.bin/juicefs/

# install to /juicefs_data/disk directory
curl -sSL https://d.juicefs.com/install | sh -s ~/.bin/juicefs/

export PATH="$PATH:/home/ubuntu/.bin/juicefs/juicefs"
# alias juicefs=~/.bin/juicefs/juicefs
alias juicefs=/home/ubuntu/.bin/juicefs/juicefs

juicefs --version


# Replace relevant options with the actual object storage being used
export MINIO_ACCESS_KEY="f3LZ9oci8OkyVc6eHmyw"
export MINIO_SECRET_KEY="ay8oI3CHTjGRtw1t1ytVlfa4XkJs0VaNwRo5d2VW"

juicefs format --storage s3 \
    --bucket http://127.0.0.1:9000/juicefs \
    --access-key ${MINIO_ACCESS_KEY} \
    --secret-key ${MINIO_SECRET_KEY} \
    sqlite3://myjfs.db myjfs

# ubuntu@myserver:~/juicefs_decoderleco$ export MINIO_ACCESS_KEY="f3LZ9oci8OkyVc6eHmyw"
# export MINIO_SECRET_KEY="ay8oI3CHTjGRtw1t1ytVlfa4XkJs0VaNwRo5d2VW"

# juicefs format --storage s3 \
#     --bucket http://127.0.0.1:9000/juicefs \
#     --access-key ${MINIO_ACCESS_KEY} \
#     --secret-key ${MINIO_SECRET_KEY} \
#     sqlite3://myjfs.db myjfs
# 2024/05/12 17:31:37.965362 juicefs[140600] <INFO>: Meta address: sqlite3://myjfs.db [interface.go:497]
# 2024/05/12 17:31:37.966078 juicefs[140600] <INFO>: Data use s3://juicefs/myjfs/ [format.go:471]
# 2024/05/12 17:31:38.085412 juicefs[140600] <INFO>: Volume is formatted as {
#   "Name": "myjfs",
#   "UUID": "59d23106-e1d3-4e13-a3e4-0286e54ea7f8",
#   "Storage": "s3",
#   "Bucket": "http://127.0.0.1:9000/juicefs",
#   "AccessKey": "f3LZ9oci8OkyVc6eHmyw",
#   "SecretKey": "removed",
#   "BlockSize": 4096,
#   "Compression": "none",
#   "EncryptAlgo": "aes256gcm-rsa",
#   "KeyEncrypted": true,
#   "TrashDays": 1,
#   "MetaVersion": 1,
#   "MinClientVersion": "1.1.0-A",
#   "DirStats": true
# } [format.go:508]
# ubuntu@myserver:~/juicefs_decoderleco$

# ---
# this last one will stay interactively hanging: unless i use the [-d] option
# Still it is useful to run interactively without the [-d] option: to see in the logs, that the kubernetes csi connection is happening well!
# sudo -u ubuntu /home/ubuntu/.bin/juicefs/juicefs mount sqlite3://myjfs.db /juicefs_data/disk

# sudo /home/ubuntu/.bin/juicefs/juicefs mount sqlite3://myjfs.db /juicefs_data/disk -d --force
# the [--force] option forces mounting on already mounted folder [/juicefs_data/disk]: I think it forces unmounting the previous mount etc but well all this works awesome!
sudo /home/ubuntu/.bin/juicefs/juicefs mount sqlite3://myjfs.db /juicefs_data/disk -d
