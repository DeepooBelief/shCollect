#!/bin/bash

set -e

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# 更新apt包索引
sudo apt-get update

# 安装ca-certificates和curl
sudo apt-get install -y ca-certificates curl

# 创建keyrings目录
sudo install -m 0755 -d /etc/apt/keyrings

# 下载Docker的GPG密钥
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# 修改GPG密钥的权限
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 将Docker存储库添加到Apt源列表中
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新apt包索引
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
cd ~
git clone https://github.com/LmeSzinc/AzurLaneAutoScript.git
cd ~/AzurLaneAutoScript/config
mv deploy.template-docker-cn.yaml deploy.yaml
cd ~/AzurLaneAutoScript/deploy/docker
mv Dockerfile.cn Dockerfile
sudo docker build --no-cache -t hgjazhgj/alas:latest .
cd ~/AzurLaneAutoScript
sudo docker run -d --restart unless-stopped -v ${PWD}:/app/AzurLaneAutoScript -p 22267:22267 --name alas -it  hgjazhgj/alas # 后台启动容器



