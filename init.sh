#!/usr/bin/env bash
# 一键初始化并更新所有子模块
# 用法:
#   ./init.sh            按 .gitmodules 中记录的 commit 检出子模块
#   ./init.sh --latest   拉取子模块远端主分支最新代码
set -euo pipefail

cd "$(dirname "$0")"

echo "==> 初始化并更新子模块..."
git submodule update --init --recursive

if [[ "${1:-}" == "--latest" ]]; then
    echo "==> 拉取子模块最新代码..."
    git submodule foreach '
        branch=$(git remote show origin 2>/dev/null | sed -n "s/.*HEAD branch: //p")
        branch=${branch:-main}
        git checkout "$branch" && git pull origin "$branch"
    '
fi

echo "==> 完成。当前子模块状态:"
git submodule status
