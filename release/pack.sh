#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))
SRC_DIR=$CUR_DIR/..
DEST_DIR=$CUR_DIR/server
BUILD_DIR=$CUR_DIR/build

# Clear destination directory
if [ -d "$DEST_DIR" ]; then
  rm -rf $DEST_DIR
fi
mkdir -p $DEST_DIR

cd $SRC_DIR
make rpc

# Copy files
FILES=(\
  client      \
  common      \
  luaclib     \
  lualib      \
  lualib-src  \
  Makefile    \
  proto       \
  service     \
  web         \
  sh          \
)
for file in ${FILES[*]} ; do
  cp -r $SRC_DIR/$file $DEST_DIR
done

mkdir -p $DEST_DIR/data
cp $SRC_DIR/data/*.json $DEST_DIR/data

SKYNET_DIR=$SRC_DIR/skynet
SKYNET_DEST_DIR=$DEST_DIR/skynet
mkdir -p $SKYNET_DEST_DIR
SKYNET_FILES=(\
  cservice \
  luaclib  \
  lualib   \
  service  \
  skynet   \
)
for file in ${SKYNET_FILES[*]]} ; do
  cp -r $SKYNET_DIR/$file $SKYNET_DEST_DIR
done

#copy lua 5.3 version
mkdir -p $SKYNET_DEST_DIR/3rd/lua
cp $SKYNET_DIR/3rd/lua/lua $SKYNET_DEST_DIR/3rd/lua/lua

# Don't deploy setting file which is dependent on server.
rm -f $DEST_DIR/common/settings.lua
rm -f $DEST_DIR/common/clustername.lua
rm -f $DEST_DIR/sh/server_dependency.sh
rm -f $DEST_DIR/sh/debug*
rm -f $DEST_DIR/sh/*.pid

#包名 fgame+时间+包类型
DATE=$(date '+%Y-%m-%d_%H_%M_%S')

cd $DEST_DIR
if [ -d "$BUILD_DIR" ]; then
    rm -rf $BUILD_DIR/*
else
    mkdir -p $BUILD_DIR
fi

tar -czf $BUILD_DIR/hs_game-"$DATE".tar.gz *

rm -rf $DEST_DIR

