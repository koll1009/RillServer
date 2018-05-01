#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))
BUILD_DIR=$CUR_DIR/build

COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_RESET='\033[0m'

HOST='127.0.0.1'
USER='fgame'
WORK_DIR='fgame'

function usage(){
    echo -e "$COLOR_GREEN usage is : $0 [tar file] $COLOR_RESET"
    echo -e "$COLOR_GREEN需要指定需要安装的文件$COLOR_RESET"
    exit 2
}


if [ $# -lt 1 ]; then
    usage
fi

FILE_PATH=$1
FILE_NAME=$(basename $FILE_PATH)


if [ ! -f $FILE_PATH ]; then
    echo -e "$COLOR_GREEN $FILE is not a file $COLOR_RESET"
    exit 2
fi

TMP=${FILE_NAME%.*}
DIR_NAME=${TMP%.*}

. $CUR_DIR/config.sh
coloum=4
server_list_len=$((${#SERVER_LIST[@]}/$coloum))

# Choose a server for update
function choose_server() {
    printf "\n========================================\n"
    printf "             Server List\n"
    for ((i=0; i<$server_list_len; i=i+1)); do
        printf "%-10d %-20s %-20s  %-20s %-20s\n" $i ${SERVER_LIST[$(($i*$coloum))]} \
            ${SERVER_LIST[$(($i*$coloum+1))]} ${SERVER_LIST[$(($i*$coloum+2))]} ${SERVER_LIST[$(($i*$coloum+3))]} 
    done
    printf "========================================\n"
    printf "             Server List\n"

    read -p "Please Enter server index[0-$(($server_list_len -1))](others to exist): " server_index

    if [[ "$server_index" =~ ^[0-9]?$ && $server_index -ge 0 && $server_index -le $server_list_len ]]; then
        HOST="${SERVER_LIST[$(($server_index*$coloum))]}"
        USER="${SERVER_LIST[$(($server_index*$coloum+1))]}"
        WORK_DIR="${SERVER_LIST[$(($server_index*$coloum+2))]}"
    else
        echo -e "${COLOR_RED}invalidate input ${COLOR_RESET} : $COLOR_GREEN $server_index $COLOR_RESET";
        exit 4;
    fi
}


function insure(){
    echo -e "you will upload the file to ${COLOR_GREEN}\t$HOST\t$USER\t$WORK_DIR ${COLOR_RESET}\c"
    read -p " [Y/N]: " sure
    if [ "$sure" != "Y" ]; then
        echo "bye $sure"
        exit 4;
    fi
}

function upload(){
    scp $FILE_PATH $USER@$HOST:$WORK_DIR
    
    #先上传解压，然后用root用户安装依赖
    ssh $USER@$HOST "cd $WORK_DIR 
        tar xvf $FILE_NAME"

    #我们需要安装一些依赖库，所以先用root用户安装
    ssh root@$HOST "cd $WORK_DIR
        bash $WORK_DIR/$DIR_NAME/sudo.sh"

    #再执行安装步骤
    ssh $USER@$HOST "cd $WORK_DIR/$DIR_NAME
        bash install.sh $USER $USER"
}

while true; do
    choose_server

    insure

    upload
done

