#!/bin/bash

set -e

# 显示帮助信息
show_help() {
    cat << EOF
用法: $(basename "$0") [选项]

选项:
  -y, --you-domain <域名>        你的域名或IP (例如: example.com)
  -r, --r-domain <域名>          反代 Emby 前端域名 (例如: r.example.com)
  -t, --backend-domain <域名>    反代 Emby 后端域名 (默认: backend.example.com)
  -R, --r-path <路径>              反代 Emby 后端目标路径 (可选, 例如: /emby)
  -P, --you-frontend-port <端口>  你的前端访问端口 (默认: 443)
  -p, --r-frontend-port <端口>    反代 Emby 前端端口 (默认: 空)
  -f, --r-http-frontend          反代 Emby 使用 HTTP 作为前端访问 (默认: 否)
  -b, --r-http-backend           反代 Emby 使用 HTTP 连接后端 (默认: 否)
  -s, --no-tls                   禁用 TLS (默认: 否)
  -h, --help                     显示帮助信息
EOF
    exit 0
}

# 初始化变量
you_domain=""
r_domain=""
backend_domain="backend.example.com"
r_path="" # 新增：后端路径变量
you_frontend_port="443"
r_frontend_port=""
r_http_backend="no"
r_http_frontend="no"
no_tls="no"

# 使用 `getopt` 解析参数 - 添加 R: 和 r-path:
TEMP=$(getopt -o y:r:t:P:p:bfshR: --long you-domain:,r-domain:,backend-domain:,you-frontend-port:,r-frontend-port:,r-http-frontend,r-http-backend,no-tls,help,r-path: -n "$(basename "$0")" -- "$@")

if [ $? -ne 0 ]; then
    echo "参数解析失败，请检查输入的参数。"
    exit 1
fi

eval set -- "$TEMP"

while true; do
    case "$1" in
        -y|--you-domain) you_domain="$2"; shift 2 ;;
        -r|--r-domain) r_domain="$2"; shift 2 ;;
        -t|--backend-domain) backend_domain="$2"; shift 2 ;;
        -R|--r-path) r_path="$2"; shift 2 ;; # 新增：处理后端路径参数
        -P|--you-frontend-port) you_frontend_port="$2"; shift 2 ;;
        -p|--r-frontend-port) r_frontend_port="$2"; shift 2 ;;
        -b|--r-http-backend) r_http_backend="yes"; shift ;;
        -f|--r-http-frontend) r_http_frontend="yes"; shift ;;
        -s|--no-tls) no_tls="yes"; shift ;;
        -h|--help) show_help; shift ;;
        --) shift; break ;;
        *) echo "错误: 未知参数 $1"; exit 1 ;;
    esac
done

# 交互模式 (如果未提供必要参数) - 添加对 backend_domain 的检查
if [[ -z "$you_domain" || -z "$r_domain" ]]; then # backend_domain 有默认值，通常不需要交互
    echo -e "\n--- 交互模式: 配置反向代理 ---"
    echo "请按提示输入参数，或直接按 Enter 使用默认值"
    [[ -z "$you_domain" ]] && read -p "你的域名或者 IP [默认: you.example.com]: " input_you_domain
    [[ -z "$r_domain" ]] && read -p "反代 Emby 前端域名 [默认: r.example.com]: " input_r_domain
    # 可以选择性地为 backend_domain 和 r_path 添加交互输入
    # [[ -z "$backend_domain" ]] && read -p "反代 Emby 后端域名 [默认: backend.example.com]: " input_backend_domain
    # [[ -z "$r_path" ]] && read -p "反代 Emby 后端目标路径 [默认: 空]: " input_r_path

    read -p "你的前端访问端口 [默认: 443]: " input_you_frontend_port
    read -p "反代Emby前端端口 [默认: 空]: " input_r_frontend_port
    read -p "是否使用HTTP连接反代Emby后端? (yes/no) [默认: no]: " input_r_http_backend
    read -p "是否使用HTTP连接反代Emby前端? (yes/no) [默认: no]: " input_r_http_frontend
    read -p "是否禁用TLS? (yes/no) [默认: no]: " input_no_tls

    # 赋值默认值
    you_domain="${input_you_domain:-you.example.com}"
    r_domain="${input_r_domain:-r.example.com}"
    backend_domain="${input_backend_domain:-${backend_domain}}" # 保留命令行或默认值
    r_path="${input_r_path:-${r_path}}" # 保留命令行或默认值
    you_frontend_port="${input_you_frontend_port:-443}"
    r_frontend_port="${input_r_frontend_port}"
    r_http_backend="${input_r_http_backend:-no}"
    r_http_frontend="${input_r_http_frontend:-no}"
    no_tls="${input_no_tls:-no}"
