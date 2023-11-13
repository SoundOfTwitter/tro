#!/bin/bash

# 切换到 root 用户
sudo -i

# 更新软件包列表
apt-get update

# 安装 gnutls-bin 软件包并自动选择“是”
yes | apt-get install gnutls-bin

# 切换到 /home 目录
cd /home

# 创建一个新文件 "ca.txt"
touch ca.txt

# 写入文件内容
cat <<EOF > ca.txt
cn = "18.141.179.7"
organization = "GlobalSign RULTR"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF

# 确认文件已创建
ls ca.txt

# 创建一个新文件 "server.txt"
touch server.txt

# 写入文件内容
cat <<EOF > server.txt
cn = "18.141.179.7"
organization = "GlobalSign RULTR"
expiration_days = 3650
signing_key
encryption_key
tls_www_server
EOF

# 确认文件已创建
ls server.txt

# 生成 ca-key.pem
certtool --generate-privkey --outfile ca-key.pem

# 生成自签名的 CA 证书 ca-cert.pem，同时选择“是”
yes | certtool --generate-self-signed --load-privkey ca-key.pem --template ca.txt --outfile ca-cert.pem

# 生成 trojan-key.pem，同时选择“是”
certtool --generate-privkey --outfile trojan-key.pem

# 生成 trojan-cert.pem，同时选择“是”
certtool --generate-certificate --load-privkey trojan-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.txt --outfile trojan-cert.pem

# 安装 trojan 软件包并选择“是”
yes | apt-get install trojan

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
systemctl status trojan
