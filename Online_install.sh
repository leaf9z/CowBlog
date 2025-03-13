#!/usr/bin/bash
#Date:2024/04/03
#Author:SunPengyan

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
line4="*******************************"

#package
memcached_version="memcached-1.6.26"
redis_version="redis-6.2.8"
nginx_version="nginx-1.24.0"
mysql_version="mysql-8.0.30-linux-glibc2.12-x86_64"


color_meun() {
        echo -e "${blue_start}${line}
\t\tInstallation Options
\t安装memcached请输入：1
\t卸载memcached请输入：2
\t安装redis请输入：3
\t卸载redis请输入：4
\t安装nginx请输入：5
\t卸载nginx请输入：6
\t安装mysql8请输入：7
\t卸载mysql8请输入：8
\t安装全部请输入：all
\t卸载全部请输入：del
\t退出请输入：quit
${line}${blue_end}"
}

meun() {
	echo  "****************************************************"
	echo  "安装 memcached请输入：1"
	echo  "安装 redis请输入：2"
	echo  "安装 memcached + redis请输入：3"
	echo  "卸载 memcached请输入：4"
	echo  "卸载 redis请输入：5"
	echo  "退出请输入：quit"
	echo  "****************************************************"
}

install_memcached() {
	echo -e "${green_start}正在安装memcached${green_end}"
	echo -e "${green_start}${line4}正在下载memcached安装包${line4}${green_end}"
	yum -y install libevent libevent-devel gcc* &> /dev/null
	if [ -e ${memcached_version}.tar.gz ] ;then
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包"
	        wget https://www.memcached.org/files/${memcached_version}.tar.gz
	fi
	echo -e "${green_start}${line4}正在解压安装memcached${line4}${green_end}"
	tar -xvf ${memcached_version}.tar.gz -C /usr/local/  &> /dev/null
	cd /usr/local/${memcached_version}/
	./configure  &> /dev/null
	make &> /dev/null
	make install &> /dev/null
	echo -e "memcached的安装位置："
	ls /usr/local/bin/mem*
	echo -e "正在创建memcached用户..."
        # 检查memcached用户是否存在
        if ! id "memcached" &>/dev/null; then
                echo "memcached用户不存在，正在创建..."
		useradd -r memcached -s /sbin/nologin
        else
                echo "memcached用户已存在。"
        fi
	cd
	echo -e "${green_start}${line4}memcached已完成安装${line4}${green_end}"
        echo -e "\033[35m
==============================================================================================
||          memcached用法：                                                                  ||
||  安装位置：/usr/local                                                                     ||
||  启动memcached：memcached -d -m 1024 -u memcached -U 0 -l 本机ip -p 11211 -c 4096 -t 64   ||
==============================================================================================\033[0m"
}

remove_memcached() {
        echo -e "${red_start}${line4}正在卸载并删除memcached${line4}${red_end}"
        pkill memcached
        rm -rf /usr/local/${memcached_version}/
        echo "正在删除memcached用户"
        userdel memcached
        echo -e "${red_start}${line4}memcached删除完成!${line4}${red_end}"
}

install_redis() {
	echo -e "${green_start}${line4}正在安装redis${line4}${green_end}"	
	echo -e "redis在CentOS7安装需要高版本的GCC，正在下载高版本GCC"
#	yum -y install centos-release-scl  &> /dev/null
#	yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils  &> /dev/null
#	scl enable devtoolset-9 bash 
#	echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile

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

	
	echo -e "${green_start}${line4}正在下载redis安装包${line4}${green_end}"

	if [ -e ${redis_version}.tar.gz  ];then 
		echo "安装包已存在，跳过下载"
	else
		echo "开始下载安装包"
	
	        wget https://download.redis.io/releases/${redis_version}.tar.gz
	fi
	if [  $? -eq 0 ];then
		
		echo -e "${green_start}${line4}正在解压安装redis${line4}${green_end}"
		tar -xvf ${redis_version}.tar.gz -C /usr/local/  &> /dev/null
		cd /usr/local/${redis_version}/
		echo -e "${green_start}${line4}正在编译安装redis${line4}${green_end}"
		make &> /dev/null
		make install &> /dev/null
		echo -e "创建/usr/redis目录并将redis-server和配置文件复制到/usr/redis下"
		mkdir -p /usr/redis/
		cp src/redis-server src/redis-cli redis.conf /usr/redis/
		echo vm.overcommit_memory=1 >> /etc/sysctl.conf
		sysctl -p
		sed -i 's/^daemonize\s*no/daemonize yes/' /usr/redis/redis.conf
	else
		echo "$red_startredis安装包下载失败!$red_end"
		exit 1
	fi
	cd	
	echo -e "${line4}正在创建systemctl管理服务${line4}"
	cat > /usr/lib/systemd/system/redis.server << EOF
[Unit]
Description=Redis persistent key-value database
After=network.target

[Service]
Type=simple
ExecStart=/usr/redis/redis-server /usr/redis/redis.conf
ExecStop=/usr/redis/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF

	
	echo -e "${green_start}${line4}redis已完成安装${line4}${green_end}"	
	echo -e "\033[35m
=============================================
=          redis用法：                      =
=  安装位置：/usr/redis                     =
=  启动redis：systemctl start redis         =
=  关闭redis：systemctl stop redis          =
=  开机自启redis：systemctl enable redis    =
=                                           =
=============================================\033[0m"


}

remove_redis() {
        echo -e "${red_start}${line4}正在卸载并删除redis${line4}${red_end}"
        pkill redis
        rm -rf /usr/local/redis*
        rm -rf /usr/redis
        sed -i '/source \/opt\/rh\/devtoolset-9\/enable/d' /etc/profile
        sed -i '/vm.overcommit_memory=1/d' /etc/sysctl.conf
        echo -e "${red_start}${line4}redis删除完成!${line4}${red_end}"
}



install_nginx() {
	echo -e "${line4}正在下载nginx安装包${line4}"
        if [ -e ${nginx_version}.tar.gz ] ;then
                echo "安装包已存在，跳过下载"
        else
                echo "开始下载安装包"
               	wget https://nginx.org/download/${nginx_version}.tar.gz 
        fi
	echo -e "${line4}正在下载依赖${line4}"
	yum -y install gcc make pcre pcre-devel openssl openssl-devel zlib zlib-devel GeoIP-devel.x86_64  gd gd-devel.x86_64 &> /dev/null

	echo -e "正在创建nginx用户及组"
	# 检查nginx组是否存在
	if ! grep -q "^nginx:" /etc/group; then
   		echo "nginx用户组不存在，正在创建..."
    		groupadd nginx
	else
        	echo "nginx用户组已存在。"
	fi

	# 检查nginx用户是否存在
	if ! id "nginx" &>/dev/null; then
        	echo "nginx用户不存在，正在创建..."
    		useradd -r -g nginx -s /sbin/nologin  nginx
	else
        	echo "nginx用户已存在。"
	fi

	tar -xvf ${nginx_version}.tar.gz -C /usr/local  &> /dev/null
	cd /usr/local/${nginx_version}
	echo -e "${line4}正在编译安装nginx${line4}"
	./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-threads --with-stream --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module  &> /dev/null
	make &> /dev/null 
	make install &> /dev/null
	echo -e "nginx的版本为："
	echo -e "${green_start}$(/usr/local/nginx/sbin/nginx -v)${green_end}"
	cd
	echo -e "${line4}正在创建systemctl管理服务${line4}"
	cat > /usr/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=nginx service
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
	echo -e "\033[35m
=============================================
=          nginx用法：                      =
=  安装位置：/usr/local                     =
=  启动nginx：systemctl start  nginx        =
=  停止nginx：systemctl stop  nginx         =
=  开机自启nginx：systemctl enable nginx    =
=                                           =
=============================================\033[0m"
	
}	

remove_nginx() {
	echo -e "${red_start}${line4}正在卸载nginx${line4}${red_end}"
	pkill nginx
	echo -e "正在删除nginx用户及组"
	userdel -r nginx &> /dev/null
	groupdel nginx   &> /dev/null
	echo -e "正在删除nginx相关目录..."
	rm -rf /usr/local/nginx*
	rm -rf /usr/lib/systemd/system/nginx.service
	echo -e "${red_start}${line4}nginx已卸载完成!${line4}${red_end}"

}




install_mysql8() {
	echo -e "${line4}正在安装MySQL8${line4}"
	echo -e "正在下载MySQL8..."
	if [ -e ${mysql_version}.tar.xz  ];then
		echo "安装包已存在，跳过下载"
	else
		echo "开始下载安装包..."
		wget https://downloads.mysql.com/archives/get/p/23/file/${mysql_version}.tar.xz
	fi
	
	echo -e "${line4}正在下载安装依赖${line4}"
	yum -y install libaio &> /dev/null
	yum install -y ncurses-compat-libs &> /dev/null
	echo -e "${line4}正在解压安装${line4}"
	tar -xvf ${mysql_version}.tar.xz -C /usr/local &> /dev/null 
	cd /usr/local
	mv ${mysql_version}  mysql
	
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
basedir=/usr/local/mysql
datadir=/var/lib/mysql

lower_case_table_names = 1
explicit_defaults_for_timestamp = 1

#日志配置
log-error = /var/log/mysql/error.log
slow-query-log = 1
slow-query-log-file = /var/log/mysql/mysql-slow.log
long_query_time = 2
binlog_expire_logs_seconds = 604800

# 字符集设置及排序规则
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
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
		systemctl daemon-reload  &&	systemctl enable --now mysql
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
	echo -e "${red_start}${line4}MySQL8已完成卸载${line4}${red_end}"	


}


install_all() {
	echo -e "${yellow_start}${line4}安装全部软件${line4}${yellow_end}"
	install_memcached
	install_redis
	install_nginx
	install_mysql8

}

remove_all() {
	echo -e "${red_start}${line4}卸载全部软件${line4}${red_end}"
	remove_memcached
	remove_redis
	remove_nginx
	remove_mysql8	

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
	install_memcached
	;;
   2)
	remove_memcached
	;;
   3)
	install_redis
	;;
   4)   
	remove_redis
	;;
   5)
	install_nginx
	;;
   6)
	remove_nginx
	;;
   7)
	install_mysql8
	;;
   8)
	remove_mysql8
	;;
   all)
	install_all
	;;
   del)
	remove_all
	;;
   quit)
	quit
	;;
   *)
	echo -e "${red_start}无效输入，请重新输入...${red_end}"	
	;;
esac
done