fi


# 美化输出配置信息
protocol=$( [[ "$no_tls" == "yes" ]] && echo "http" || echo "https" )
url="${protocol}://${you_domain}:${you_frontend_port}"

echo -e "\n------ 配置信息 ------"
echo "🌍 访问地址: ${url}"
echo "📌 你的域名: ${you_domain}"
echo "🖥️ 你的前端访问端口: ${you_frontend_port}"
echo "🔄 反代 Emby 前端域名: ${r_domain}"
echo "🔧 反代 Emby 后端域名: ${backend_domain}"
echo "└─ 路径: ${r_path:-/ (根目录)}" # 新增: 显示后端路径
echo "🎯 反代 Emby 前端端口: ${r_frontend_port:-未指定}"
echo "🔗 使用 HTTP 连接反代 Emby 后端: $( [[ "$r_http_backend" == "yes" ]] && echo "✅ 是" || echo "❌ 否" )"
echo "🛠️  使用 HTTP 连接反代 Emby 前端: $( [[ "$r_http_frontend" == "yes" ]] && echo "✅ 是" || echo "❌ 否" )"
echo "🔒 禁用 TLS: $( [[ "$no_tls" == "yes" ]] && echo "✅ 是" || echo "❌ 否" )"
echo "----------------------"

check_dependencies() {
  # ... (check_dependencies 函数保持不变) ...
  if [[ ! -f '/etc/os-release' ]]; then
    echo "error: Don't use outdated Linux distributions."
    return 1
  fi
  source /etc/os-release
  if [ -z "$ID" ]; then
      echo -e "Unsupported Linux OS Type"
      exit 1
  fi

  case "$ID" in
  debian|devuan|kali)
      OS_NAME='debian'
      PM='apt'
      GNUPG_PM='gnupg2'
      ;;
  ubuntu)
      OS_NAME='ubuntu'
      PM='apt'
      GNUPG_PM=$([[ ${VERSION_ID%%.*} -lt 22 ]] && echo "gnupg2" || echo "gnupg")
      ;;
  centos|fedora|rhel|almalinux|rocky|amzn)
      OS_NAME='rhel'
      PM=$(command -v dnf >/dev/null && echo "dnf" || echo "yum")
      ;;
  arch|archarm)
      OS_NAME='arch'
      PM='pacman'
      ;;
  alpine)
      OS_NAME='alpine'
      PM='apk'
      ;;
  *)
      OS_NAME="$ID"
      PM='apt'
      ;;
  esac
}

check_dependencies

