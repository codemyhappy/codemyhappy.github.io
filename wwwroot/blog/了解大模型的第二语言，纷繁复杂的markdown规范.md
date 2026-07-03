# 了解大模型的第二语言，纷繁复杂的 Markdown 规范

## 前言

如果你经常和 ChatGPT、Claude 等大语言模型打交道，你会发现它们最擅长输出的格式就是 Markdown。无论是写代码、列清单、做表格，还是写一篇完整的文章，Markdown 几乎成了大模型与人类之间的"第二语言"。

但 Markdown 有一个"历史遗留问题"——它从来没有一个真正统一的官方标准。从 John Gruber 在 2004 年发布最初的 Markdown 语法以来，各路实现者根据自己的需求不断扩展，衍生出了十几种不同的规范。这就导致了一个尴尬的局面：同一份 Markdown 源码，在不同的渲染器下可能呈现出完全不同的效果。

本文将带你梳理主流的 Markdown 规范，分析不同前端（渲染器）的处理差异，并给出让 Markdown 源码跨规范保持一致的实用建议。

## 一、主流 Markdown 规范概览

### 1. CommonMark

- **官方规范**：[https://spec.commonmark.org](https://spec.commonmark.org)
- **GitHub 仓库**：[https://github.com/commonmark/commonmark-spec](https://github.com/commonmark/commonmark-spec)

CommonMark 是 Markdown 社区为了终结碎片化而发起的一个标准化项目。它定义了一套严格、无歧义的规范，并提供了官方测试套件。

- **特点**：语法严格、行为可预测、有完整的规范文档
- **典型实现**：`cmark`（C 语言参考实现）、`markdown-it`（默认模式）、`remark`（基于 AST 的解析器）
- **适用场景**：追求标准化的通用场景

CommonMark 解决了很多原始 Markdown 的歧义问题，比如：

```markdown
**加粗*部分加粗*部分加粗**
```

在原始 Markdown 中，这段代码的行为是不确定的。CommonMark 明确规定了嵌套强调的解析规则。

#### CommonMark 的核心设计原则

CommonMark 之所以重要，是因为它解决了原始 Markdown 中大量"未定义行为"的问题。以下是它的一些关键设计：

**（1）明确的优先级规则**

CommonMark 定义了严格的块级元素优先级。例如，一个 `>` 开头的行到底是引用还是普通文本？CommonMark 规定：如果一行以 `>` 开头且后面跟一个空格，它就是块引用；如果 `>` 后面紧跟非空格字符，则 `>` 被视为普通文本。

```markdown
> 这是引用

>这不是引用，>是普通文本
```

**（2）容器块与叶块的分层结构**

CommonMark 将块级元素分为两类：

- **容器块**（Container blocks）：可以包含其他块，如块引用（`>`）、列表项（`-`/`*`/`1.`）
- **叶块**（Leaf blocks）：不能包含其他块，如段落、标题、代码块、水平线

这种分层结构让解析器可以递归处理嵌套结构，行为非常清晰。

**（3）列表的严格规则**

原始 Markdown 中列表的缩进和嵌套规则非常模糊。CommonMark 明确规定了：

- 列表项的缩进从标记符（`-`、`*`、`1.`）后的第一个非空格字符开始计算
- 有序列表的起始数字有意义（`3. 条目` 会从 3 开始编号）
- 列表项可以包含多个段落，但后续段落必须缩进

```markdown
- 第一项

  这是第一项的第二个段落（缩进 2 空格或更多）

- 第二项
```

**（4）信息字符串（Info String）**

CommonMark 的围栏代码块支持信息字符串（通常用于标注语言），但规范明确规定信息字符串仅作为元数据，渲染器可以选择忽略或使用它。


**（5）实体和字符引用**

CommonMark 支持 HTML 实体（`&`）和数字字符引用（`&#60;`），并规定了它们在行内代码和代码块中的转义行为。

#### CommonMark 的局限性

CommonMark 虽然解决了标准化问题，但它有意保持"最小化"——只包含最核心的语法，不包含表格、任务列表、删除线、脚注等实用扩展。这意味着：

- CommonMark 本身不适合直接用于内容创作（缺少太多实用功能）
- 它更适合作为其他规范的基础层（如 GFM 就是在 CommonMark 之上扩展的）
- 如果你只使用 CommonMark 语法，你的内容在任何平台上都能正确渲染，但功能有限

### 2. GitHub Flavored Markdown (GFM)

- **官方规范**：[https://github.github.com/gfm](https://github.github.com/gfm)
- **GitHub 仓库**：[https://github.com/github/cmark-gfm](https://github.com/github/cmark-gfm)

GFM 是 GitHub 在 CommonMark 基础上扩展的一套规范，是目前使用最广泛的 Markdown 方言之一。

- **特点**：基于 CommonMark，增加了大量实用扩展
- **典型实现**：`cmark-gfm`、`remark-gfm`
- **适用场景**：GitHub、GitLab、GitBook 等代码协作平台

GFM 在 CommonMark 基础上增加了：

- **表格**（Table）：使用 `|` 和 `-` 绘制
- **任务列表**（Task List）：`- [x]` 和 `- [ ]`
- **删除线**（Strikethrough）：`~~文本~~`
- **自动链接**（Autolink）：URL 自动转为可点击链接
- **围栏代码块**（Fenced Code Block）：支持语言标注
- **Emoji**：`:smile:` 简码支持

### 3. Markdown Extra

- **官方文档**：[https://michelf.ca/projects/php-markdown/extra](https://michelf.ca/projects/php-markdown/extra/)

Markdown Extra 是 PHP 生态中流行的扩展规范，由 Michel Fortin 在 2005 年提出。

- **特点**：在原始 Markdown 基础上增加了轻量级扩展
- **典型实现**：PHP Markdown Extra、Python-Markdown（extra 扩展）
- **适用场景**：WordPress、Drupal 等 CMS 系统

主要扩展包括：

- **表格**（与 GFM 类似但语法略有差异）
- **脚注**（Footnote）：`[^1]` 语法
- **定义列表**（Definition List）
- **缩写**（Abbreviation）
- **围栏代码块**（早期实现之一）

### 4. Pandoc Markdown

- **官方文档**：[https://pandoc.org/MANUAL.html#pandocs-markdown](https://pandoc.org/MANUAL.html#pandocs-markdown)

Pandoc 是一个文档格式转换工具，它定义了自己的一套 Markdown 方言，几乎是最全功能的 Markdown 规范。

- **特点**：功能极其丰富，支持多种输出格式
- **典型实现**：Pandoc
- **适用场景**：文档格式转换、学术出版

Pandoc Markdown 支持：

- **YAML 元数据块**
- **数学公式**（多种语法）
- **脚注**、**引文**、**参考文献**
- **表格**（多种风格：简单表、网格表、管道表）
- **围栏代码块**（带属性）
- **原始 HTML/LaTeX 内联**
- **目录**、**图表标题**、**交叉引用**

### 5. Obsidian Flavored Markdown

- **官方文档**：[https://help.obsidian.md/Editing+and+formatting/Obsidian+Flavored+Markdown](https://help.obsidian.md/Editing+and+formatting/Obsidian+Flavored+Markdown)

Obsidian 作为目前最流行的知识管理工具，也发展出了自己的 Markdown 方言。

- **特点**：强调双向链接和知识图谱
- **典型实现**：Obsidian 内置渲染器
- **适用场景**：个人知识管理、笔记系统

特色语法：

- **Wiki 链接**：`[[笔记名]]` 双向链接
- **块引用**：`^block-id`
- **Callout**：`> [!note]` 提示块
- **Mermaid 图表**：内建支持
- **LaTeX 数学**：`$...$` 和 `$$...$$`
- **标签**：`#tag` 语法

### 6. VuePress / VitePress Markdown

- **VitePress 文档**：[https://vitepress.dev/guide/markdown](https://vitepress.dev/guide/markdown)
- **VuePress 文档**：[https://vuepress.vuejs.org/guide/markdown](https://vuepress.vuejs.org/guide/markdown)

VuePress 和 VitePress 是 Vue 生态的静态站点生成器，它们基于 markdown-it 做了大量扩展。

- **特点**：面向文档站点，支持 Vue 组件嵌入
- **典型实现**：VuePress、VitePress
- **适用场景**：技术文档、个人博客

特色功能：

- **Frontmatter**：YAML 头部元数据
- **自定义容器**：`::: tip`、`::: warning` 等
- **代码组**（Code Group）：Tab 切换代码块
- **Vue 组件内嵌**：在 Markdown 中直接使用 Vue 组件
- **图片优化**：自动缩放、懒加载
- **目录**：`[[toc]]` 语法

## 二、Markdown 编辑器与渲染引擎

除了规范本身，实际开发中我们接触更多的是各种 Markdown 编辑器和渲染引擎。它们有的基于规范实现，有的自创了一套解析体系。了解它们的工作原理，有助于我们理解 Markdown 在不同场景下的行为差异。

### 1. markdown-it

- **GitHub 仓库**：[https://github.com/markdown-it/markdown-it](https://github.com/markdown-it/markdown-it)

markdown-it 是目前最流行的 JavaScript Markdown 解析器之一，也是 VuePress、VitePress 等工具的底层引擎。

- **特点**：速度快、插件生态丰富、严格遵循 CommonMark
- **默认模式**：严格 CommonMark 模式
- **扩展方式**：通过插件机制添加语法支持

markdown-it 的架构非常清晰：

```
Markdown 源码 → Parser（解析为 Token 流） → Renderer（渲染为 HTML）
```

它支持通过插件在解析阶段注入自定义规则，比如：

- `markdown-it-table`：表格支持
- `markdown-it-emoji`：Emoji 支持
- `markdown-it-tex`：数学公式支持
- `markdown-it-footnote`：脚注支持

**使用示例**：

```javascript
const md = require('markdown-it')();
const result = md.render('# Hello World');
// <h1>Hello World</h1>
```

**开启 GFM 模式**：

```javascript
const md = require('markdown-it')({
  html: true,
  linkify: true,
  typographer: true
});
```

### 2. MDEditor v3

- **GitHub 仓库**：[https://github.com/imzbf/md-editor-v3](https://github.com/imzbf/md-editor-v3)

MDEditor v3 是一个基于 Vue 3 的 Markdown 编辑器组件，是目前 Vue 生态中最流行的 Markdown 编辑器之一。

- **特点**：Vue 3 原生、TypeScript 支持、主题可定制
- **底层引擎**：默认使用 markdown-it，可切换为其他解析器
- **适用场景**：Vue 3 项目中的 Markdown 编辑功能

MDEditor v3 支持：

- **双栏编辑**：左侧编辑、右侧实时预览
- **工具栏**：丰富的快捷插入按钮（表格、代码块、图片、链接等）
- **主题切换**：内置亮色/暗色主题
- **自定义扩展**：支持自定义工具栏按钮和渲染规则
- **代码高亮**：内置代码语法高亮
- **图片上传**：支持拖拽/粘贴上传，可自定义上传处理函数

**使用示例**：

```vue
<template>
  <MdEditor v-model="text" />
</template>

<script setup>
import { ref } from 'vue'
import { MdEditor } from 'md-editor-v3'
import 'md-editor-v3/lib/style.css'

const text = ref('# Hello World')
</script>
```

它的核心设计是"编辑与预览分离"——编辑区保持纯文本，预览区通过 markdown-it 渲染为 HTML。这种模式的好处是源码清晰可控，但缺点是无法做到真正的"所见即所得"（比如表格编辑时无法直观看到对齐效果）。

### 3. Notion

Notion 是目前最流行的全能型笔记和协作工具，但它**不是**一个 Markdown 编辑器——它有自己的块级编辑器（Block-based Editor），只是**兼容 Markdown 的输入和输出**。

- **特点**：块级编辑、数据库驱动、Markdown 导入/导出
- **底层引擎**：自研的块级渲染引擎
- **Markdown 支持方式**：输入时识别 Markdown 语法并转换为块，导出时渲染为 Markdown

**Notion 的 Markdown 处理逻辑**：

```
输入 Markdown 语法 → 识别为块操作 → 存储为 Notion 内部数据结构
导出 Notion 页面 → 将块结构渲染为 Markdown 文本
```

这意味着：

- 在 Notion 中输入 `# 标题` 会立即转换为标题块，不再是纯文本
- 从 Notion 导出的 Markdown 可能包含 Notion 特有的块结构标记
- 导入 Markdown 到 Notion 时，部分复杂语法可能丢失

**支持的 Markdown 语法**：

| 语法 | 支持情况 |
|------|---------|
| `#` 标题 | ✅ 转换为标题块 |
| `**` 加粗 | ✅ |
| `*` 斜体 | ✅ |
| `` ` `` 行内代码 | ✅ |
| ``` 代码块 | ✅ |
| `-` 无序列表 | ✅ |
| `1.` 有序列表 | ✅ |
| `[]` 任务列表 | ✅ |
| `|` 表格 | ⚠️ 导入支持有限 |
| `~~` 删除线 | ✅ |
| `>` 引用 | ✅ 转换为引用块 |

### 4. TipTap

- **官方文档**：[https://tiptap.dev](https://tiptap.dev)
- **GitHub 仓库**：[https://github.com/ueberdosis/tiptap](https://github.com/ueberdosis/tiptap)

TipTap 是一个基于 ProseMirror 的富文本编辑器框架，它代表了 Markdown 编辑的另一种思路——**不直接编辑 Markdown 源码，而是编辑渲染后的富文本，再序列化为 Markdown**。

#### TipTap 的架构

```
用户操作（输入/粘贴/拖拽）
    ↓
ProseMirror 状态管理（维护文档的 JSON 数据结构）
    ↓
视图层渲染（DOM 更新）
    ↓
序列化（将 JSON 结构输出为 Markdown / HTML / 其他格式）
```

这种架构的核心优势是：**用户看到的就是最终结果**，不存在"源码 vs 预览"的认知鸿沟。

#### TipTap 如何支持 Markdown

TipTap 对 Markdown 的支持分为三个层面：

**（1）输入时：Markdown 快捷输入（Input Rules）**

TipTap 通过 ProseMirror 的 Input Rules 机制，在用户输入时实时识别 Markdown 语法并转换为富文本节点：

```javascript
// 例如：输入 "# " 自动转换为标题
import { Heading } from '@tiptap/extension-heading'

// 输入 "> " 自动转换为块引用
import { Blockquote } from '@tiptap/extension-blockquote'

// 输入 "**text**" 自动转换为加粗
import { Bold } from '@tiptap/extension-bold'

// 输入 "```" 自动转换为代码块
import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight'
```

这意味着用户在 TipTap 中可以直接用 Markdown 语法快速输入，但最终存储的是结构化的 JSON 数据，而不是 Markdown 文本。

**（2）粘贴时：Paste Rules**

当用户从外部复制 Markdown 文本粘贴到 TipTap 编辑器时，TipTap 会解析 Markdown 并转换为内部节点结构：

```javascript
// 开启 Markdown 粘贴支持
import { Markdown } from 'tiptap-markdown'

const editor = new Editor({
  extensions: [
    StarterKit,
    Markdown.configure({
      html: true,        // 允许 HTML
      tightLists: true,  // 紧凑列表
    }),
  ],
})
```

**（3）序列化/反序列化：Markdown 导入导出**

TipTap 可以将内部文档结构序列化为 Markdown 文本，也可以将 Markdown 文本反序列化为内部结构：

```javascript
// 导出为 Markdown
const markdown = editor.storage.markdown.getMarkdown()

// 从 Markdown 导入
editor.commands.setContent(markdown)
```

#### TipTap 的 Markdown 扩展生态

TipTap 通过扩展机制支持丰富的 Markdown 语法：

| 扩展 | 功能 | Markdown 语法 |
|------|------|--------------|
| `@tiptap/extension-bold` | 加粗 | `**text**` |
| `@tiptap/extension-italic` | 斜体 | `*text*` |
| `@tiptap/extension-strike` | 删除线 | `~~text~~` |
| `@tiptap/extension-code` | 行内代码 | `` `code` `` |
| `@tiptap/extension-code-block` | 代码块 | ` ``` ` |
| `@tiptap/extension-heading` | 标题 | `#` ~ `######` |
| `@tiptap/extension-blockquote` | 引用 | `>` |
| `@tiptap/extension-bullet-list` | 无序列表 | `-` / `*` |
| `@tiptap/extension-ordered-list` | 有序列表 | `1.` |
| `@tiptap/extension-task-list` | 任务列表 | `- [ ]` / `- [x]` |
| `@tiptap/extension-table` | 表格 | 通过 UI 插入 |
| `@tiptap/extension-image` | 图片 | `![](url)` |
| `@tiptap/extension-link` | 链接 | `[text](url)` |
| `@tiptap/extension-mention` | @提及 | `@user` |
| `@tiptap/extension-emoji` | Emoji | `:smile:` |

#### TipTap vs 传统 Markdown 编辑器的区别

| 特性 | TipTap（富文本模式） | 传统 Markdown 编辑器 |
|------|-------------------|-------------------|
| 编辑方式 | 直接编辑渲染结果 | 编辑源码 + 预览 |
| 数据存储 | JSON 节点树 | Markdown 文本 |
| Markdown 角色 | 输入/输出格式 | 存储格式 |
| 表格编辑 | 可视化拖拽调整 | 手动对齐管道符 |
| 图片处理 | 拖拽上传 | 手动写 URL |
| 复杂排版 | 原生支持 | 需写 HTML 兜底 |

#### TipTap 的适用场景

TipTap 特别适合以下场景：

- **需要富文本编辑体验的应用**：如博客后台、CMS 编辑器、知识库系统
- **非技术用户**：不想学习 Markdown 语法的用户
- **需要结构化数据的场景**：如协同编辑、版本对比、内容复用
- **需要自定义节点**：如嵌入视频、数据库视图、自定义组件

但如果你是一个 Markdown 重度用户，习惯直接编辑源码、用 Git 做版本管理，TipTap 的"黑盒"存储方式可能会让你感到不便——因为最终存储的是 JSON 而不是纯文本 Markdown，无法直接用 `diff` 查看变更。

### 5. 其他值得关注的编辑器

| 编辑器 | 特点 | 底层引擎 | 适用场景 |
|--------|------|---------|---------|
| **StackEdit** | 浏览器端、支持同步到多个平台 | marked | 在线写作 |
| **Typora** | 所见即所得、极简 UI | 自研 | 本地写作 |
| **HackMD / CodiMD** | 实时协同、HackMD 社区版 | markdown-it | 团队协作 |
| **Editor.md** | 老牌 Web 编辑器、功能全面 | marked | Web 应用集成 |
| **ByteMD** | 字节跳动开源、轻量高性能 | 自研 | React 应用 |
| **Milkdown** | 插件化、基于 ProseMirror | ProseMirror | 可定制编辑器 |

## 三、不同规范的核心差异对比

| 特性 | CommonMark | GFM | Markdown Extra | Pandoc | Obsidian | VitePress |
|------|-----------|-----|---------------|--------|----------|-----------|
| 表格 | ❌ | ✅ 管道表 | ✅ 管道表 | ✅ 多种 | ✅ | ✅ |
| 任务列表 | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| 删除线 | ❌ | ✅ `~~` | ❌ | ✅ | ✅ | ✅ |
| 脚注 | ❌ | ❌ | ✅ `[^1]` | ✅ | ✅ | ❌ |
| 数学公式 | ❌ | ❌ | ❌ | ✅ | ✅ `$$` | ✅ `$$` |
| 围栏代码块 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| YAML Frontmatter | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Wiki 链接 | ❌ | ❌ | ❌ | ❌ | ✅ `[[]]` | ❌ |
| Callout | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ `:::` |
| Mermaid | ❌ | ✅ (渲染) | ❌ | ❌ | ✅ | ✅ |
| Emoji 简码 | ❌ | ✅ `:smile:` | ❌ | ❌ | ❌ | ❌ |
| 自动链接 | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| 定义列表 | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| 原始 HTML | ✅ | ✅ | ✅ | ✅ | 受限 | 受限 |

## 四、不同前端（渲染器）的处理差异

要真正理解不同 Markdown 渲染器之间的差异，最好的方式是自己动手对比。以下是一些在线 Markdown 预览工具，你可以复制同一段 Markdown 源码到不同工具中，直观地观察渲染结果的差异。

### 在线预览工具

| 工具 | 底层引擎 | 链接 |
|------|---------|------|
| **CommonMark Dingus** | cmark（CommonMark 官方参考实现） | [https://spec.commonmark.org/dingus](https://spec.commonmark.org/dingus/) |
| **GitHub GFM 预览** | cmark-gfm | 在任意 GitHub Issue 或 PR 的评论框中输入 |
| **markdown-it 演示** | markdown-it | [https://markdown-it.github.io](https://markdown-it.github.io/) |
| **MDEditor v3 在线演示** | markdown-it | [https://imzbf.github.io/md-editor-v3/zh-CN](https://imzbf.github.io/md-editor-v3/zh-CN/) |
| **Yaniv Editor 演示** | 自研 | [https://yanivwang.github.io/yaniv-editor/examples/#/full-editor](https://yanivwang.github.io/yaniv-editor/examples/#/full-editor) |
| **StackEdit** | marked / markdown-it（可切换） | [https://stackedit.io](https://stackedit.io/) |
| **HackMD** | markdown-it | [https://hackmd.io](https://hackmd.io/) |

### 建议对比的测试用例

你可以将以下 Markdown 片段依次粘贴到上述工具中，观察差异：

**测试 1：表格与对齐**

```markdown
| 左对齐 | 居中 | 右对齐 |
| :----- | :--: | ----: |
| A      |  B   |     C |
```

👉 在 CommonMark Dingus 中不会渲染为表格（CommonMark 不支持），在 GFM 和 markdown-it 演示中则正常渲染。注意对齐样式在不同工具中的表现差异。

**测试 2：换行规则**

```markdown
第一行
第二行

第一行

第二行
```

👉 在 CommonMark Dingus 中，直接换行会被合并为空格。在 GFM 中，直接换行会变为 `<br>`（软换行）。这会导致排版间距完全不同。

**测试 3：删除线**

```markdown
~~这段文字被删除了~~
```

👉 CommonMark Dingus 中显示为普通文本 `~~...~~`。GFM 和 markdown-it（开启 GFM 模式）中会渲染为带删除线的文本。

**测试 4：任务列表**

```markdown
- [x] 已完成
- [ ] 未完成
```

👉 CommonMark Dingus 中 `[x]` 被当作普通文本。GFM 中渲染为可交互的 checkbox。

**测试 5：数学公式**

```markdown
行内公式 $E = mc^2$

块级公式：

$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$
```

👉 CommonMark Dingus 中 `$...$` 原样输出。GFM 会识别并用 `<code>` 包裹。大多数在线工具需要安装插件才能正确渲染数学公式。

**测试 6：原始 HTML**

```markdown
<div style="color: red">红色文字</div>

<span style="color: blue">蓝色</span>
```

👉 CommonMark 和 GFM 中块级 HTML 保持原样，行内 HTML 会被 `<p>` 包裹。部分工具（如某些富文本编辑器）会过滤掉原始 HTML。

**测试 7：标题锚点**

```markdown
## 我的标题
[跳转](#我的标题)
```

👉 在 GFM 中，标题会自动生成锚点 ID，但通常带有 `user-content-` 前缀。在 markdown-it 中，锚点 ID 直接使用标题文本。你可以查看页面 HTML 源码观察差异。

### 关键差异速查表

| 特性 | CommonMark | GFM | markdown-it（默认） | TipTap |
|------|-----------|-----|-------------------|--------|
| 表格 | ❌ 不渲染 | ✅ 原生 | ❌ 需插件 | ✅ 节点序列化 |
| 删除线 | ❌ 原样 | ✅ `<del>` | ❌ 需插件 | ✅ Input Rule |
| 任务列表 | ❌ 原样 | ✅ checkbox | ❌ 需插件 | ✅ 扩展节点 |
| 换行规则 | 合并为空格 | 变 `<br>` | 合并为空格 | 键盘事件 |
| 原始 HTML | ✅ 允许 | ✅ 允许 | ✅ 可关闭 | ❌ 屏蔽 |
| 数据存储 | Markdown 文本 | Markdown 文本 | Markdown 文本 | JSON 节点树 |

## 五、跨规范保持一致的实战建议

### 1. 以 CommonMark 为基础，谨慎使用扩展语法

CommonMark 是所有现代 Markdown 渲染器的基础。如果你的内容需要在多个平台发布，**优先使用 CommonMark 核心语法**，只在确定目标平台支持时才使用扩展语法。

**推荐做法**：

````
# ✅ 通用语法（CommonMark 安全）

**加粗**
*斜体*
`行内代码`
> 引用

```python
# 围栏代码块
print("hello")
```

- 无序列表
1. 有序列表

[链接](https://example.com)
![图片](image.png)

---

# ⚠️ 条件使用（确认平台支持）

| 表格 | 语法 |
| ---- | ---- |

- [ ] 任务列表

~~删除线~~

> [!note] Callout
````

### 2. 表格：使用最简语法

表格是跨平台兼容性最差的语法之一。建议：

- **前后保留空行**（兼容性最好）
- **使用管道表（Pipe Table）**，这是最广泛支持的表格语法
- **不要依赖对齐功能**，很多平台不支持
- **表格内容保持简洁**，避免在表格中使用复杂 Markdown

```markdown
<!-- ✅ 推荐的跨平台表格写法 -->

| 名称 | 版本 | 说明 |
| --- | --- | --- |
| CommonMark | 0.31 | 标准化规范 |
| GFM | 1.0 | GitHub 扩展 |
```

### 3. 图片：使用图床 + 相对路径双保险

对于需要跨平台发布的场景：

- **使用图床**（如 GitHub 仓库、阿里云 OSS、Cloudflare R2 等）存放图片
- **在 Markdown 中使用完整 URL**，而不是相对路径
- **如果必须用相对路径**，确保所有平台对路径的解析规则一致

```markdown
<!-- ✅ 跨平台最安全 -->
![示意图](https://cdn.example.com/images/diagram.png)

<!-- ⚠️ 仅在特定平台有效 -->
![示意图](./images/diagram.png)
```

### 4. 数学公式：使用 `$$` 块级语法

如果需要在支持数学公式的平台间迁移：

- **使用 `$$...$$` 块级语法**，比 `$...$` 歧义更少
- **避免在行内使用 `$...$`**，除非确定目标平台支持
- **考虑使用图片替代复杂公式**，作为兜底方案

```markdown
<!-- ✅ 推荐的数学公式写法 -->

$$
E = mc^2
$$

<!-- ⚠️ 行内公式可能被误解 -->
行内公式 $E = mc^2$ 在某些平台会失效。
```

### 5. 脚注：使用替代方案

由于脚注在 GFM 和 CommonMark 中不支持，建议：

- **使用行内括号注释**代替脚注：`（详见附录 A）`
- **使用超链接**代替脚注引用：`[详见此文](https://example.com)`
- **在文末统一用列表列出参考信息**

```markdown
<!-- ✅ 跨平台替代方案 -->
这是一段需要说明的文字（详见参考资料[1]）。

---

**参考资料：**

[1] Markdown 规范文档，https://spec.commonmark.org
```

### 6. 删除线：用文字表达代替

```markdown
<!-- ❌ 不跨平台 -->
~~这个功能已废弃~~

<!-- ✅ 跨平台 -->
<del>这个功能已废弃</del>（已废弃）
```

使用 `<del>` HTML 标签比 `~~` 语法兼容性更好，因为几乎所有 Markdown 渲染器都允许内联 HTML。

### 7. 任务列表：用列表 + 文字代替

```markdown
<!-- ❌ 不跨平台 -->
- [x] 已完成
- [ ] 未完成

<!-- ✅ 跨平台 -->
- ✅ 已完成
- ⬜ 未完成
```

使用 Emoji 符号代替任务列表的复选框，在所有平台上都能正确显示。

### 8. 换行：统一使用空行分段

```markdown
<!-- ✅ 跨平台推荐 -->
这是第一段。

这是第二段，与第一段之间有空行。

<!-- ❌ 行为不一致 -->
这是第一行。
这是第二行，在 GFM 中会换行，在 CommonMark 中不会。
```

**最佳实践**：段落之间始终使用空行分隔。需要换行但不分段时，使用 `<br>` HTML 标签。

### 9. 使用标准化工具进行检测

推荐使用以下工具来检查 Markdown 的兼容性：

- **[markdownlint](https://github.com/DavidAnson/markdownlint)**：VS Code 插件，可配置规则检查 CommonMark 兼容性
- **[remark-lint](https://github.com/remarkjs/remark-lint)**：基于 remark 的 Markdown 检查工具
- **[CommonMark 规范测试](https://spec.commonmark.org/dingus/)**：在线测试你的 Markdown 是否符合 CommonMark 规范

**推荐的 markdownlint 配置**：

```json
{
  "MD001": true,
  "MD003": { "style": "atx" },
  "MD007": { "indent": 2 },
  "MD009": false,
  "MD012": true,
  "MD022": true,
  "MD024": false,
  "MD026": false,
  "MD032": true,
  "MD033": false,
  "MD036": false,
  "MD041": false
}
```

### 10. 建立自己的 Markdown 风格指南

对于团队或个人长期维护的内容，建议建立一份 Markdown 风格指南，明确：

1. **标题**：使用 ATX 风格（`#`）还是 Setext 风格（`===`）？推荐 ATX。
2. **列表**：无序列表使用 `-`、`*` 还是 `+`？推荐 `-`。
3. **代码块**：使用围栏代码块，标注语言。
4. **图片**：统一使用图床 URL。
5. **表格**：使用管道表，前后空行。
6. **引用**：每行一个 `>` 还是只在段落开头使用？推荐每行一个。
7. **空行**：块级元素前后保留空行。

## 六、总结

Markdown 的碎片化是一个历史遗留问题，短期内不可能完全解决。但作为内容创作者，我们可以通过以下策略来应对：

| 策略 | 适用场景 | 成本 |
|------|---------|------|
| **以 CommonMark 为子集** | 多平台通用内容 | 低，但功能受限 |
| **为目标平台定制** | 单平台发布 | 低，但不可迁移 |
| **使用抽象层工具** | 多平台发布 | 中，需额外工具 |
| **建立风格指南 + 自动化检查** | 团队协作 | 中高，但长期收益大 |

对于大多数场景，我的建议是：

1. **核心内容用 CommonMark 语法**，确保在任何平台都能正确显示
2. **扩展语法加注释标记**，方便在特定平台发布时做转换
3. **使用图床管理图片**，避免路径问题
4. **用 CI/CD 工具做格式检查**，在提交前发现兼容性问题
5. **如果使用大模型生成 Markdown**，在 Prompt 中明确指定目标规范

最后，记住一个原则：**Markdown 的初衷是"易读易写"，而不是"功能丰富"**。当你在某个炫酷的扩展语法和跨平台兼容性之间犹豫时，问问自己：这个语法真的让内容更好读了吗？还是只是让渲染效果更花哨？

毕竟，Markdown 之所以能成为大模型的"第二语言"，正是因为它足够简单、足够通用。保持简单，就是保持力量。

