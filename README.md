# funflix-dev

Funflix 联合开发仓库，通过 Git 子模块固定后端与 Web 界面的版本。

## 项目

| 目录 | 项目 | 说明 |
| --- | --- | --- |
| `apps/funflix` | [funflix](https://github.com/farfarfun/funflix) | 影视资源采集、解析、校验与查询服务 |
| `apps/funflix-web` | [funflix-web](https://github.com/farfarfun/funflix-web) | Web 界面、静态资源服务与后端反向代理 |

具体的安装、配置和开发方式见各子项目 README。

## 获取代码

首次克隆时同时拉取子模块：

```bash
git clone --recurse-submodules https://github.com/farfarfun/funflix-dev.git
cd funflix-dev
```

已有仓库可执行：

```bash
git submodule update --init --recursive
```

## 更新子模块

```bash
git submodule update --remote
git add apps/funflix apps/funflix-web
```

更新后的子模块提交由当前仓库记录，需要随父仓库一起提交。

## 构建

安装并配置好 `funbuild` 后执行：

```bash
bash scripts/build.sh
```

脚本会依次构建 `funflix` 和 `funflix-web`，最后执行 `funbuild push`。
