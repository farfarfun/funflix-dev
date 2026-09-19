#!/usr/bin/env bash
# funflix-dev 跨仓库统一入口：scripts/setup.sh <action> <target> [version]
#
# service 动作（start/stop/restart/run/status）只对 service app 生效（api、web）；
# release 动作（install-dev/install-prod/upgrade/rollback）对 service + package app
# 生效（api、web、core）。build/publish 不归这个脚本管，由仓库根目录的
# `funbuild build`（scripts/build.sh）统一处理。
#
# 三个 app 目前都没有实现 bash-service-guide 标准的 `./scripts/setup.sh <action>`
# 子脚本接口：funflix-api / funflix-web 的服务动作是装好之后的 CLI 子命令
# （`funflix-api <action>` / `funflix-web server <action>`），release 动作按各自
# README 里记录的命令走（funbuild install / pip / npm）。这里如实按现状分发，
# 不假装存在一个统一的子脚本接口——各 app 自己的生命周期脚本改造不归这个仓库管。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

readonly -a SERVICE_ACTIONS=(start stop restart run status)
readonly -a RELEASE_ACTIONS=(install-dev install-prod upgrade rollback)
readonly -a ACTIONS=("${SERVICE_ACTIONS[@]}" "${RELEASE_ACTIONS[@]}")
readonly -a TARGETS=(api web core all)

usage() {
  cat >&2 <<'EOF'
Usage: scripts/setup.sh <start|stop|restart|run|status> <api|web|all>
       scripts/setup.sh <install-dev|install-prod|upgrade> <api|web|core|all> [version]
       scripts/setup.sh rollback <api|web|core|all> <version>

api   = apps/funflix-api  (service app)
web   = apps/funflix-web  (service app)
core  = apps/funflix      (package app，没有常驻进程，不接受 service 动作)
all   按动作分组扩展：service 动作 -> api web；release 动作 -> api web core
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 2
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done
  return 1
}

choose() {
  command -v gum >/dev/null 2>&1 ||
    die "missing argument and gum is unavailable; run with explicit arguments"
  gum choose "$@"
}

is_service_action() {
  contains "$1" "${SERVICE_ACTIONS[@]}"
}

# service app: 有人把它当长驻进程启动。只有这些接受 service 动作。
# 自己在这里登记，永远不要从名字后缀推断（见 rules.md 的 App Category 一节）。
resolve_service_app() {
  case "$1" in
    api) return 0 ;;
    web) return 0 ;;
    *) return 1 ;;
  esac
}

# package app：作为依赖被安装，从不作为自己的进程启动。
resolve_package_app() {
  case "$1" in
    core) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_release_app() {
  resolve_service_app "$1" 2>/dev/null || resolve_package_app "$1" 2>/dev/null
}

run_service_action() {
  local app="$1" action="$2"
  case "${app}" in
    api) funflix-api "${action}" ;;
    web) funflix-web server "${action}" ;;
    *) die "${action} only applies to a service app, not: ${app}" ;;
  esac
}

# pip 包名（core、api）；web 走 npm，单独处理。
pip_package_name() {
  case "$1" in
    core) printf 'funflix\n' ;;
    api) printf 'funflix-api\n' ;;
    *) return 1 ;;
  esac
}

run_release_action() {
  local app="$1" action="$2" version="${3:-}" path pkg
  path="apps/funflix"
  case "${app}" in
    core) path="apps/funflix" ;;
    api) path="apps/funflix-api" ;;
    web) path="apps/funflix-web" ;;
    *) die "${action} does not apply to: ${app}" ;;
  esac

  case "${action}" in
    install-dev)
      if [[ "${app}" == "web" ]]; then
        (cd "${path}" && pnpm install)
      else
        (cd "${path}" && funbuild install)
      fi
      ;;
    install-prod)
      if [[ "${app}" == "web" ]]; then
        npm install -g "funflix-web${version:+@${version}}"
      else
        pkg="$(pip_package_name "${app}")"
        pip install "${pkg}${version:+==${version}}"
      fi
      ;;
    upgrade)
      if [[ "${app}" == "web" ]]; then
        funflix-web upgrade ${version:+"${version}"}
      else
        pkg="$(pip_package_name "${app}")"
        if [[ -n "${version}" ]]; then
          pip install "${pkg}==${version}"
        else
          pip install --upgrade "${pkg}"
        fi
      fi
      ;;
    rollback)
      [[ -n "${version}" ]] || die "rollback requires an explicit version"
      if [[ "${app}" == "web" ]]; then
        funflix-web rollback "${version}"
      else
        pkg="$(pip_package_name "${app}")"
        pip install "${pkg}==${version}"
      fi
      ;;
    *)
      die "unknown release action: ${action}"
      ;;
  esac
}

dispatch_app_action() {
  local action="$1" target="$2" version="${3:-}" app
  local -a apps
  if [[ "${target}" == "all" ]]; then
    if is_service_action "${action}"; then
      apps=(api web)
    else
      apps=(api web core)
    fi
  else
    apps=("${target}")
  fi
  for app in "${apps[@]}"; do
    if is_service_action "${action}"; then
      resolve_service_app "${app}" || die "${action} only applies to a service app, not: ${app}"
      printf '== %s: %s ==\n' "${app}" "${action}"
      run_service_action "${app}" "${action}"
    else
      resolve_release_app "${app}" >/dev/null || die "${action} does not apply to: ${app}"
      printf '== %s: %s ==\n' "${app}" "${action}"
      run_release_action "${app}" "${action}" "${version}"
    fi
  done
}

main() {
  local action="${1:-}"
  local target="${2:-}"
  local version="${3:-}"

  [[ -n "${action}" ]] || action="$(choose "${ACTIONS[@]}")"
  contains "${action}" "${ACTIONS[@]}" || {
    usage
    die "unknown action: ${action}"
  }

  [[ -n "${target}" ]] || target="$(choose "${TARGETS[@]}")"
  contains "${target}" "${TARGETS[@]}" || {
    usage
    die "unknown target: ${target}"
  }

  if [[ "${action}" == "rollback" ]]; then
    [[ -n "${version}" ]] || die "rollback requires an explicit version: ${0##*/} rollback <api|web|core|all> <version>"
  fi

  dispatch_app_action "${action}" "${target}" "${version}"
}

main "$@"
