# chrome-devtools-protocol，别名CDP，浏览器自动化知识储备

## 储备的一些学习链接，等我有空再看

- [getting-started-with-cdp](https://github.com/aslushnikov/getting-started-with-cdp/blob/master/README.md)

这是一篇cdp底层的介绍文章，通过socket连接cdp，给cdp发送和接收底层的消息。


- [chromedevtools.github.io/devtools-protocol/](https://chromedevtools.github.io/devtools-protocol/)

这是chrome官方的cdp文档，仅仅是个文档，没有教程。

- [基于CDP的命令行工具 - opencli](https://opencli.info/docs/)

这是一个基于cdp的命令行工具，它的目标是通过cdp将网站变为command命令。

- [基于CDP的高级API - Chrome DevTools 团队维护的Puppeteer](https://github.com/puppeteer/puppeteer)

这是一个基于cdp的高级API，类似于模拟一个浏览器，基于puppeteer可开发很多浏览器自动化项目。

- [如何打开浏览器的CDP监控面板](https://developer.chrome.google.cn/docs/devtools/protocol-monitor?hl=zh-cn)

这是一个打开chrome浏览器自带的cdp监控面板，可以查看所有cdp的请求和响应。

- [适配器func中page的类型定义，是一个非标准的Puppeteer类型](https://github.com/jackwener/OpenCLI/blob/main/src/types.ts)

这是opencli开发adapter的一个类型定义，opencli的adapter开发的文档非常少，这个类型是从其源码中找到的。