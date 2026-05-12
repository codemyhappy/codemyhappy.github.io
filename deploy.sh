#!/bin/bash

# 构建和部署Astro项目到GitHub Pages的脚本

# 确保脚本在遇到错误时停止执行
set -e

pnpm install 
pnpm build

# 添加所有更改的文件
git add .

# 获取用户输入的提交消息
echo "请输入源码提交消息："
read -r source_commit_message

if [ -z "$source_commit_message" ]; then
    echo "未提供提交消息，使用默认消息"
    exit
fi

# 提交源码到当前分支（通常是main/master）
git commit -m "$source_commit_message"
echo "源码提交完成！"

# proxy
export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897

# 检查远程仓库是否存在
git push origin main

echo "部署完成！"
echo "访问地址： https://codemyhappy.github.io/"
