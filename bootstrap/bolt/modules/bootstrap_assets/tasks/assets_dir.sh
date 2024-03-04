#!/usr/bin/env bash
# Set up bootstrap directory
#

if [ -n "$PT_path" ]; then
  path=$PT_path
else
  path="/root/bootstrap"
fi

# Error if non-root
if [ $(id -u) -ne 0 ]; then
  echo "bootstrap_assets::assets_dir task must be run as root"
  exit 1
fi

mkdir -p $path && chmod 700 $path

echo "{\"path\":\"$path\"}"

exit 0