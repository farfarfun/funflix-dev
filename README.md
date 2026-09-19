# funflix-dev

Funflix 联合开发仓库，通过 Git 子模块固定后端与 Web 界面的版本。

## 项目

| 目录 | 项目 | 类别 | 说明 |
| --- | --- | --- | --- |
| `apps/funflix` | [funflix](https://github.com/farfarfun/funflix) | package | 核心库：影视资源采集、解析、校验的领域逻辑与 CLI，被 funflix-api 依赖 |
| `apps/funflix-api` | [funflix-api](https://github.com/farfarfun/funflix-api) | service | 后端 API 服务，依赖 funflix 提供的领域逻辑，被 funflix-web 反代 |
| `apps/funflix-web` | [funflix-web](https://github.com/farfarfun/funflix-web) | service | Web 界面、静态资源服务与后端反向代理 |

具体的安装、配置和开发方式见各子项目 README；跨 app 的架构说明见 [`docs/`](docs/)。

## 获取代码

首次克隆时同时拉取子模块：

```bash
git clone --recurse-submodules https://github.com/farfarfun/funflix-dev.git
cd funflix-dev
```

已有仓库可执行：

```bash
bash scripts/init.sh
```

## 更新子模块

```bash
git submodule update --remote
git add apps/funflix apps/funflix-api apps/funflix-web
```

更新后的子模块提交由当前仓库记录，需要随父仓库一起提交。

## 构建

安装并配置好 `funbuild` 后执行：

```bash
bash scripts/build.sh
```

`funbuild build` 会识别本仓库的布局（`apps/` + `scripts/funbuild.toml`），自动按
`scripts/funbuild.toml` 里的共享版本号依次构建、发布 `apps/` 下的每个 app，再统一
提交/推送/打标签本仓库，子模块指针的更新也一并记录进这次提交。

## 服务与发布

```bash
scripts/setup.sh <start|stop|restart|run|status> <api|web|all>
scripts/setup.sh <install-dev|install-prod|upgrade> <api|web|core|all> [version]
scripts/setup.sh rollback <api|web|core|all> <version>
```

`api`/`web` 是常驻服务，接受 service 动作；`core`（`funflix`）是纯 package，没有
自己的进程，只接受 release 动作。缺参数时会弹交互菜单（需要 `gum`）；参数给全就
直接执行。
