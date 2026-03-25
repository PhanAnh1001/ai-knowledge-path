# AI Wisdom Battle — Context Dự án

> Cập nhật lần cuối: 2026-03-25 13:18:04
> Session: `unknown`
> Branch: `claude/fix-lightsail-bundle-ipv6`

---

## Trạng thái hiện tại

### Các commit gần nhất

```
c4c2017 Update PROJECT_LOG: 2026-03-25 d90ad423
52f4c64 Update PROJECT_LOG: 2026-03-25 d90ad423
6cb3e60 Fix frontend 404: deploy to production branch + add SPA _redirects
13dc68c Fix deploy security: validate ref_sha, clear git token, docker logout
798b41e Fix deploy: validate secrets before SSH + sync postgres password on rotation
82283ff Fix deploy.yml: replace nested heredoc with echo group to fix YAML parse error
cc11c8f Automate Caddy image build + .env secrets injection via CI/CD
8bdf9fe Fix deploy: only start postgres and app, skip caddy
7ca1c0d Fix deploy: start all services (not --no-deps), increase health check wait
f0d83db Fix docker compose env vars: pass GHCR_REPO/IMAGE_TAG via sudo syntax
e635835 Fix git fetch in deploy: refresh remote URL with current GITHUB_TOKEN
52ffbb8 Add contents: read permission to deploy-backend job
37a62aa Fix git clone URL: use original case GHCR_REPO not lowercased
f7b09f4 Fix git clone auth: use GITHUB_TOKEN in clone URL
cc2569e Fix git clone: combine GIT_TERMINAL_PROMPT=0 and credential.helper=
```

### Thay đổi chưa commit

```
 M .claude/save-discussion.sh
 M .claude/settings.json
```

---

## Ghi chú & Quyết định

<!-- Claude và người dùng ghi chú thủ công vào đây trong quá trình làm việc -->

