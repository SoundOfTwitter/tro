#!/bin/bash
publicIP=$(curl -s https://api64.ipify.org?format=json | jq -r .ip)
# 写入文件内容
echo 'cn = ${publicIP}' >> /home/admin/ca.txt
echo 'organization = "GlobalSign RULTR"' >> /home/admin/ca.txt
echo 'serial = 1' >> /home/admin/ca.txt
echo 'expiration_days = 3650' >> /home/admin/ca.txt
echo 'ca' >> /home/admin/ca.txt
echo 'signing_key' >> /home/admin/ca.txt
echo 'cert_signing_key' >> /home/admin/ca.txt
echo 'crl_signing_key' >> /home/admin/ca.txt
# 写入文件内容
echo 'cn = ${publicIP}' >> /home/admin/server.txt
echo 'organization = "GlobalSign RULTR"' >> /home/admin/server.txt
echo 'expiration_days = 3650' >> /home/admin/server.txt
echo 'signing_key' >> /home/admin/server.txt
echo 'encryption_key' >> /home/admin/server.txt
echo 'tls_www_server' >> /home/admin/server.txt
# 生成 ca-key.pem
certtool --generate-privkey --outfile ca-key.pem
# 生成自签名的 CA 证书 ca-cert.pem，同时选择“是”
yes | certtool --generate-self-signed --load-privkey ca-key.pem --template ca.txt --outfile ca-cert.pem
# 生成 trojan-key.pem，同时选择“是”
certtool --generate-privkey --outfile trojan-key.pem
# 生成 trojan-cert.pem，同时选择“是”
certtool --generate-certificate --load-privkey trojan-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.txt --outfile trojan-cert.pem
# 将 trojan 使用的证书文件拷贝到目录/etc/trojan：
cp trojan-cert.pem trojan-key.pem /etc/trojan
# 修改 config.json 文件
sed -i '8s/.*/        "aDm8H%MdA",/' /etc/trojan/config.json
sed -i '13s/.*/        "cert": "\/etc\/trojan\/trojan-cert.pem",/' /etc/trojan/config.json
sed -i '14s/.*/        "key": "\/etc\/trojan\/trojan-key.pem",/' /etc/trojan/config.json
# 将/lib/systemd/system/trojan.service里的User更改为trojan
sed -i '9s/.*/User=trojan/' /lib/systemd/system/trojan.service
groupadd -g 54321 trojan
useradd -g trojan -s /usr/sbin/nologin trojan
chown -R trojan:trojan /etc/trojan
systemctl start trojan
systemctl enable trojan
echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
reboot
