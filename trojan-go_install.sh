#!/bin/bash
#=================================================
#	System Required: :Debian 9+/Ubuntu 18.04+/Centos 7+
#	Description: Trojan&V2ray&SSR script
#	Version: 1.0.0
#	Author: Jeannie
#	Blog: https://jeanniestudio.top/
# Official document: www.v2ray.com
#=================================================
sh_ver="1.0.0"
#fonts color
RED="\033[0;31m"
NO_COLOR="\033[0m"
GREEN="\033[32m\033[01m"
FUCHSIA="\033[0;35m"
YELLOW="\033[33m"
BLUE="\033[0;36m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[��Ϣ]${Font_color_suffix}"
Error="${Red_font_prefix}[����]${Font_color_suffix}"
Tip="${Green_font_prefix}[ע��]${Font_color_suffix}"
trojan_dir=/etc/trojan
trojan_bin_dir=${trojan_dir}/bin
trojan_conf_dir=${trojan_dir}/conf
trojan_conf_file=${trojan_conf_dir}/server.json
trojan_qr_config_file=${trojan_conf_dir}/qrconfig.json
trojan_systemd_file="/etc/systemd/system/trojan.service"
web_dir="/usr/wwwroot"
nginx_bin_file="/etc/nginx/sbin/nginx"
nginx_conf_dir="/etc/nginx/conf/conf.d"
nginx_conf="${nginx_conf_dir}/default.conf"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"
nginx_systemd_file="/etc/systemd/system/nginx.service"
caddy_bin_dir="/usr/local/bin"
caddy_conf_dir="/etc/caddy"
caddy_conf="${caddy_conf_dir}/Caddyfile"
caddy_systemd_file="/etc/systemd/system/caddy.service"
nginx_version="1.18.0"
openssl_version="1.1.1g"
jemalloc_version="5.2.1"
old_config_status="off"
check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} ${RedBG} ��ǰ��ROOT�˺�(��û��ROOTȨ��)���޷�������������ִ������ ${Green_background_prefix}sudo -i${Font_color_suffix} ����ROOT�˺�" && exit 1
}
set_SELINUX() {
  if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
  fi
}
check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=`uname -m`
}
sys_cmd(){
  if [[ ${release} == "centos" ]]; then
    cmd="yum"
  else
    cmd="apt"
  fi
}
sucess_or_fail() {
    if [[ 0 -eq $? ]]; then
        echo -e "${Info} ${GreenBG} $1 ��� ${Font}"
        sleep 1
    else
        echo -e "${Error} ${GreenBG}$1 ʧ��${Font}"
        exit 1
    fi
}
GCE_debian10(){
  echo -e "${Tip}${RedBG}��Ϊ�ȸ��Ƶ�debian10��磬������Ҫȷ������ǰ�Ƿ��ǹȸ��Ƶ�debian10ϵͳ��Y/n����"
  echo -e "${Tip}${RedBG}ֻ�йȸ��Ƶ�debian10ϵͳ����y����������n����������ֱ�ӵ����������޷���ѧ������Y/n��(Ĭ�ϣ�n)${NO_COLOR}"
  read -rp "������:" Yn
  [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
           is_debian10="y"
        ;;
    *)
        ;;
    esac
}
install_dependency() {
  echo -e "${Info}��ʼ����ϵͳ����Ҫ���Ѽ����ӡ���"
  ${cmd} update -y
  sucess_or_fail "ϵͳ����"
  echo -e "${Info}��ʼ��װ��������"
  if [[ ${cmd} == "apt" ]]; then
    apt -y install dnsutils
  else
    yum -y install bind-utils
  fi
  sucess_or_fail "DNS���߰���װ"
  ${cmd} -y install wget
  sucess_or_fail "wget����װ"
  ${cmd} -y install unzip
  sucess_or_fail "unzip��װ"
  ${cmd} -y install zip
  sucess_or_fail "zip��װ"
  ${cmd} -y install curl
  sucess_or_fail "curl��װ"
  ${cmd} -y install tar
  sucess_or_fail "tar��װ"
  ${cmd} -y install git
  sucess_or_fail "git��װ"
  ${cmd} -y install lsof
  sucess_or_fail "lsof��װ"
  if [[ ${cmd} == "yum" ]]; then
    yum -y install crontabs
  else
    apt -y install cron
  fi
  sucess_or_fail "��ʱ���񹤾߰�װ"
  ${cmd} -y install qrencode
  sucess_or_fail "qrencode��װ"
  ${cmd} -y install bzip2
  sucess_or_fail "bzip2��װ"
  if [[ ${cmd} == "yum" ]]; then
    yum install -y epel-release
  fi
  sucess_or_fail "epel-release��װ"
  if [[ "${cmd}" == "yum" ]]; then
        ${cmd} -y groupinstall "Development tools"
    else
        ${cmd} -y install build-essential
  fi
  sucess_or_fail "���빤�߰� ��װ"

  if [[ "${cmd}" == "yum" ]]; then
      ${cmd} -y install pcre pcre-devel zlib-devel epel-release
  else
      ${cmd} -y install libpcre3 libpcre3-dev zlib1g-dev dbus
  fi
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
close_firewall() {
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  echo -e "${Info} firewalld �ѹر� ${Font}"
}
open_port() {
  if [[ ${release} != "centos" ]]; then
    #iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    #iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
    iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
    netfilter-persistent save
    netfilter-persistent reload
  else
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
	fi
}

get_ip() {
  local_ip=$(curl -s https://ipinfo.io/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.ip.sb/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.ipify.org)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://ip.seeip.org)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://ifconfig.co/ip)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s icanhazip.com)
  [[ -z ${local_ip} ]] && ${local_ip}=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
  [[ -z ${local_ip} ]] && echo -e "${Error}��ȡ������vps��ip��ַ" && exit
}
check_domain() {
  read -rp "��������������(�����Cloudflare��������������С�Ʋ�ʹ����):" domain
  real_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
  while [ "${real_ip}" != "${local_ip}" ]; do
    read -rp "����IP�������󶨵�IP��һ�£����������Ƿ�����ɹ�,��������������:" domain
    real_ip=$(ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    read -rp "�����˹�ȷ�ϣ�����Ip�������󶨵�IPһ�£�������װ��Y/n������Ĭ��:n��" continue_install
    [[ -z ${continue_install} ]] && continue_install="n"
    case ${continue_install} in
    [yY][eE][sS] | [yY])
        echo -e "${Tip} ������װ"
        break
        ;;
    *)
        echo -e "${Tip} ��װ��ֹ"
        exit 2
        ;;
    esac
  done
}

uninstall_web() {
  [[ -d ${web_dir} ]] && rm -rf ${web_dir} && echo -e "${Info}��ʼɾ��αװ��վ����" && echo -e "${Info}αװ��վɾ���ɹ���"
}

tls_generate_script_install() {
    if [[ "${cmd}" == "yum" ]]; then
        ${cmd} install socat nc -y
    else
        ${cmd} install socat netcat -y
    fi
    sucess_or_fail "��װ tls ֤�����ɽű�����"

    curl https://get.acme.sh | sh
    sucess_or_fail "��װ tls ֤�����ɽű�"
    source ~/.bashrc
}
tls_generate() {
  if [[ -f "/data/${domain}/fullchain.crt" ]] && [[ -f "/data/${domain}/privkey.key" ]]; then
    echo -e "${Info}֤���Ѵ��ڡ�������Ҫ������ǩ���ˡ���"
  else
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force --test; then
        echo -e "${Info} TLS ֤�����ǩ���ɹ�����ʼ��ʽǩ��"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        sleep 2
    else
        echo -e "${Error}TLS ֤�����ǩ��ʧ�� "
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "${Info} TLS ֤�����ɳɹ� "
        sleep 2
        mkdir /data
        mkdir /data/${domain}
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /data/${domain}/fullchain.crt --keypath /data/${domain}/privkey.key --ecc --force; then
            echo -e "${Info}֤�����óɹ� "
            sleep 2
        fi
    else
        echo -e "${Error} TLS ֤������ʧ��"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi
  fi
}
install_nginx() {
  if [[ -f ${nginx_bin_file} ]]; then
     echo -e "${Info} Nginx�Ѵ��ڣ��������밲װ���� ${Font}"
     sleep 2
  else
    wget -nc --no-check-certificate http://nginx.org/download/nginx-${nginx_version}.tar.gz -P ${nginx_openssl_src}
    sucess_or_fail "Nginx ����"
    wget -nc --no-check-certificate https://www.openssl.org/source/openssl-${openssl_version}.tar.gz -P ${nginx_openssl_src}
    sucess_or_fail "openssl ����"
    wget -nc --no-check-certificate https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version}/jemalloc-${jemalloc_version}.tar.bz2 -P ${nginx_openssl_src}
    sucess_or_fail "jemalloc ����"
    cd ${nginx_openssl_src} || exit

    [[ -d nginx-"$nginx_version" ]] && rm -rf nginx-"$nginx_version"
    tar -zxvf nginx-"$nginx_version".tar.gz

    [[ -d openssl-"$openssl_version" ]] && rm -rf openssl-"$openssl_version"
    tar -zxvf openssl-"$openssl_version".tar.gz

    [[ -d jemalloc-"${jemalloc_version}" ]] && rm -rf jemalloc-"${jemalloc_version}"
    tar -xvf jemalloc-"${jemalloc_version}".tar.bz2

    [[ -d "$nginx_dir" ]] && rm -rf ${nginx_dir}

    echo -e "${Info} ��ʼ���벢��װ jemalloc����"
    sleep 2

    cd jemalloc-${jemalloc_version} || exit
    ./configure
    sucess_or_fail "�����顭��"
    make && make install
    sucess_or_fail "jemalloc ���밲װ"
    echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
    ldconfig

    echo -e "${Info} ������ʼ���밲װ Nginx, �����Ծã������ĵȴ�����"
    sleep 4

    cd ../nginx-${nginx_version} || exit

    ./configure --prefix="${nginx_dir}" \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-pcre \
        --with-http_realip_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_secure_link_module \
        --with-http_v2_module \
        --with-cc-opt='-O3' \
        --with-ld-opt="-ljemalloc" \
        --with-openssl=../openssl-"$openssl_version"
    sucess_or_fail "������"
    make && make install
    sucess_or_fail "Nginx ���밲װ"

    # �޸Ļ�������
    sed -i 's/#user  nobody;/user  root;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/worker_processes  1;/worker_processes  3;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/    worker_connections  1024;/    worker_connections  4096;/' ${nginx_dir}/conf/nginx.conf
    sed -i '$i include conf.d/*.conf;' ${nginx_dir}/conf/nginx.conf

    # ɾ����ʱ�ļ�
    rm -rf ../nginx-"${nginx_version}"
    rm -rf ../openssl-"${openssl_version}"
    rm -rf ../nginx-"${nginx_version}".tar.gz
    rm -rf ../openssl-"${openssl_version}".tar.gz

    # ��������ļ��У�����ɰ�ű�
    mkdir ${nginx_dir}/conf/conf.d
fi
}
nginx_systemd() {
  touch ${nginx_systemd_file}
  cat >${nginx_systemd_file} <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/etc/nginx/logs/nginx.pid
ExecStartPre=/etc/nginx/sbin/nginx -t
ExecStart=/etc/nginx/sbin/nginx -c ${nginx_dir}/conf/nginx.conf
ExecReload=/etc/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
  sucess_or_fail "Nginx systemd ServerFile ���"
  systemctl daemon-reload
}
trojan_go_systemd(){
  touch ${trojan_systemd_file}
  cat >${trojan_systemd_file} << EOF
[Unit]
Description=trojan
Documentation=https://github.com/p4gefau1t/trojan-go
After=network.target

[Service]
Type=simple
StandardError=journal
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/etc/trojan/bin/trojan-go -config /etc/trojan/conf/server.json
ExecReload=
ExecStop=/etc/trojan/bin/trojan-go
LimitNOFILE=51200
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
}
uninstall_nginx() {
  if [[ -f ${nginx_bin_file} ]]; then
        echo -e "${Tip} �Ƿ�ж�� Nginx [Y/N]? "
        read -r uninstall_nginx
        case ${uninstall_nginx} in
        [yY][eE][sS] | [yY])
            rm -rf ${nginx_dir}
            echo -e "${Info} ��ж�� Nginx ${Font}"
            ;;
        *) ;;
        esac
    fi
}
download_install(){
  [[ ! -d ${trojan_dir} ]] && mkdir ${trojan_dir}
  [[ ! -d ${trojan_bin_dir} ]] && mkdir ${trojan_bin_dir}
  if [[ ! -f ${trojan_bin_dir}/trojan-go ]];then
      case  ${bit} in
      "x86_64")
        wget --no-check-certificate -O ${trojan_bin_dir}/trojan-go-linux-amd64.zip "https://github.com/p4gefau1t/trojan-go/releases/download/v0.4.10/trojan-go-linux-amd64.zip"
        sucess_or_fail "trojan-go����"
        unzip -o -d ${trojan_bin_dir} ${trojan_bin_dir}/trojan-go-linux-amd64.zip
        sucess_or_fail "trojan-go��ѹ"
        ;;
      "i386" | "i686")
        wget --no-check-certificate -O ${trojan_bin_dir}/trojan-go-linux-386.zip "https://github.com/p4gefau1t/trojan-go/releases/download/v0.4.10/trojan-go-linux-386.zip"
         sucess_or_fail "trojan-go����"
        unzip -o -d ${trojan_bin_dir} ${trojan_bin_dir}/trojan-go-linux-386.zip
        sucess_or_fail "trojan-go��ѹ"
        ;;
      "armv7l")
        wget --no-check-certificate -O ${trojan_bin_dir}/trojan-go-linux-armv7.zip "https://github.com/p4gefau1t/trojan-go/releases/download/v0.4.10/trojan-go-linux-armv7.zip"
         sucess_or_fail "trojan-go����"
        unzip -o -d ${trojan_bin_dir} ${trojan_bin_dir}/trojan-go-linux-armv7.zip
        sucess_or_fail "trojan-go��ѹ"
        ;;
      *)
        echo -e "${Error}��֧�� [${bit}] ! ����Jeannie����[]�е����ƣ��ἰʱ���֧�֡�" && exit 1
        ;;
      esac
      rm -f ${trojan_bin_dir}/trojan-go-linux-amd64.zip
      rm -f ${trojan_bin_dir}/trojan-go-linux-386.zip
      rm -f ${trojan_bin_dir}/trojan-go-linux-armv7.zip
  else
    echo -e "${Info}trojan-go�Ѵ��ڣ����谲װ"
  fi
}

