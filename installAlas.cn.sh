#!/bin/bash

set -e

# 检查Docker是否已经安装
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Proceeding with installation."

  # 删除可能会干扰的旧版本或相关包
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
  done

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

  # 更新apt包索引并安装Docker
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "Docker is already installed. Skipping installation."
fi

# 配置Docker镜像加速器
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
daemon_updated=false

# 检查文件是否存在
if [ -f "$daemon_json_path" ]; then
    # 读取现有的 JSON 数据
    existing_content=$(cat "$daemon_json_path")
    if [ -z "$existing_content" ]; then
        # 文件为空，直接写入 registry mirrors
        echo "$registry_mirrors" | sudo tee "$daemon_json_path" > /dev/null
        daemon_updated=true
    else
        # 文件不为空，合并 JSON 数据
        new_content=$(echo "$existing_content" | jq '. + '"$registry_mirrors")
        if [[ "$new_content" != "$existing_content" ]]; then
            echo "$new_content" | sudo tee "$daemon_json_path.tmp" > /dev/null && sudo mv "$daemon_json_path.tmp" "$daemon_json_path"
            daemon_updated=true
        fi
    fi
else
    # 文件不存在，创建并写入 registry mirrors
    echo "$registry_mirrors" | sudo tee "$daemon_json_path" > /dev/null
    daemon_updated=true
fi

# 仅当更新了daemon.json时才重启 Docker 服务
if [ "$daemon_updated" = true ]; then
  echo "Restarting Docker to apply changes in daemon.json."
  sudo systemctl restart docker
else
  echo "No changes to daemon.json. Skipping Docker restart."
fi

# 检查Docker镜像是否已经存在
image_name="python:3.7-slim-bullseye"
if ! sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$image_name"; then
  echo "Docker image $image_name not found locally. Pulling the image."
  sudo docker pull docker.io/library/"$image_name"
else
  echo "Docker image $image_name already exists locally. Skipping pull."
fi

# 检查仓库是否已经存在
repo_path=~/AzurLaneAutoScript
if [ -d "$repo_path" ]; then
  echo "The repository already exists at $repo_path."
  read -p "Do you want to delete it and clone a fresh copy? (y/n): " response
  if [[ "$response" == "y" || "$response" == "Y" ]]; then
    sudo rm -rf "$repo_path"
    echo "Existing repository deleted."
  else
    echo "Skipping clone as the repository already exists."
  fi
fi

# 如果用户选择删除或目录不存在，则进行克隆
if [ ! -d "$repo_path" ]; then
  cd ~
  git clone https://ghp.ci/https://github.com/LmeSzinc/AzurLaneAutoScript.git
fi

# 检查是否存在名为 "alas" 的容器
container_name="alas"
if [ "$(sudo docker ps -aq -f name=^/${container_name}$)" ]; then
  echo "A container named '$container_name' already exists."
  read -p "Do you want to delete it and rebuild the container? (y/n): " response
  if [[ "$response" == "y" || "$response" == "Y" ]]; then
    sudo docker rm -f "$container_name"
    echo "Existing container deleted."
  else
    echo "Skipping container build as the container already exists."
    exit 0
  fi
fi

# Docker 构建步骤
cd ~/AzurLaneAutoScript/config
mv deploy.template-docker-cn.yaml deploy.yaml
cd ~/AzurLaneAutoScript/deploy/docker
mv Dockerfile.cn Dockerfile
sudo docker build --no-cache -t hgjazhgj/alas:latest .

# 启动Docker容器
cd ~/AzurLaneAutoScript
sudo docker run -d --restart unless-stopped -v ${PWD}:/app/AzurLaneAutoScript -p 22267:22267 --name alas -it hgjazhgj/alas
