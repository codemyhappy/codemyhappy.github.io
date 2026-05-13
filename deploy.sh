#!/bin/bash

# 构建和部署Astro项目到GitHub Pages的脚本

# 确保脚本在遇到错误时停止执行
set -e

# 构建
pnpm build

# 推送到远程仓库
./push-to-remote.sh

echo "部署完成！"
echo "访问地址： https://codemyhappy.github.io/"