trojan_go_uninstall(){
  [[ -d ${trojan_dir} ]] && rm -rf ${trojan_dir} && echo -e "${Info}Trojan-goж�سɹ�"
}
trojan_go_qr_config(){
  touch ${trojan_qr_config_file}
  cat >${trojan_qr_config_file} <<-EOF
  "domain": "${domain}"
  "uuid": "${uuid}"
  "password": "${password}"
  "obfuscation_password":"${obfuscation_password}"
  "websocket_status":"${websocket_status}"
  "double_tls":"${double_tls}"
  "websocket_path":"${websocket_path}"
EOF
}
trojan_info_extraction() {
  grep "$1" ${trojan_conf_file} | awk -F '"' '{print $4}'
}
trojan_go_conf(){
  [[ ! -d ${trojan_conf_dir} ]] && mkdir ${trojan_conf_dir}
  touch ${trojan_conf_file}
  read -rp "$(echo -e "${Info}����������Trojan-go����:")" password
  while [[ -z ${password} ]]; do
    read -rp "$(echo -e "${Tip}���벻��Ϊ��,��������������Trojan-go����:")" password
  done
  cat >${trojan_conf_file} <<EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "log_level": 1,
  "log_file": "",
  "password": [
       "${password}"
  ],
  "buffer_size": 32,
  "dns": [],
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "/data/${domain}/fullchain.crt",
    "key": "/data/${domain}/privkey.key",
    "key_password": "",
    "cipher": "",
    "cipher_tls13": "",
    "curves": "",
    "prefer_server_cipher": false,
    "sni": "",
    "alpn": [
      "http/1.1"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "",
    "fallback_port": 1234,
    "fingerprint": "firefox",
    "serve_plain_text": false
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "prefer_ipv4": false,
    "fast_open": false,
    "fast_open_qlen": 20
  },
  "mux": {
    "enabled": false,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": false,
    "bypass": [],
    "proxy": [],
    "block": [],
    "default_policy": "proxy",
    "domain_strategy": "as_is",
    "geoip": "./geoip.dat",
    "geosite": "./geoip.dat"
  },
  "websocket": {
    "enabled": false,
    "path": "",
    "hostname": "127.0.0.1",
    "obfuscation_password": "",
    "double_tls": false,
    "ssl": {
      "verify": true,
      "verify_hostname": true,
      "cert": "/data/${domain}/fullchain.crt",
      "key": "/data/${domain}/privkey.key",
      "key_password": "",
      "prefer_server_cipher": false,
      "sni": "",
      "session_ticket": true,
      "reuse_session": true,
      "plain_http_response": ""
    }
  },
  "forward_proxy": {
    "enabled": false,
    "proxy_addr": "",
    "proxy_port": 0,
    "username": "",
    "password": ""
  },
  "mysql": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 3306,
    "database": "",
    "username": "",
    "password": "",
    "check_rate": 60
  },
  "redis": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 6379,
    "password": ""
  },
  "api": {
    "enabled": false,
    "api_addr": "",
    "api_port": 0
  }
}
EOF
}
trojan_client_conf(){
  uuid=$(cat /proc/sys/kernel/random/uuid)
  touch ${web_dir}/${uuid}.json
  cat >${web_dir}/${uuid}.json <<EOF
  {
  "run_type": "client",
  "local_addr": "127.0.0.1",
  "local_port": 1080,
  "remote_addr": "${domain}",
  "remote_port": 443,
  "log_level": 1,
  "log_file": "",
  "password": [
    "${password}"
  ],
  "buffer_size": 32,
  "dns": [],
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "/data/${domain}/fullchain.crt",
    "key": "/data/${domain}/privkey.key",
    "key_password": "",
    "cipher": "",
    "cipher_tls13": "",
    "curves": "",
    "prefer_server_cipher": false,
    "sni": "",
    "alpn": [
      "http/1.1"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "",
    "fallback_port": 1234,
    "fingerprint": "firefox",
    "serve_plain_text": false
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "prefer_ipv4": false,
    "fast_open": false,
    "fast_open_qlen": 20
  },
  "mux": {
    "enabled": false,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": false,
    "bypass": [],
    "proxy": [],
    "block": [],
    "default_policy": "proxy",
    "domain_strategy": "as_is",
    "geoip": "./geoip.dat",
    "geosite": "./geoip.dat"
  },
  "websocket": {
    "enabled": false,
    "path": "",
    "hostname": "127.0.0.1",
    "obfuscation_password": "",
    "double_tls": false,
    "ssl": {
      "verify": true,
      "verify_hostname": true,
      "cert": "/data/${domain}/fullchain.crt",
      "key": "/data/${domain}/privkey.key",
      "key_password": "",
      "prefer_server_cipher": false,
      "sni": "",
      "session_ticket": true,
      "reuse_session": true,
      "plain_http_response": ""
    }
  },
  "forward_proxy": {
    "enabled": false,
    "proxy_addr": "",
    "proxy_port": 0,
    "username": "",
    "password": ""
  },
  "mysql": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 3306,
    "database": "",
    "username": "",
    "password": "",
    "check_rate": 60
  },
  "redis": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 6379,
    "password": ""
  },
  "api": {
    "enabled": false,
    "api_addr": "",
    "api_port": 0
  }
}
EOF
}
web_download() {
  [[ ! -d "${web_dir}" ]] && mkdir "${web_dir}"
  while [[ ! -f "${web_dir}/web.zip" ]]; do
    echo -e "${Tip}αװ��վδ���ػ�����ʧ��,��ѡ�����������һ����������:
      ${Info}1. https://templated.co/intensify
      ${Info}2. https://templated.co/binary
      ${Info}3. https://templated.co/retrospect
      ${Info}4. https://templated.co/spatial
      ${Info}5. https://templated.co/monochromed
      ${Info}6. https://templated.co/transit
      ${Info}7. https://templated.co/interphase
      ${Info}8. https://templated.co/ion
      ${Info}9. https://templated.co/solarize
      ${Info}10. https://templated.co/phaseshift
      ${Info}11. https://templated.co/horizons
      ${Info}12. https://templated.co/grassygrass
      ${Info}13. https://templated.co/breadth
      ${Info}14. https://templated.co/undeviating
      ${Info}15. https://templated.co/lorikeet"
    read -rp "$(echo -e "${Tip}��������Ҫ���ص���վ������:")" aNum
    case $aNum in
    1)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/intensify/download
      ;;
    2)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/binary/download
      ;;
    3)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/retrospect/download
      ;;
    4)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/spatial/download
      ;;
    5)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/monochromed/download
      ;;
    6)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/transit/download
      ;;
    7)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/interphase/download
      ;;
    8)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/ion/download
      ;;
    9)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/solarize/download
      ;;
    10)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/phaseshift/download
      ;;
    11)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/horizons/download
      ;;
    12)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/grassygrass/download
      ;;
    13)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/breadth/download
      ;;
    14)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/undeviating/download
      ;;
    15)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/lorikeet/download
      ;;
    *)
      wget -O ${web_dir}/web.zip --no-check-certificate https://templated.co/intensify/download
      ;;
    esac
  done
  unzip -o -d ${web_dir} ${web_dir}/web.zip
}
open_websocket(){
  echo -e "${Info}�Ƿ�����websocketЭ��?ע�⣺�������ѡ�����������·�ٶȣ������п����½���"
  echo -e "${Info}���������websocketЭ��,���Ϳ��Կ���CDN�ˣ������cloudflare���������ģ����ɺ���Ե���С�Ʋ��ˡ�"
  read -rp "$(echo -e "${Info}�Ƿ�����Y/n������Ĭ�ϣ�n��")" Yn
    case ${Yn} in
    [yY][eE][sS] | [yY])
        sed -i "59c    \"enabled\": true," ${trojan_conf_file}
        sed -i "59c    \"enabled\": true," ${web_dir}/"${uuid}".json
        sed -i "60c    \"path\": \"/trojan\"," ${trojan_conf_file}
        sed -i "60c    \"path\": \"/trojan\"," ${web_dir}/"${uuid}".json
        websocket_path="/trojan"
        websocket_status="����"
        echo -e "${Info}�����׼��ʹ�õĹ���CDN,Ϊ�����⵽��������CDN��Ӫ��ʶ��ĸ��ʣ��������������"
        echo -e "${Info}�����˻��������������һ��Ӱ�죬���������ð�ȫ�Ժ����ܵ�ƽ�⣬Ĭ��Ϊ��"
        read -rp "$(echo -e "������������룺")" obfuscation_password
        sed -i "62c \"obfuscation_password\": \"${obfuscation_password}\"," ${trojan_conf_file}
        sed -i "62c \"obfuscation_password\": \"${obfuscation_password}\"," ${web_dir}/${uuid}.json
        sed -i "63c \"double_tls\": true," ${trojan_conf_file}
        sed -i "63c \"double_tls\": true," ${web_dir}/${uuid}.json
        double_tls="����"
        ;;
    *)
        websocket_status="�ر�"
        double_tls="�ر�"
        websocket_path=""
        obfuscation_password=""
        ;;
    esac
}
trojan_go_basic_information() {
  {
echo -e "
${GREEN}=========================Trojan-go+tls ��װ�ɹ�==============================
${FUCHSIA}=========================   Trojan-go ������Ϣ  =============================
${GREEN}��ַ��              ${domain}
${GREEN}�˿ڣ�              443
${GREEN}���룺              ${password}
${GREEN}websocket״̬��     ${websocket_status}
${GREEN}websocket·����     ${websocket_path}
${GREEN}websocket����TLS��  ${double_tls}
${GREEN}�������룺        ${obfuscation_password}
${FUCHSIA}=========================   �ͻ��������ļ�  ===============================
${GREEN}��ϸ��Ϣ��https://${domain}/${uuid}.html${NO_COLOR}"
} | tee /etc/motd
}

