#!/bin/bash

set -e

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# 更新apt包索引
sudo apt-get update

# 安装ca-certificates和curl
sudo apt-get install -y ca-certificates curl jq

# 创建keyrings目录
sudo install -m 0755 -d /etc/apt/keyrings

# 下载Docker的GPG密钥
sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# 修改GPG密钥的权限
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 将Docker存储库添加到Apt源列表中
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新apt包索引
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

registry_mirrors='{
    "registry-mirrors": [
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://cr.console.aliyun.com",
        "https://mirror.ccs.tencentyun.com"
    ]
}'

# Docker daemon.json 文件路径
daemon_json_path="/etc/docker/daemon.json"

# 检查文件是否存在
if [ -f "$daemon_json_path" ]; then
    # 读取现有的 JSON 数据
    existing_content=$(cat "$daemon_json_path")
    if [ -z "$existing_content" ]; then
        # 文件为空，直接写入 registry mirrors
        echo "$registry_mirrors" | sudo tee "$daemon_json_path" > /dev/null
    else
        # 文件不为空，合并 JSON 数据
        echo "$existing_content" | jq '. + '"$registry_mirrors" | sudo tee "$daemon_json_path.tmp" > /dev/null && sudo mv "$daemon_json_path.tmp" "$daemon_json_path"
    fi
else
    # 文件不存在，创建并写入 registry mirrors
    echo "$registry_mirrors" | sudo tee "$daemon_json_path" > /dev/null
fi

# 重启 Docker 服务以使更改生效
sudo systemctl restart docker
sudo docker pull docker.io/library/python:3.7-slim-bullseye

cd ~
git clone https://ghp.ci/https://github.com/LmeSzinc/AzurLaneAutoScript.git
cd ~/AzurLaneAutoScript/config
mv deploy.template-docker-cn.yaml deploy.yaml
cd ~/AzurLaneAutoScript/deploy/docker
mv Dockerfile.cn Dockerfile
sudo docker build --no-cache -t hgjazhgj/alas:latest .
cd ~/AzurLaneAutoScript
sudo docker run -d --restart unless-stopped -v ${PWD}:/app/AzurLaneAutoScript -p 22267:22267 --name alas -it  hgjazhgj/alas # 后台启动容器


