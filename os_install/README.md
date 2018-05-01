安装 mongo https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-centos-7
目前是 没有验证处理 见 mongod.cnf 中 authorization 选项
执行命令 /usr/local/mongodb/bin/mongod -f /etc/mongod.conf

登录具体流程在 RillServer\mod\login\login 中 forward.login(fd, msg, source)

安装 nodejs8.*
安装前请检查是否系统有自带的node
yum groupinstall 'Development Tools'
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs