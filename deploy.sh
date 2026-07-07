#!/bin/bash
set -e

echo "=============================="
echo "  Toonflow 一键部署脚本"
echo "=============================="

# 安装 Docker（如果未安装）
if ! command -v docker &> /dev/null; then
    echo "[1/4] 安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "Docker 安装完成"
else
    echo "[1/4] Docker 已安装: $(docker --version)"
fi

# 安装 Docker Compose 插件（如果未安装）
if ! docker compose version &> /dev/null; then
    echo "[2/4] 安装 Docker Compose 插件..."
    apt-get update -qq && apt-get install -y -qq docker-compose-plugin 2>/dev/null || {
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
            -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    }
    echo "Docker Compose 安装完成"
else
    echo "[2/4] Docker Compose 已安装: $(docker compose version)"
fi

# 安装 Git（如果未安装）
if ! command -v git &> /dev/null; then
    echo "[3/4] 安装 Git..."
    apt-get update -qq && apt-get install -y -qq git
else
    echo "[3/4] Git 已安装: $(git --version)"
fi

# 克隆或更新代码
DEPLOY_DIR="/opt/toonflow"
REPO_URL="https://github.com/ldcstc-gif/toonflow-app.git"
BRANCH="claude/project-deployment-4z2cbk"

echo "[4/4] 部署应用..."

if [ -d "$DEPLOY_DIR" ]; then
    echo "更新代码..."
    cd "$DEPLOY_DIR"
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    echo "克隆代码..."
    git clone -b "$BRANCH" "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

# 构建并启动服务
echo ""
echo "构建 Docker 镜像（首次可能需要几分钟）..."
docker compose down 2>/dev/null || true
docker compose up -d --build

echo ""
echo "=============================="
echo "  部署完成!"
echo "=============================="
echo ""
echo "  访问地址: http://$(hostname -I | awk '{print $1}'):80"
echo "  直接端口: http://$(hostname -I | awk '{print $1}'):10588"
echo ""
echo "  常用命令:"
echo "    查看日志:   cd $DEPLOY_DIR && docker compose logs -f"
echo "    重启服务:   cd $DEPLOY_DIR && docker compose restart"
echo "    停止服务:   cd $DEPLOY_DIR && docker compose down"
echo "    更新部署:   cd $DEPLOY_DIR && git pull && docker compose up -d --build"
echo ""
