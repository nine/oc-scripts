#!/bin/bash

# exit on error 
set -e

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-hv] -c FILE -u URL 
Update owncloud installations

    -h        display this help and exit
    -c FILE   path to config-file containing the paths of the
              particular installations
    -u URL    url of update package, e.g.
    	      https://download.owncloud.org/community/owncloud-7.0.2.tar.bz2
    -v        verbose mode. Can be used multiple times for increased
              verbosity.
EOF
}

config="/etc/owncloud/installs.list"
url=""

OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hvcu:" opt; do
  case "$opt" in
    h)
        show_help
        exit 0
        ;;
    v)  verbose=$((verbose+1))
        ;;
    c)  config=$OPTARG
        ;;
    u)  url=$OPTARG
        ;;
    '?')
        show_help >&2
        exit 1
        ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

echo "download owncloud package"
wget -O /tmp/owncloud-latest.tar.bz2 $url 
echo "unpack archive"
if [ -d /tmp/owncloud_latest ]; then
	rm -rf /tmp/owncloud_latest
fi
mkdir /tmp/owncloud_latest 
tar -C /tmp/owncloud_latest -xjf /tmp/owncloud-latest.tar.bz2

while read path           
do
	echo "entering: $path"
	echo "backup old install"
	rsync -a $path/htdocs $path/htdocs_bkp`date +"%Y%m%d"`/
	echo "syncing files"
	rsync --inplace -rtv /tmp/owncloud_latest/owncloud/ $path/htdocs/
	find $path -maxdepth 1 -type d -name "htdocs_bkp*" -printf '%T@ %p\0' | sort -r -z -n | awk 'BEGIN { RS="\0"; ORS="\0"; FS="" } NR > 3 { sub("^[0-9]*(.[0-9]*)? ", ""); print }' | xargs -0 rm -rf
done < $config 

echo "cleanup"
rm -rf /tmp/owncloud-latest.tar.bz2 /tmp/owncloud_latest/

#eof
