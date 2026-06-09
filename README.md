# CodeMyHappy 个人主页

欢迎来到我的个人技术空间。我在这里分享编程经验、技术思考和项目实践。

访问地址： [https://codemyhappy.github.io/](https://codemyhappy.github.io/)

## 项目特点

- 基于 VitePress 构建的现代化个人主页
- 集成了博客功能，展示技术文章和个人思考
- 响应式布局，支持多设备访问
- 快速的构建和开发体验

## 开始使用

1. 安装依赖：
   ```
   pnpm install
   ```

2. 启动开发服务器：
   ```
   pnpm dev
   ```

3. 访问 http://localhost:9002 查看网站

## 项目结构

```
.
├── .vitepress/             # VitePress 配置目录
├── wwwroot/                # 源代码目录 (VitePress 源文件)
│   ├── blog/               # 博客文章目录
│   │   ├── index.md        # 博客首页
│   │   └── 文章文件...
│   ├── index.md            # 主页文件
│   └── public/             # 静态资源目录
├── docs/                   # 构建输出目录 (GitHub Pages 部署目录)
├── todo-drafts/            # 待发布文章草稿
├── components/             # 博客组件目录
├── deploy.sh               # 自动化部署脚本
├── push-to-remote.sh       # 仅推送到远程仓库，不发版
├── package.json            # 项目配置和脚本
└── README.md              # 项目说明
```

## 开发流程

1. **本地开发**：
   - 修改 [wwwroot]目录下的源文件
   - 运行 `pnpm dev` 启动开发服务器
   - 在浏览器中实时预览更改 (地址为 http://localhost:9002)

2. **添加博客文章**：
   - 在 [wwwroot/blog]目录下创建新的 Markdown 文件
   - 确保文件头部包含适当的元数据

3. **构建项目**：
   - 运行 `pnpm build` 将源文件编译为静态网站
   - 输出文件位于 [docs]目录

## 发版流程

- 运行 `./deploy.sh` 执行自动化部署
- 根据提示输入提交消息
- 脚本会自动构建项目并将结果推送到 GitHub Pages


## 脚本命令

- `pnpm dev` - 启动开发服务器 (端口 9002)
- `pnpm build` - 构建静态网站到 [docs] 目录
- `pnpm serve` - 本地预览构建后的网站
- `./deploy.sh` - 自动构建并部署到 GitHub Pages

## 许可证

本项目使用 MIT 许可证 - 查看 `LICENSE` 文件了解更多详情。