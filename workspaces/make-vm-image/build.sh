#!/bin/sh

# https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

IMAGE=https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2

BASE=images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2
BOOT=images/Fedora-Cloud-Customized.qcow2

if [ ! -f "$BASE" ]; then
  mkdir -p images
  curl -L "$IMAGE" -o $BASE 
fi

if [ ! -f "$BOOT" ]; then
  cp $BASE $BOOT
  qemu-img resize $BOOT 20G
fi

# If we wanted to use an overlay
# qemu-img create -f qcow2 -F qcow2 -b $(basename $BASE) $BOOT 20G

# cidata cvo
# try ISO
# (cd nocloud; genisoimage -input-charset utf-8 -output ../$NOCLOUD -volid cidata -joliet -rock user-data meta-data network-config;)

# try vfat
# truncate --size 2M $NOCLOUD
# mkfs.vfat -n CIDATA $NOCLOUD
# mcopy -oi $NOCLOUD nocloud/user-data nocloud/meta-data ::

# the cidata volume isn't mounted because of a bug in alpine's
# default mount command. See:
# https://gitlab.kveer.fr/upstream/alpine-aports/-/blob/v3.15.0/community/cloud-init/README.Alpine

# start metadata server
python3 -m http.server --directory nocloud &
serverPID=$!

qemu-system-x86_64 -m 1024 -net nic -net user -nographic \
  -drive file=$BOOT,if=virtio \
  -smbios type=1,serial=ds='nocloud;s=http://
  
  :8000/' \
  -machine accel=kvm:tcg

# stop metadata server
kill $serverPID

