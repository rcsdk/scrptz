#!/bin/bash

# Check if the file is immutable
if lsattr /etc/resolv.conf | grep -q "i"; then
    echo "File is immutable. Removing immutable flag..."
    chattr -i /etc/resolv.conf
fi

# Check if the filesystem is read-only
if mount | grep -w "/" | grep -q "ro"; then
    echo "Filesystem is read-only. Remounting as read-write..."
    mount -o remount,rw /
fi

# Define the new DNS servers
DNS_SERVERS="nameserver 8.8.8.8\nnameserver 8.8.4.4"

# Overwrite /etc/resolv.conf with the new DNS servers
echo -e "$DNS_SERVERS" > /etc/resolv.conf

# Make the file immutable to prevent further changes
chattr +i /etc/resolv.conf

# Verify the changes
echo "DNS settings have been updated and locked:"
cat /etc/resolv.conf
echo "File is now immutable."
