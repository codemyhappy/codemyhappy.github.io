# 我开发了一个 VSCode 插件《markdown-publisher-for-all》，支持 Markdown 多平台一键发布

作为一个热爱写技术博客的人，我经常需要将自己的文章发布到多个平台上，比如 CSDN、简书、知乎、掘金等。但每次手动复制粘贴内容，再上传图片，不仅效率低下，还容易出错。因此，我决定开发一个 VSCode 插件来解决这个问题。

## 什么是 markdown-publisher-for-all？

markdown-publisher-for-all 是一个基于 VSCode 的博文发布客户端，能够一键将 Markdown 文章发布到多个主流博客平台，无需额外的图床服务。

> 项目由个人独立开发，专注于提高博主们的发布效率。

你可以在 VSCode 插件市场找到它：[markdown-publisher-for-all](https://marketplace.visualstudio.com/items?itemName=brother-xiaohei.markdown-publisher-for-all&ssr=false#overview)

## 主要特性

### 1. 二维码登录
通过扫描二维码快速登录各个平台，免去账号密码的繁琐流程。


### 2. 一键多平台发布
支持将同一篇文章同时发布到多个平台，包括：
- CSDN
- 简书
- 知乎
- 掘金
- 其他主流博客平台


### 3. 图片自动上传
智能识别 Markdown 中的图片链接，并自动上传到对应平台的图床服务，无需手动上传。


## 快速开始

### 初始配置

#### Step 1: 安装 Chrome 浏览器

目前插件仅支持 Chrome 浏览器，你需要：

1. 安装最新版的 Chrome 浏览器
2. 在浏览器地址栏输入 `chrome://version/` 获取浏览器信息
3. 记录下 "Executable Path" 和 "User Data Directory" 的值

#### Step 2: 配置插件设置

在工作区的 [.vscode/settings.json]文件中添加以下配置：

```json
{
    "MarkdownPublisher.ChromeExecutablePath": "你的 Chrome 可执行文件路径",
    "MarkdownPublisher.ChromeUserDataDir": "你的 Chrome 用户数据目录路径"
}
```

### 使用方法

1. 打开一个编写好的 Markdown 文件
2. 在编辑器中右键点击
3. 选择需要发布的目标平台
4. 插件会自动处理内容并发布到相应平台


## 使用技巧

- 在 Markdown 文件头部添加 Front Matter 来设置文章标题、标签和分类
- 插件会自动处理本地图片路径，将其上传到平台图床
- 支持预览模式，可在发布前检查格式

## 更新日志 (Changelog)

### V1.4.0 [Planning]
- 加入思否平台的支持

### V1.3.6 [Released]
- 解决Windows下图片上传的路径问题

### V1.3.2 [Released]
- 掘金平台图片上传流程修改

### V1.3.0 [Released]
- 加入知乎平台的支持

### V1.2.0 [Released]
- 加入掘金平台的支持

### V1.1.0 [Released]
- 加入简书的支持
- 添加配置uploadImageTogether，可控制文章配图是否需要上传

### V1.0.0 [Released]
- 核心功能完成
- 完成对CSDN的一键发文

## 问题反馈

如果你在使用过程中遇到任何问题，或者有功能建议，欢迎到我的 CSDN 博客留言交流。我将持续改进这个工具，为大家提供更好的体验。

## 总结

这个插件解决了我自己的痛点，也希望能帮助更多热爱写作的技术人。让我们专注于创作内容本身，而不是繁琐的发布流程。

> Now, Enjoy!