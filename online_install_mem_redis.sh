#!/usr/bin/bash
#Date:2024/04/03
#Author:Noleaf

#color_print
red_start="\033[31m"
red_end="\033[0m"

blue_start="\033[36m"
blue_end="\033[0m"

green_start="\033[32m"
green_end="\033[0m"

yellow_start="\033[33m"
yellow_end="\033[0m"

#split_line
line="==========================================================================="
line2="--------------------------------------------------------------------------"
line3="+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

#package
memcached_version="memcached-1.6.26"
redis_version="redis-6.2.8"


color_meun() {
        echo  $line
        echo -e "$blue_start安装memcached请输入：1$blue_end"
        echo -e "$blue_start安装redis请输入：2$blue_end"
        echo -e "$blue_start安装memcached + redis请输入：3$blue_end"
        echo -e "$blue_start卸载memcached请输入：4$blue_end"
        echo -e "$blue_start卸载redis请输入：5$blue_end"
        echo -e "$blue_start退出请输入：6$blue_end"
        echo  $line
}

meun() {
        echo  "****************************************************"
        echo  "安装 memcached请输入：1"
        echo  "安装 redis请输入：2"
        echo  "安装 memcached + redis请输入：3"
        echo  "卸载 memcached请输入：4"
        echo  "卸载 redis请输入：5"
        echo  "退出请输入：6"
        echo  "****************************************************"
}

install_memcached() {
        echo -e "$green_start正在安装memcached$green_end"
        echo -e "$green_start***********************正在下载memcached安装包****************************$green_end"
        yum -y install libevent libevent-devel gcc* &> /dev/null
        if [ -e /root/${memcached_version}.tar.gz ] ;then
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包"
                wget https://www.memcached.org/files/${memcached_version}.tar.gz
        fi
        echo -e "$green_start***********************正在解压安装memcached*******************************$green_end"
        tar -xvf ${memcached_version}.tar.gz -C /usr/local/  &> /dev/null
        cd /usr/local/${memcached_version}/
        ./configure  &> /dev/null
        make &> /dev/null
        make install &> /dev/null
        echo -e "memcached的安装位置："
        ls /usr/local/bin/mem*
        echo -e "正在创建memcached用户..."
        useradd -r memcached -s /sbin/nologin
        cd
        echo -e "$green_start************************memcached已完成安装*******************************$green_end"
}


install_redis() {
        echo -e "$green_start********************正在安装redis*******************************$green_end"
        echo -e "redis在CentOS7安装需要高版本的GCC，正在下载高版本GCC"
#       yum -y install centos-release-scl  &> /dev/null
#       yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils  &> /dev/null
#       scl enable devtoolset-9 bash 
#       echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile

        if rpm -q centos-release-scl > /dev/null && \
           rpm -q devtoolset-9-gcc > /dev/null && \
           rpm -q devtoolset-9-gcc-c++ > /dev/null && \
           rpm -q devtoolset-9-binutils > /dev/null; then
           echo "已经安装了 centos-release-scl 和 devtoolset-9 工具链，无需重复安装。"
        else
           echo "开始安装 centos-release-scl 和 devtoolset-9 工具链..."
           yum -y install centos-release-scl &> /dev/null
           yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils &> /dev/null
           echo "安装完成。"
        fi



        if scl -l | grep -q devtoolset-9; then
           echo "devtoolset-9 环境已经启用。"
        else
         # 启用 devtoolset-9 环境
           echo "启用 devtoolset-9 环境..."
           scl enable devtoolset-9 bash
           echo "devtoolset-9 环境已经启用。"
        fi

        # 检查是否已经将 devtoolset-9 环境设置添加到 /etc/profile 文件中
        if grep -q "/opt/rh/devtoolset-9/enable" /etc/profile; then
           echo "已经将 devtoolset-9 环境设置添加到 /etc/profile 文件中。"
        else
           # 将 devtoolset-9 环境设置添加到 /etc/profile 文件中
           echo "将 devtoolset-9 环境设置添加到 /etc/profile 文件中..."
           echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile
           echo "已经将 devtoolset-9 环境设置添加到 /etc/profile 文件中。"
        fi


        echo -e "$green_start*******************正在下载redis安装包***************************$green_end"

        if [ -e /root/${redis_version}.tar.gz  ];then 
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包"

                wget https://download.redis.io/releases/${redis_version}.tar.gz
        fi
        if [  $? -eq 0 ];then

                echo -e "$green_start************************正在解压安装redis***********************************$green_end"
                tar -xvf ${redis_version}.tar.gz -C /usr/local/  &> /dev/null
                cd /usr/local/${redis_version}/
                echo -e "$green_start************************正在编译安装redis***********************************$green_end"
                make &> /dev/null
                make install &> /dev/null
                echo -e "创建/usr/redis目录并将redis-server和配置文件复制到/usr/redis下"
                mkdir -p /usr/redis/
                cp src/redis-server src/redis-cli redis.conf /usr/redis/
                echo vm.overcommit_memory=1 >> /etc/sysctl.conf
                sysctl -p
        else
                echo "$red_startredis安装包下载失败!$red_end"
                exit 1
        fi
        cd
        echo -e "$green_start***************************************redis已完成安装*********************************$green_end"

}

install_mem_redis() {
        echo -e "$green_start正在安装memcached和redis...$green_end"
}

remove_memcached() {
        echo -e "$red_start********************************正在卸载并删除memcached****************************$red_end"
        pkill memcached
        rm -rf /usr/local/${memcached_version}/
        echo "正在删除memcached用户"
        userdel memcached
        echo -e "$red_start**********************************memcached删除完成!**********************************$red_end"
}

remove_redis() {
        echo -e "$red_start*******************************正在卸载并删除redis**********************************$red_end"
        pkill redis
        rm -rf /usr/local/redis*
        rm -rf /usr/redis
        sed -i '/source \/opt\/rh\/devtoolset-9\/enable/d' /etc/profile
        sed -i '/vm.overcommit_memory=1/d' /etc/sysctl.conf
        echo -e "$red_start******************************redis删除完成!****************************************$red_end"
}

quit() {
        echo -e "$red_start退出脚本$red_end"
        exit 0
}

while true
do
#meun
color_meun
read -p "请输入您的选择： " choice

case $choice in 
   1)
        install_memcached
        ;;
   2)
        install_redis
        ;;
   3)
        install_mem_redis
        ;;
   4)
        remove_memcached
        ;;
   5)
        remove_redis
        ;;
   6)
        quit
        ;;
   *)
        echo -e "$red_start无效输入，请重新输入...$red_end"
        ;;
esac
done
