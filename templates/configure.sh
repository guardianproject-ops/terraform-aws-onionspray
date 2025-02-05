#!/usr/bin/env bash

set -e

aws s3 cp s3://${bucket_name}/configuration.zip /root/configuration.zip

cd /root
unzip configuration.zip
mv sites.conf /home/ubuntu/onionspray/
chown ubuntu:ubuntu /home/ubuntu/onionspray/sites.conf
mkdir -p /home/ubuntu/onionspray/secrets
mv *.key /home/ubuntu/onionspray/secrets/
chown ubuntu:ubuntu -R /home/ubuntu/onionspray/secrets
chmod 640 /home/ubuntu/onionspray/secrets/*.v3pub.key
chmod 600 /home/ubuntu/onionspray/secrets/*.v3sec.key
cd /home/ubuntu/onionspray
sudo -u ubuntu ./onionspray configure sites.conf
mv /root/*.cert /root/*.pem /home/ubuntu/onionspray/projects/sites/ssl/
chown ubuntu:ubuntu -R /home/ubuntu/onionspray/projects/sites/ssl
chmod 640 /home/ubuntu/onionspray/projects/sites/ssl/*-v3.cert
chmod 600 /home/ubuntu/onionspray/projects/sites/ssl/*-v3.pem
sudo -u ubuntu ./onionspray bounce sites
