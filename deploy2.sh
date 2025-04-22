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
r_path="" # 后端路径变量
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
        -R|--r-path) r_path="$2"; shift 2 ;; # 处理后端路径参数
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

# 交互模式 (如果未提供必要参数)
if [[ -z "$you_domain" || -z "$r_domain" ]]; then
    echo -e "\n--- 交互模式: 配置反向代理 ---"
    echo "请按提示输入参数，或直接按 Enter 使用默认值"
    [[ -z "$you_domain" ]] && read -p "你的域名或者 IP [默认: you.example.com]: " input_you_domain
    [[ -z "$r_domain" ]] && read -p "反代 Emby 前端域名 [默认: r.example.com]: " input_r_domain
    # 可选：为 backend_domain 和 r_path 添加交互输入
    # [[ -z "$backend_domain" ]] && read -p "反代 Emby 后端域名 [默认: ${backend_domain}]: " input_backend_domain
    [[ -z "$r_path" ]] && read -p "反代 Emby 后端目标路径 (例如 /emby) [默认: 空]: " input_r_path

    read -p "你的前端访问端口 [默认: 443]: " input_you_frontend_port
    read -p "反代Emby前端端口 [默认: 空]: " input_r_frontend_port
    read -p "是否使用HTTP连接反代Emby后端? (yes/no) [默认: no]: " input_r_http_backend
    read -p "是否使用HTTP连接反代Emby前端? (yes/no) [默认: no]: " input_r_http_frontend
    read -p "是否禁用TLS? (yes/no) [默认: no]: " input_no_tls

    # 赋值默认值
    you_domain="${input_you_domain:-you.example.com}"
    r_domain="${input_r_domain:-r.example.com}"
    backend_domain="${input_backend_domain:-${backend_domain}}"
    r_path="${input_r_path:-${r_path}}"
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
echo "└─ 路径: ${r_path:-/ (根目录)}" # 显示后端路径
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
  debian|devuan|kali) OS_NAME='debian'; PM='apt'; GNUPG_PM='gnupg2' ;;
  ubuntu) OS_NAME='ubuntu'; PM='apt'; GNUPG_PM=$([[ ${VERSION_ID%%.*} -lt 22 ]] && echo "gnupg2" || echo "gnupg") ;;
  centos|fedora|rhel|almalinux|rocky|amzn) OS_NAME='rhel'; PM=$(command -v dnf >/dev/null && echo "dnf" || echo "yum") ;;
  arch|archarm) OS_NAME='arch'; PM='pacman' ;;
  alpine) OS_NAME='alpine'; PM='apk' ;;
  *) OS_NAME="$ID"; PM='apt' ;;
  esac
}

check_dependencies

# 检查并安装 Nginx
# ... (Nginx 安装逻辑保持不变) ...
echo "检查 Nginx 是否已安装..."
if ! command -v nginx &> /dev/null; then
    echo "Nginx 未安装，正在安装..."
    # ... (根据 $PM 安装 Nginx 的代码) ...
    if [[ "$OS_NAME" == "debian" || "$OS_NAME" == "ubuntu" ]]; then
      $PM update && $PM install -y "$GNUPG_PM" ca-certificates lsb-release "$OS_NAME-keyring" \
        && curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg \
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
      $PM update && <span class="math-inline">PM add \-\-no\-cache nginx\-mainline \\
&& rc\-update add nginx default && rm \-f /etc/nginx/conf\.d/default\.conf \\
&& rc\-service nginx start
else echo "不支持的操作系统，请手动安装 Nginx" \>&2; exit 1; fi
else
echo "Nginx 已安装，跳过安装步骤。"
fi
\# 下载并复制 nginx\.conf \(主配置文件\)
echo "下载并复制 nginx 主配置文件\.\.\."
\# \!\!注意\!\!\: 请确认这个主配置文件 URL 是否正确且必要
curl \-fsSL \-o /etc/nginx/nginx\.conf https\://raw\.githubusercontent\.com/YilyOu/Emby\_nginx\_proxy/main/nginx\.conf
\# 确定 Nginx 站点配置文件名和模板来源
you\_domain\_config\_filename\="</span>{you_domain}.conf" # 默认启用 TLS 的文件名
# !!注意!!: 需要确认模板文件的准确 URL
template_base_url="https://raw.githubusercontent.com/YilyOu/Emby_nginx_proxy/main/conf.d" # 假设的模板目录 URL
template_conf_name="p.example.com.conf" # 假设的 HTTPS 模板名

if [[ "<span class="math-inline">no\_tls" \=\= "yes" \]\]; then
you\_domain\_config\_filename\="</span>{you_domain}.${you_frontend_port}.conf" # 禁用 TLS 的文件名
    template_conf_name="p.example.com.no_tls.conf"
