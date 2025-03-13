#!/bin/bash

set -e


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
line4="*******************************"

mysql57_version="mysql-5.7.39-linux-glibc2.12-x86_64"
mysql8_version="mysql-8.0.30-linux-glibc2.12-x86_64"

color_meun() {
        echo -e "${blue_start}${line}
\t\tInstallation Options
\t安装mysql5.7请输入：1
\t卸载mysql5.7请输入：2
\t安装mysql8请输入：3
\t卸载mysql8请输入：4
\t退出请输入：quit
${line}${blue_end}"
}




install_mysql57() {
        echo -e "${line4}正在安装MySQL5.7${line4}"
        echo -e "正在下载MySQL5.7..."
        if [ -e ${mysql57_version}.tar.gz  ];then
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包..."
                wget --tries=3 https://downloads.mysql.com/archives/get/p/23/file/${mysql57_version}.tar.gz || {
                        echo "下载失败，脚本终止"
                        exit 1
                }
        fi

        echo -e "${line4}正在下载安装依赖${line4}"
        yum -y install libaio &> /dev/null
        yum install -y ncurses-compat-libs &> /dev/null
        
        echo -e "${line4}正在解压安装${line4}"
        tar -xvf ${mysql57_version}.tar.gz -C /usr/local &> /dev/null 
        cd /usr/local
        mv ${mysql57_version}  mysql5.7

        echo -e "${line4}正在创建MySQL用户及组${line4}"
        #检查mysql组是否存在
        if ! grep -q "^mysql:" /etc/group; then
                echo "mysql用户组不存在，正在创建..."
                groupadd mysql
        else
                echo "mysql用户组已存在。"
        fi

        # 检查mysql用户是否存在
        if ! id "mysql" &>/dev/null; then
                echo "mysql用户不存在，正在创建..."
                useradd -r -g mysql   mysql
        else
                echo "mysql用户已存在。"
        fi

        echo -e "${line4}创建数据及日志目录${line4}"
        if [ ! -d /var/log/mysql  ];then
                mkdir /var/log/mysql
        fi
        if [ ! -d /var/lib/mysql ];then
                mkdir /var/lib/mysql
        fi
        if [ ! -d /var/run/mysql ];then
                mkdir /var/run/mysql
        fi

        chown -R mysql:mysql /var/lib/mysql /var/run/mysql /var/log/mysql &> /dev/null

        echo -e "${line4}创建MySQL配置文件${line4}"
        cat > /etc/my.cnf<<EOF
[client]
# 默认连接 MySQL 时使用的字符集
default-character-set = utf8mb4
socket=/var/lib/mysql/mysql.sock

[mysqld]
user=mysql
socket=/var/lib/mysql/mysql.sock
port=3306
pid-file=/var/lib/mysql/mysql.pid
basedir=/usr/local/mysql5.7
datadir=/var/lib/mysql

lower_case_table_names = 1
explicit_defaults_for_timestamp = 1

#日志配置
log-error = /var/log/mysql/error.log
slow-query-log = 1
slow-query-log-file = /var/log/mysql/mysql-slow.log
long_query_time = 2

# 字符集设置及排序规则
character-set-server = utf8mb4
EOF
        echo -e "${line4}配置MySQL环境变量${line4}"
        if ! grep -q 'export PATH=\$PATH:/usr/local/mysql5.7/bin' /etc/profile; then
                echo 'export PATH=$PATH:/usr/local/mysql5.7/bin' >> /etc/profile
        fi
        source /etc/profile

        echo -e "${line4}正在初始化MySQL${line4}"
        /usr/local/mysql5.7/bin/mysqld  --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql  &> /dev/null
        if [ $? -eq 0 ] ;then
                echo -e "${line4}正在创建systemctl管理服务${line4}"
                cat > /usr/lib/systemd/system/mysql.service << EOF
[Unit]
Description=mysql
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/usr/local/mysql5.7/support-files/mysql.server start
ExecReload=/usr/local/mysql5.7/support-files/mysql.server restart
ExecStop=/usr/local/mysql5.7/support-files/mysql.server stop
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

                echo -e "${line4}正在启动MySQL并添加密码${line4}"
                systemctl daemon-reload  &&     systemctl enable --now mysql
                mysql -S /var/lib/mysql/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '1qaz!QAZ';
FLUSH PRIVILEGES;
EOF

                echo ""
                echo -e "${green_start}MySQL初始密码已修改为：1qaz!QAZ${green_end}"
                echo ""
                ln -s /var/lib/mysql/mysql.sock   /tmp/mysql.sock &> /dev/null
                        echo -e "\033[35m
=============================================
=          mysql用法：                      =
=  安装位置：/usr/local                     =
=  启动mysql：systemctl start  mysql        =
=  停止mysql：systemctl stop  mysql         =
=  开机自启mysql：systemctl enable mysql    =
=                                           =
=============================================\033[0m"


        else
                echo "MySQL初始化失败..."
                exit 1
        fi

}


remove_mysql57() {
        echo -e "${red_start}${line4}正在卸载mysql5.7${line4}${red_end}"
        echo -e "${line4}正在删除mysql数据目录及配置文件${line4}"
        systemctl stop mysql
        sed -i '/export PATH=\$PATH:\/usr\/local\/mysql5.7\/bin/d' /etc/profile
        rm -rf  /var/log/mysql /var/lib/mysql /var/run/mysql /usr/local/mysql5.7* &> /dev/null
        rm -rf /usr/lib/systemd/system/mysql.service
        echo ""
        echo -e "${red_start}${line4}MySQL5.7已完成卸载${line4}${red_end}"
        echo ""

}


