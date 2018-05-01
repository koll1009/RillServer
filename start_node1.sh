#!/bin/sh

export ROOT=$(cd `dirname $0`; pwd)
export SKYNET_ROOT=$ROOT/skynet
export DAEMON=false

## echo $ROOT
 echo $SKYNET_ROOT
while getopts "Dk" arg
do
	case $arg in
		D)
			export DAEMON=true
			;;
		k)
			kill `cat $ROOT/run/skynet.pid`
			exit 0;
			;;
	esac
done

$SKYNET_ROOT/skynet $ROOT/etc/config_node1

