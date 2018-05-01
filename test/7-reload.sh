#!/usr/bin/expect
set timeout 20
set ip 127.0.0.1
set port 8701


spawn telnet $ip $port
expect "'^]'."
sleep .1

#game全部


#game某个模块
send "reload game game.example\r"
expect "<CMD OK>"


#全部配置
#send "resetup\r"
#expect "<CMD OK>"


#单个配置
send "resetup item\r"
expect "<CMD OK>"

exit

##reload wsagent agent.agent_room

