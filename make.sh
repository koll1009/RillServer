#!/bin/sh

dir=$(cd `dirname $0`; pwd)
echo $dir
echo $1

if [ ! $1 ]; then  
       cmd='help' 
else
		cmd=$1
fi  

if [ $cmd = "all" ];then
	echo -e "\n make skynet"
    cd $dir/skynet && pwd
	make linux 
	
	echo -e "\n make luaclib"
	cd $dir/lualib-src  && pwd
	make linux
	
	echo -e "\n make LuaPbIntf"
	cd $dir/lualib-src/LuaPbIntf/build && pwd
	make config=release 
	\cp -f bin/Release/luapbintf.so ../../../luaclib/
	
elif [ $cmd = "clean" ];then
	echo -e "\n clean skynet"
	cd $dir/skynet && pwd
	make clean
	
	echo -e "\n clean luaclib"
	cd $dir/lualib-src && pwd
	make clean
	
	echo -e "\n clean LuaPbIntf"
	cd $dir/lualib-src/LuaPbIntf/build && pwd
	make clean config=release
else
	echo "make help"
	echo "make.sh all"
	echo "make.sh clean"
fi



