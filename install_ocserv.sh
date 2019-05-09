#!/bin/bash
# check variables
if [ ! -n "$4" ] ;then
	echo "Insufficient variables detected. Usage:"
	echo "initialize.sh sub-domain_name domain_name cloudflare_email cloudflare_private_key."
	exit 1
else
  # check root
  if [ `whoami` = "root" ];then
    if [ $(sysctl net.ipv4.tcp_congestion_control) ! = "net.ipv4.tcp_congestion_control = bbr" ];then
      modprobe tcp_bbr
      echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
      echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
      sysctl -p
    fi
    if [ $(cat /proc/sys/net/ipv4/ip_forward) = 0 ];then
      echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
      sysctl -p
    fi
		apt update
		apt dist-upgrade -y
		apt install shadowsocks-libev build-essential ocserv python3-certbot-dns-cloudflare unzip -y
    wget -O ocserv.zip "https://github.com/dreamsafari/ocserv-auto-config/blob/master/ocserv.zip?raw=true"
    rm -rf /etc/ocserv
    unzip ocserv.zip -d /etc/ocserv
    rm ocserv.zip
    # cloudflare sub-domain registration
    ip=$(curl -s http://ipv4.icanhazip.com)
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$2" -H "X-Auth-Email: $3" -H "X-Auth-Key: $4" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    status=$(curl -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/" -H "X-Auth-Email: $3" -H "X-Auth-Key: $4" -H "Content-Type: application/json" --data '{"type":"'"A"'","name":"'"secure2"'","content":"'"$ip"'","proxied":'"false"',"ttl":'"1"'}')
    if [[ $status == *"\"success\":false"* ]]; then
      echo "Sub-domain registration failed. Please manually register with Cloudflare (Maybe already registered?)"
      read -p "Press [Enter] key when registration is complete or ctrl+c to terminate the script..."
    fi
    mkdir /root/.secrets
    echo "dns_cloudflare_email = \"$3\"
    dns_cloudflare_api_key = \"$4\"" > /root/.secrets/cloudflare.ini
    chmod 0700 /root/.secrets/
    chmod 0400 /root/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d $1.$2 --preferred-challenges dns-01
    sed -i "s/your_domain/$1.$2/g" /etc/ocserv/ocserv.conf
    systemctl restart ocserv
    interface=$(find /sys/class/net ! -type d | xargs --max-args=1 realpath  | awk -F\/ '/pci/{print $NF}')
    iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
    echo "Success"
    echo "Next, please use \"ocpasswd -g Global,Optimized -c /etc/ocserv/ocpasswd user_name\" to add users and set their passwords"
    exit 0
  else
    echo "This script should be run as root. Now exit."
    exit 1
  fi
fi
