---
name: wsl-network
description: WSL 网络工具集 — 获取 Windows 主机 IP、配置 HTTP/SOCKS5 代理、Git 全局代理
tags: [wsl, network, proxy, ip, vpn]
---

# WSL Network

WSL 网络工具集：获取 Windows 主机 IP + 代理配置。

## 触发条件

- WSL、wsl2、网络
- 代理、proxy、代理端口
- VPN、翻墙、fq
- 主机 IP、host ip

## 获取 Windows 主机 IP

```bash
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
```

或通过网关：

```bash
ip route show | grep default | awk '{print $3}'
```

返回值通常是 `172.x.x.x`，下面记为 `WIN_IP`。

## 代理配置

| 配置项 | 值 |
|--------|-----|
| Windows 主机 IP | `$(ip route show default | awk '{print $3}')`（动态获取） |
| SOCKS5 端口 | `9909` |
| HTTP 代理端口 | `9910` |

### 单次使用

```bash
# Git 通过 HTTP 代理
HTTPS_PROXY=http://WIN_IP:9910 git clone https://github.com/user/repo.git

# curl 测试
curl -I --proxy http://WIN_IP:9910 https://www.google.com
curl -I --proxy socks5://WIN_IP:9909 https://www.google.com
```

### 持久化配置

添加到 `~/.bashrc` 或 `~/.zshrc`:

```bash
export HTTPS_PROXY=http://WIN_IP:9910
export ALL_PROXY=socks5://WIN_IP:9909
```

### Git 全局代理

```bash
git config --global http.proxy http://WIN_IP:9910
git config --global https.proxy http://WIN_IP:9910
```

### 验证

```bash
curl -I --proxy http://WIN_IP:9910 https://www.google.com
```
