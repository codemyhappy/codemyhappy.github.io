#!/bin/bash

# 构建和部署Astro项目到GitHub Pages的脚本

# 确保脚本在遇到错误时停止执行
set -e

echo "======= 第一步：提交源码到主分支 ======="

# 添加所有更改的文件
git add .

# 获取用户输入的提交消息
echo "请输入源码提交消息："
read -r source_commit_message

if [ -z "$source_commit_message" ]; then
    echo "未提供提交消息，使用默认消息"
    source_commit_message="Update source code"
fi

# 提交源码到当前分支（通常是main/master）
git commit -m "$source_commit_message"
echo "源码提交完成！"

echo ""
echo "======= 第二步：构建并部署到gh-pages分支 ======="

# 安装依赖
pnpm install

# 构建Astro项目
pnpm run build

echo "构建完成！"

# 获取当前分支名
current_branch=$(git branch --show-current)

# 检查是否存在gh-pages分支，如果不存在则创建
if ! git rev-parse --verify gh-pages > /dev/null 2>&1; then
    echo "创建gh-pages分支..."
    git checkout --orphan gh-pages
else
    echo "切换到gh-pages分支..."
    git checkout gh-pages
fi

# 删除除了构建产物以外的所有文件
git rm -rf .
rm -rf .gitignore

# 将dist目录中的内容移动到当前目录
mv dist/* .

# 创建一个空的.gitignore文件，防止意外提交敏感文件
touch .gitignore
echo "node_modules/" >> .gitignore
echo ".env" >> .gitignore
echo "dist/" >> .gitignore

# 提交部署文件
git add .

echo "请输入部署提交消息："
read -r deploy_commit_message

if [ -z "$deploy_commit_message" ]; then
    echo "未提供部署提交消息，使用默认消息"
    deploy_commit_message="Deploy website to GitHub Pages"
fi

git commit -m "$deploy_commit_message"

echo "部署到gh-pages分支完成！"

# 返回之前的分支
if [ "$current_branch" != "" ]; then
    git checkout "$current_branch"
fi

echo ""
echo "======= 部署流程完成 ======="
echo "1. 源码已提交到 $current_branch 分支"
echo "2. 构建产物已提交到 gh-pages 分支"
echo ""

# proxy
export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897

# 检查远程仓库是否存在
git push origin main && git push origin gh-pages


# 返回主分支
git checkout main


echo "部署完成！"
echo "访问地址： https://codemyhappy.github.io/"
