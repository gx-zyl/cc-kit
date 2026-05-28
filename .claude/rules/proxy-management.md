# 代理管理

- 默认不启用 `HTTP_PROXY` / `HTTPS_PROXY`
- 需要访问外网时临时启用：
  ```pwsh
  $env:HTTP_PROXY = 'http://127.0.0.1:9910'
  $env:HTTPS_PROXY = 'http://127.0.0.1:9910'
  ```
- 用完即时取消：
  ```pwsh
  Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY
  ```
- 浏览器走 PAC 自动分流（`proxy.pac`），不依赖环境变量
- marketplace 操作（`claude plugin marketplace update`、`claude plugin install`、`claude plugin tag --push` 等）涉及 GitHub 访问，需临时启用代理
- `claude plugin marketplace update` 会 `git fetch` 但**不会**自动 checkout 最新 tag，导致插件版本号解析停滞。发版后手动补一步：
  ```pwsh
  cd "$env:USERPROFILE\.claude\plugins\marketplaces\cc-kit"
  git fetch --tags origin
  git checkout cc-kit--v{version}
  ```
  或用 `/workflow release version=x.y.z` 一键发布。
