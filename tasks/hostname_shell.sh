#!/usr/bin/env bash

# Error if non-root
if [ $(id -u) -ne 0 ]; then
  echo "puppet::hostname task must be run as root"
  exit 1
fi

# Get command line arguments
if [ -n "$PT_hostname" ]; then
    if [ -x /usr/bin/hostnamectl ]; then
        /usr/bin/hostnamectl set-hostname "$PT_hostname"
    fi
    echo "$PT_hostname" > /etc/hostname
fi
