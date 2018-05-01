#!/bin/bash
CUR_DIR=$(dirname $(readlink -f $0))
BUILD_DIR=$CUR_DIR/build

COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_RESET='\033[0m'

HOST='127.0.0.1'
USER='fgame'
WORK_DIR='fgame'
OPTION="$1"

case "$1" in
    copy|deploy)
        ;;
    *)
        echo -e "Usage: $0 {copy|deploy}"
        echo -e "\t${COLOR_GREEN}copy   - only upload the file with scp${COLOR_RESET}"
        echo -e "\t${COLOR_GREEN}deploy - upload the file and extract files then restart the program${COLOR_RESET}\n"
        exit 2
esac


# Choose a server for update
. $CUR_DIR/config.sh
server_list_len=$((${#SERVER_LIST[@]}/4))

function choose_server() {
    printf "\n========================================\n"
    printf "             Server List\n"
    for ((i=0; i<$server_list_len; i=i+1)); do
        printf "%-10d %-20s %-20s  %-20s %-20s\n" $i ${SERVER_LIST[$(($i*4))]} \
            ${SERVER_LIST[$(($i*4+1))]} ${SERVER_LIST[$(($i*4+2))]}  ${SERVER_LIST[$(($i*4+3))]}  
    done
    printf "========================================\n"
    printf "             Server List\n"

    read -p "Please Enter server index[0-$(($server_list_len -1))](others to exist): " server_index

    if [[ "$server_index" =~ ^[0-9]?$ && $server_index -ge 0 && $server_index -le $server_list_len ]]; then
        HOST="${SERVER_LIST[$(($server_index*4))]}"
        USER="${SERVER_LIST[$(($server_index*4+1))]}"
        WORK_DIR="${SERVER_LIST[$(($server_index*4+2))]}"
    else
        echo -e "${COLOR_RED}invalidate input ${COLOR_RESET} : $COLOR_GREEN $server_index $COLOR_RESET";
        exit 4;
    fi
}

function getArchive() {
    bash ${CUR_DIR}/pack.sh
    FILE=$(ls -1 $BUILD_DIR/*.tar.gz | head -n 1)
    printf "the upload file is : ${COLOR_GREEN} $FILE ${COLOR_RESET}\n"
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
    upload_dir="${WORK_DIR}upload"
    bak_dir="${WORK_DIR}bak"
    game_dir="${WORK_DIR}${GAME_NAME}"
    ssh $USER@$HOST "mkdir -p $upload_dir"
    scp $FILE $USER@$HOST:${upload_dir}
    if [ "$OPTION" != "copy" ]; then
        ssh $USER@$HOST "cd $WORK_DIR;
        mkdir -p $bak_dir;
        mkdir -p $game_dir;
        tar cvf $bak_dir/$GAME_NAME-$(date '+%Y-%m-%d_%H_%M_%S').tar.gz ./$GAME_NAME --exclude=log/* --exclude=business/* --exclude=busilog/*;
        tar xvf $upload_dir/$(basename $FILE) -C ${game_dir};
        cd $game_dir;
        bash sh/template.sh $HOST;
        bash sh/restart.sh"
    fi
}

getArchive

while true; do
    choose_server

    insure

    upload

done