install_mysql8() {
        echo -e "${line4}正在安装MySQL8${line4}"
        echo -e "正在下载MySQL8..."
        if [ -e ${mysql8_version}.tar.xz  ];then
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包..."
                wget https://downloads.mysql.com/archives/get/p/23/file/${mysql8_version}.tar.xz
        fi

        echo -e "${line4}正在下载安装依赖${line4}"
        yum -y install libaio &> /dev/null
        yum install -y ncurses-compat-libs &> /dev/null
        
        echo -e "${line4}正在解压安装${line4}"
        tar -xvf ${mysql8_version}.tar.xz -C /usr/local &> /dev/null 
        cd /usr/local
        mv ${mysql8_version}  mysql

        echo -e "${line4}正在创建MySQL用户及组${line4}"
        #检查mysql组是否存在
        if ! grep -q "^mysql:" /etc/group; then
                echo "mysql用户组不存在，正在创建..."
                groupadd mysql
        else
                echo "mysql用户组已存在。"
        fi

        # 检查mysql用户是否存在
        if ! id "mysql" &>/dev/null; then
                echo "mysql用户不存在，正在创建..."
                useradd -r -g mysql   mysql
        else
                echo "mysql用户已存在。"
        fi

        echo -e "${line4}创建数据及日志目录${line4}"
        if [ ! -d /var/log/mysql  ];then
                mkdir /var/log/mysql
        fi
        if [ ! -d /var/lib/mysql ];then
                mkdir /var/lib/mysql
        fi
        if [ ! -d /var/run/mysql ];then
                mkdir /var/run/mysql
        fi

        chown -R mysql:mysql /var/lib/mysql /var/run/mysql /var/log/mysql &> /dev/null

        echo -e "${line4}创建MySQL配置文件${line4}"
        cat > /etc/my.cnf<<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
user=mysql
port=3306
lower_case_table_names = 1
[mysqld_safe]
pid-file=/var/run/mysql/mysql.pid
#slowlog
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 2
log_queries_not_using_indexes = 1
#errorlog
log_error = /var/log/mysql/error.log
EOF
        echo -e "${line4}配置MySQL环境变量${line4}"
        if ! grep -q 'export PATH=\$PATH:/usr/local/mysql/bin' /etc/profile; then
                echo 'export PATH=$PATH:/usr/local/mysql/bin' >> /etc/profile
        fi
        source /etc/profile

        echo -e "${line4}正在初始化MySQL${line4}"
        /usr/local/mysql/bin/mysqld  --defaults-file=/etc/my.cnf --initialize-insecure --user=mysql  &> /dev/null
        if [ $? -eq 0 ] ;then
                echo -e "${line4}正在创建systemctl管理服务${line4}"
                cat > /usr/lib/systemd/system/mysql.service << EOF
[Unit]
Description=mysql
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/usr/local/mysql/support-files/mysql.server start
ExecReload=/usr/local/mysql/support-files/mysql.server restart
ExecStop=/usr/local/mysql/support-files/mysql.server stop
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

                echo -e "${line4}正在启动MySQL并添加密码${line4}"
                systemctl daemon-reload  &&     systemctl enable --now mysql
                mysql -S /var/lib/mysql/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '1qaz!QAZ';
FLUSH PRIVILEGES;
EOF

                echo ""
                echo -e "${green_start}MySQL初始密码已修改为：1qaz!QAZ${green_end}"
                echo ""
                ln -s /var/lib/mysql/mysql.sock   /tmp/mysql.sock &> /dev/null
                        echo -e "\033[35m
=============================================
=          mysql用法：                      =
=  安装位置：/usr/local                     =
=  启动mysql：systemctl start  mysql        =
=  停止mysql：systemctl stop  mysql         =
=  开机自启mysql：systemctl enable mysql    =
=                                           =
=============================================\033[0m"


        else
                echo "MySQL初始化失败..."
                exit 1
        fi

}


remove_mysql8() {
        echo -e "${red_start}${line4}正在卸载mysql8${line4}${red_end}"
        echo -e "${line4}正在删除mysql数据目录及配置文件${line4}"
        systemctl stop mysql
        sed -i '/export PATH=\$PATH:\/usr\/local\/mysql\/bin/d' /etc/profile
        rm -rf  /var/log/mysql /var/lib/mysql /var/run/mysql /usr/local/mysql* &> /dev/null
        rm -rf /usr/lib/systemd/system/mysql.service
        echo ""
        echo -e "${red_start}${line4}MySQL8已完成卸载${line4}${red_end}"
        echo ""


}

quit() {
        echo -e "${red_start}退出脚本${red_end}"
        exit 0
}



while true
do
#meun
color_meun
read -p "请输入您的选择： " choice

case $choice in
   1)
        install_mysql57
        ;;
   2)
        remove_mysql57
        ;;
   3)
        install_mysql8
        ;;
   4)
        remove_mysql8
        ;;
   quit)
        quit
        ;;
   *)
        echo -e "${red_start}无效输入，请重新输入...${red_end}"
        ;;
esac
done