nginx_trojan_conf() {
  touch ${nginx_conf_dir}/default.conf
  cat >${nginx_conf_dir}/default.conf <<EOF
  server {
    listen 80;
    server_name ${domain};
    root ${web_dir};
}
EOF
}
install_caddy() {
  if [[ -d ${caddy_bin_dir} ]] && [[ -f ${caddy_systemd_file} ]] && [[ -d ${caddy_conf_dir} ]]; then
    read -rp "$(echo -e "${Tip}��⵽�Ѿ���װ��caddy,�Ƿ����°�װ��Y/n��?(Ĭ�ϣ�n)")" Yn
    [[ -z ${Yn} ]] && Yn="n"
    case ${Yn} in
    [yY][eE][sS] | [yY])
        echo -e "${Info}��ʼ��װcaddy����"
        sleep 2
        curl https://getcaddy.com | bash -s personal hook.service
        ;;
    *)
        ;;
    esac
  else
    echo -e "${Info}��ʼ��װcaddy����"
    sleep 2
    curl https://getcaddy.com | bash -s personal hook.service
  fi
}
install_caddy_service(){
  echo -e "${Info}��ʼ��װcaddy��̨������񡭡�"
  rm -f ${caddy_systemd_file}
  #if [[ ${email} == "" ]]; then
  #  read -p "$(echo -e "${Info}����д�������䣺")" email
  #  read -p "$(echo -e "${Info}����������ȷ��Y/n������Ĭ�ϣ�n��")" Yn
  #  [[ -z ${Yn} ]] && Yn="n"
  #  while [[ ${Yn} != "Y" ]] && [[ ${Yn} != "y" ]]; do
  #      read -p "$(echo -e "${Tip}������д�������䣺")" email
  #      read -p "$(echo -e "${Info}����������ȷ��Y/n������Ĭ�ϣ�n��")" Yn
  #      [[ -z ${Yn} ]] && Yn="n"
  #  done
 #fi
 #caddy -service install -agree -email "${email}" -conf "${caddy_conf}"
 caddy -service install -agree -email "example@gmail.com" -conf "${caddy_conf}"
 sucess_or_fail "caddy��̨�������װ"
}
caddy_trojan_conf() {
   [[ ! -d ${caddy_conf_dir} ]] && mkdir ${caddy_conf_dir}
  touch ${caddy_conf}
  cat >${caddy_conf} <<_EOF
http://${domain}:80 {
  gzip
  timeouts none
  tls /data/${domain}/fullchain.crt /data/${domain}/privkey.key {
       protocols tls1.0 tls1.3
    }
  root ${web_dir}
}
_EOF
}
uninstall_caddy() {
  if [[ -f ${caddy_bin_dir}/caddy ]] || [[ -f ${caddy_systemd_file} ]] || [[ -d ${caddy_conf_dir} ]] || [[ -f ${caddy_bin_dir}/caddy_old ]]; then
    echo -e "${Info}��ʼж��Caddy����"
    [[ -f ${caddy_bin_dir}/caddy ]] && rm -f ${caddy_bin_dir}/caddy
    [[ -f ${caddy_bin_dir}/caddy_old ]] && rm -f ${caddy_bin_dir}/caddy_old
    [[ -d ${caddy_conf_dir} ]] && rm -rf ${caddy_conf_dir}
    [[ -f ${caddy_systemd_file} ]] && rm -f ${caddy_systemd_file}
    echo -e "${Info}Caddyж�سɹ���"
  fi
}
port_used_check() {
    if [[ 0 -eq $(lsof -i:"$1" | grep -i -c "listen") ]]; then
        echo -e "${Info} $1 �˿�δ��ռ��"
        sleep 1
    else
        echo -e "${Error}��⵽ $1 �˿ڱ�ռ�ã�����Ϊ $1 �˿�ռ����Ϣ ${Font}"
        lsof -i:"$1"
        echo -e "${Info} 5s �󽫳����Զ� kill ռ�ý��� "
        sleep 5
        lsof -i:"$1" | awk '{print $2}' | grep -v "PID" | xargs kill -9
        echo -e "${Info} kill ���"
        sleep 1
    fi
}
install_bbr() {
  wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
  chmod +x tcp.sh
  ./tcp.sh
}
download_trojan_mgr(){
  curl -s -o /etc/trojan_mgr.sh https://raw.githubusercontent.com/JeannieStudio/all_install/master/trojan_mgr.sh
  sucess_or_fail "�޸����롢�������롢����/����websocket����ѯ֤�������Ϣ�Ĺ���ű�����"
  chmod +x /etc/trojan_mgr.sh
}
remove_trojan_mgr(){
  [[ -f /etc/trojan_mgr.sh ]] && rm -f /etc/trojan_mgr.sh && echo -e "${Info}trojan_mgr.shɾ���ɹ�"
}
trojan_go_info_html() {
  vps="Trojan-go"
  wget --no-check-certificate -O ${web_dir}/trojan_go_tmpl.html https://raw.githubusercontent.com/JeannieStudio/jeannie/master/trojan_go_tmpl.html
  chmod +x ${web_dir}/trojan_go_tmpl.html
eval "cat <<EOF
  $(<${web_dir}/trojan_go_tmpl.html)
EOF
" >${web_dir}/${uuid}.html
}
trojan_nginx_install(){
  check_root
  check_sys
  sys_cmd
  sucess_or_fail
  #GCE_debian10
  install_dependency
  #close_firewall
  download_install
  port_used_check 80
  port_used_check 443
  uninstall_web
  remove_trojan_mgr
  uninstall_caddy
  get_ip
  check_domain
  tls_generate_script_install
  tls_generate
  web_download
  #generate_trojan_go_tls
  trojan_go_conf
  trojan_client_conf
  open_websocket
  trojan_go_qr_config
  install_nginx
  nginx_systemd
  nginx_trojan_conf
  systemctl restart nginx
  systemctl enable nginx
  trojan_go_info_html
  trojan_go_systemd
  systemctl start trojan.service
	systemctl enable trojan.service
	download_trojan_mgr
  trojan_go_basic_information
}
trojan_caddy_install(){
  check_root
  # shellcheck disable=SC2164
  cd /root
  set_SELINUX
  check_sys
  sys_cmd
  sucess_or_fail
  install_dependency
  #close_firewall
  download_install
  port_used_check 80
  port_used_check 443
  uninstall_web
  remove_trojan_mgr
  uninstall_nginx
  get_ip
  check_domain
  tls_generate_script_install
  tls_generate
  web_download
  #generate_trojan_go_tls
  trojan_go_conf
  trojan_client_conf
  open_websocket
  trojan_go_qr_config
  install_caddy
  install_caddy_service
  caddy_trojan_conf
  caddy -service start
  trojan_go_info_html
  trojan_go_systemd
  systemctl start trojan.service
	systemctl enable trojan.service
	download_trojan_mgr
  trojan_go_basic_information
}
uninstall_all(){
  uninstall_nginx
  trojan_go_uninstall
  uninstall_caddy
  uninstall_web
  remove_trojan_mgr
  echo -e "${Info}ж����ɣ�ϵͳ�ص���ʼ״̬��"
}
main() {
  echo -e "
${FUCHSIA}===================================================
${GREEN}Trojan-go����һ�ű�(authored by Jeannie)
${FUCHSIA}===================================================
${GREEN}����Ѿ���װ�����нű�֮һ����Ҫ��װ�����ģ�����Ҫ����ִ��ж�أ�ֱ��ѡ����Ҫ��װ�ű���Ӧ�����ּ��ɡ���
${GREEN}��Ϊ��װ��ͬʱ��ִ��ж�أ�������ж�ظɾ��ص���ʼ״̬,����ִ��3����
${FUCHSIA}===================================================
${GREEN}1. ��װtrojan-go + nginx +tls
${FUCHSIA}===================================================
${GREEN}2. ��װtrojan-go + caddy +tls
${FUCHSIA}===================================================
${GREEN}3. ж��ȫ����ϵͳ�ص���ʼ״̬
${FUCHSIA}===================================================
${GREEN}4. ��װBBR����
${FUCHSIA}===================================================
${GREEN}0. ɶҲ�������˳�${NO_COLOR}"
  read -rp "���������֣�" menu_num
  case $menu_num in
  1)
    trojan_nginx_install
    ;;
  2)
    trojan_caddy_install
    ;;
  3)
    uninstall_all
    ;;
  4)
    install_bbr
    ;;
  0)
    exit 0
    ;;
  *)
    echo -e "${RedBG}��������ȷ������${Font}"
    ;;
  esac
}
main