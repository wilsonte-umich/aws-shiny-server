#!/bin/bash

#---------------------------------------------------------------
# Prepare an EC2 instance for saving as a public AWS AMI.
# see: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/building-shared-amis.html
# run this script, then immediately create an AMI from the instance
#---------------------------------------------------------------

sudo sed -i \
  -e '/PermitRootLogin/s/.*/#/' \
  -e '$a\\nPermitRootLogin without-password\n' /etc/ssh/sshd_config 
sudo passwd -l root 
sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub 
sudo shred -u ~/.ssh/authorized_keys 
rm -rf ~/.vscode-server 
shred -u ~/.*history 