# 检查并安装 Nginx
# ... (Nginx 安装逻辑保持不变) ...
echo "检查 Nginx 是否已安装..."
if ! command -v nginx &> /dev/null; then
    echo "Nginx 未安装，正在安装..."

    if [[ "$OS_NAME" == "debian" || "$OS_NAME" == "ubuntu" ]]; then
      $PM install -y "$GNUPG_PM" ca-certificates lsb-release "$OS_NAME-keyring" \
        && curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg \
        && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/$OS_NAME `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list \
        && echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx \
        && $PM update && $PM install -y nginx \
        && mkdir -p /etc/systemd/system/nginx.service.d \
        && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf \
        && systemctl daemon-reload && rm -f /etc/nginx/conf.d/default.conf \
        && systemctl enable --now nginx
    elif [[ "$OS_NAME" == "rhel" ]]; then
      $PM install -y yum-utils \
          && echo -e "[nginx-mainline]\nname=NGINX Mainline Repository\nbaseurl=https://nginx.org/packages/mainline/centos/\$releasever/\$basearch/\ngpgcheck=1\nenabled=1\ngpgkey=https://nginx.org/keys/nginx_signing.key" > /etc/yum.repos.d/nginx.repo \
          && $PM install -y nginx \
          && mkdir -p /etc/systemd/system/nginx.service.d \
          && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf \
          && systemctl daemon-reload && rm -f /etc/nginx/conf.d/default.conf \
          && systemctl enable --now nginx
    elif [[ "$OS_NAME" == "arch" ]]; then
      $PM -Sy --noconfirm nginx-mainline \
          && mkdir -p /etc/systemd/system/nginx.service.d \
          && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf \
          && systemctl daemon-reload && rm -f /etc/nginx/conf.d/default.conf \
          && systemctl enable --now nginx
    elif [[ "$OS_NAME" == "alpine" ]]; then
      $PM update && $PM add --no-cache nginx-mainline \
          && rc-update add nginx default && rm -f /etc/nginx/conf.d/default.conf \
          && rc-service nginx start
    else
        echo "不支持的操作系统，请手动安装 Nginx" >&2
        exit 1
    fi
else
    echo "Nginx 已安装，跳过安装步骤。"
fi

# 下载并复制 nginx.conf
echo "下载并复制 nginx 配置文件..."
# 确保下载正确的 nginx.conf，如果脚本作者更新了结构，这里的 URL 可能需要调整
curl -Lo /etc/nginx/nginx.conf https://raw.githubusercontent.com/YilyOu/Emby_nginx_proxy/main/nginx.conf

you_domain_config="$you_domain"
# 注意：原作者仓库可能没有区分前后端的模板了，请确认使用的模板URL正确
# 假设模板名为 p.example.com.conf 或 p.example.com.no_tls.conf
# download_domain_config="p.example.com"
# 示例 URL，请根据实际情况修改为您使用的模板 URL
template_base_url="https://raw.githubusercontent.com/YilyOu/Emby_nginx_proxy/main/conf.d" # 假设的基础URL
template_conf_name="p.example.com.conf" # 默认 HTTPS 模板

if [[ "$no_tls" == "yes" ]]; then
    you_domain_config="$you_domain.$you_frontend_port"
    template_conf_name="p.example.com.no_tls.conf" # 假设 HTTP 模板名
fi

# 下载配置文件模板
echo "下载配置文件模板 $template_conf_name ..."
curl -Lo "$you_domain_config.conf" "${template_base_url}/${template_conf_name}"

# --- 修改配置文件模板 ---

# 1. 替换访问域名 (server_name)
sed -i "s/p.example.com/$you_domain/g" "$you_domain_config.conf"

# 2. 替换监听端口 (listen)
# 注意：模板中监听端口的写法可能不同，需要精确匹配
if [[ -n "$you_frontend_port" && "$you_frontend_port" != "443" && "$no_tls" != "yes" ]]; then
    # 假设 HTTPS 模板监听 "443 ssl http2"
    sed -i "s/listen 443 ssl http2;/listen ${you_frontend_port} ssl http2;/g" "$you_domain_config.conf"
    # 可能还有 IPv6 的监听
    sed -i "s/listen \[::]:443 ssl http2;/listen \[::]:${you_frontend_port} ssl http2;/g" "$you_domain_config.conf"
elif [[ -n "$you_frontend_port" && "$no_tls" == "yes" ]]; then
    # 假设 HTTP 模板监听 "80"
    sed -i "s/listen 80;/listen ${you_frontend_port};/g" "$you_domain_config.conf"
    # 可能还有 IPv6 的监听
    sed -i "s/listen \[::]:80;/listen \[::]:${you_frontend_port};/g" "$you_domain_config.conf"
fi

# 3. 处理反代前端域名 (r_domain) 和端口 (r_frontend_port)
#    这通常用于某些特定的 location 或 rewrite 规则，需要根据模板内容调整
#    假设模板中有类似 proxy_pass https://emby.example.com; 的地方需要修改
frontend_proto="https"
if [[ "$r_http_frontend" == "yes" ]]; then
    frontend_proto="http"
fi
frontend_target="$r_domain"
if [[ -n "$r_frontend_port" ]]; then
    frontend_target="${frontend_target}:${r_frontend_port}"
fi
full_frontend_target="${frontend_proto}://${frontend_target}"

# !!重要!!: 这里的替换需要精确知道模板中前端域名的占位符是什么
# 假设占位符是 "emby.example.com" 并且协议是 https
# 注意：如果模板中有多处使用，这个简单的替换可能不准确
placeholder_frontend_url="https://emby.example.com" # 假设的前端占位符URL
sed -i "s|${placeholder_frontend_url}|${full_frontend_target}|g" "$you_domain_config.conf"


# 4. 处理反代后端域名 (backend_domain) 和路径 (r_path)
#    这通常用于主要的 proxy_pass 指令或特定 location
#    --- 构造后端目标 URL ---
backend_proto="https"
if [[ "$r_http_backend" == "yes" ]]; then
    backend_proto="http"
fi
# 注意：脚本没有为后端指定端口的选项，如果需要，backend_domain 应包含端口，或需添加新选项
backend_addr="$backend_domain"

# 处理路径，确保以 / 开头（如果非空）
target_path="${r_path}"
if [[ -n "$target_path" && ! "$target_path" =~ ^/ ]]; then
    target_path="/${target_path}"
fi

# 构造完整的 proxy_pass 目标
# Nginx proxy_pass 末尾斜杠处理: 如果路径非空，通常建议加上末尾斜杠
if [[ -n "$target_path" && ! "$target_path" =~ /$ ]]; then
    target_path="${target_path}/"
elif [[ -z "$target_path" ]]; then
     # 如果没有指定路径，则使用根路径
     target_path="/"
fi
full_backend_target="${backend_proto}://${backend_addr}${target_path}"
# --- 后端目标 URL 构造完毕 ---

# !!重要!!: 这里的替换需要精确知道模板中后端域名的占位符是什么
# 并且最好使用标记注释来定位 proxy_pass 行
# 假设后端占位符 URL 是 "https://backend.example.com" 并且该行有标记注释
placeholder_backend_url="https://backend.example.com;" # 假设的后端占位符URL(不含标记)
marker="# BACKEND_PROXY_TARGET_MARKER" # 假设的标记注释
placeholder_proxy_pass_regex="proxy_pass ${placeholder_backend_url} ${marker}" # 组合起来用于匹配

# 使用 | 作为 sed 分隔符
sed -i "s|${placeholder_proxy_pass_regex}|proxy_pass ${full_backend_target}; ${marker}|" "$you_domain_config.conf"

# !!清理!!：删除旧的、可能冲突的 sed 命令（如果之前的脚本有的话）
# 例如：sed -i "s/backend.example.com/$backend_domain/g" ...
# 例如：sed -i "s|https://\$website|http://\$website|g" ... (这个 $website 变量来源不明，但其功能应被上述逻辑覆盖)


# --- 修改完成 ---

# 移动配置文件到 /etc/nginx/conf.d/
echo "移动 $you_domain_config.conf 到 /etc/nginx/conf.d/"
# 使用 sudo 确保权限，或者确保脚本以 root 运行
# 统一使用 mv -f 可能更简单，除非 rsync 有特殊目的
mv -f "$you_domain_config.conf" /etc/nginx/conf.d/
# if [[ "$OS_NAME" == "ubuntu" ]]; then
#   rsync -av "$you_domain_config.conf" /etc/nginx/conf.d/
# else
#   mv -f "$you_domain_config.conf" /etc/nginx/conf.d/
# fi

# TLS/acme.sh 相关逻辑
if [[ "$no_tls" != "yes" ]]; then
    ACME_SH="$HOME/.acme.sh/acme.sh"

    # 检查并安装 acme.sh
    echo "检查 acme.sh 是否已安装..."
    if [[ ! -f "$ACME_SH" ]]; then
       echo "acme.sh 未安装，正在安装..."
       # 安装依赖，根据 OS 使用 $PM
       if [[ "$PM" == "apt" ]]; then
         $PM update && $PM install -y socat cron || echo "依赖安装可能失败，请检查！"
       elif [[ "$PM" == "dnf" || "$PM" == "yum" ]]; then
         $PM install -y socat cronie || echo "依赖安装可能失败，请检查！"
         systemctl enable --now crond
       elif [[ "$PM" == "pacman" ]]; then
         $PM -Sy --noconfirm socat cronie || echo "依赖安装可能失败，请检查！"
         systemctl enable --now cronie
       elif [[ "$PM" == "apk" ]]; then
         $PM add socat dcron || echo "依赖安装可能失败，请检查！"
         rc-update add dcron default
       fi
       # 安装 acme.sh (考虑安全性，更推荐手动执行或验证)
       curl https://get.acme.sh | sh
       "$ACME_SH" --upgrade --auto-upgrade
       "$ACME_SH" --set-default-ca --server letsencrypt
    else
       echo "acme.sh 已安装，跳过安装步骤。"
    fi

    # 申请并安装 ECC 证书
    if ! "$ACME_SH" --info -d "$you_domain" | grep -q RealFullChainPath; then
        echo "ECC 证书未申请，正在申请..."
        # 确保目录存在且权限正确
        mkdir -p "/etc/nginx/certs/$you_domain"
        # chown -R your_user:your_group /etc/nginx/certs # 如果非 root 运行 acme.sh 可能需要

        "$ACME_SH" --issue -d "$you_domain" --standalone --keylength ec-256 || {
            echo "证书申请失败，请检查错误信息（如防火墙80端口是否开放）！"
            # 考虑是否移除错误的 nginx 配置
            # rm -f "/etc/nginx/conf.d/$you_domain_config.conf"
            exit 1
        }
    else
        echo "ECC 证书已申请，跳过申请步骤。"
    fi

    # 安装证书
    echo "安装证书..."
    "$ACME_SH" --install-cert -d "$you_domain" --ecc \
        --fullchain-file "/etc/nginx/certs/$you_domain/cert" \
        --key-file "/etc/nginx/certs/$you_domain/key" \
        --reloadcmd "nginx -s reload" --force # 确保 nginx 在 PATH 中

    echo "证书安装完成！"
fi

echo "重新加载 Nginx..."
nginx -t && nginx -s reload || echo "Nginx 配置测试失败或重载失败！请检查 /etc/nginx/conf.d/${you_domain_config}.conf 文件和 Nginx 错误日志。"

echo "反向代理设置完成！"
