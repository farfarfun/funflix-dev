# funflix-dev 子模块工作区

## App 组成

| app | 类别 | 仓库 | 作用 |
| --- | --- | --- | --- |
| `apps/funflix` | package | [funflix](https://github.com/farfarfun/funflix) | 领域逻辑核心库：采集、解析、网盘链接校验、数据库迁移，暴露 `funflix` CLI（`collect`/`parse`/`verify`/`worker`/`db ...`），被 `funflix-api` 依赖 |
| `apps/funflix-api` | service | [funflix-api](https://github.com/farfarfun/funflix-api) | 把 `funflix` 的领域逻辑暴露成 HTTP API，常驻进程，`funflix-api start/stop/restart/status/run` |
| `apps/funflix-web` | service | [funflix-web](https://github.com/farfarfun/funflix-web) | Web 界面 + 反向代理，发布为 npm 包，`funflix-web server start/stop/restart/status/run` |

分类依据：谁被当作长驻进程启动就是 service（`api`、`web`），只作为依赖安装、
自己没有进程的就是 package（`core`）。`funflix` 虽然有 CLI，但那是一次性/批处理
命令（CI 里跑完就退出），不是常驻服务，所以归 package。

## 服务依赖方向

```
funflix-web（反代 + 静态资源） --> funflix-api（HTTP API） --> funflix（领域逻辑 + DB）
```

`funflix-web` 从不直接调用 `funflix`；浏览器也从不跨域直连 `funflix-api`——
`funflix-web` 自己的运行时反代 `/api`、`/healthz` 等路径到 `funflix-api`。

## 版本管理

- 三个 app 各自独立版本、独立发布节奏，历史上没有共享同一个版本号
  （`funflix` 0.1.67、`funflix-api` 0.1.3、`funflix-web` 0.1.31）。
- `scripts/funbuild.toml` 声明了本仓库统一维护的共享版本号，`scripts/build.sh`
  （`funbuild build`）以后按这个号统一构建/发布 `apps/` 下的每个 app，并一并
  提交子模块指针更新。

## 跨仓库操作入口

- `scripts/init.sh` — 首次拉取/更新全部子模块。
- `scripts/build.sh` — `exec funbuild build`，构建 + 发布全部 app + 提交指针。
- `scripts/setup.sh <action> <target>` — service 生命周期（`start`/`stop`/
  `restart`/`run`/`status`，仅 `api`/`web`）与 release 动作（`install-dev`/
  `install-prod`/`upgrade`/`rollback`，`api`/`web`/`core`）的统一分发入口，见
  仓库根 README「服务与发布」一节。

`funflix-api`、`funflix-web` 目前没有各自仓库内的 `scripts/setup.sh` 子脚本——
service 动作直接是装好之后的 CLI 子命令，release 动作按各自 README 记录的
`funbuild install`/`pip`/`npm` 命令走。本仓库的 `scripts/setup.sh` 如实按现状
分发到这些命令，没有假装存在一个统一的子脚本接口；把每个 app 的生命周期脚本
改造成 `bash-service-guide` 标准形态是各 app 自己仓库的后续工作，不在本仓库
职责范围内。
