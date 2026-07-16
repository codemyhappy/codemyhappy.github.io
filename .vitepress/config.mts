import { defineConfig } from 'vitepress'
import { RssPlugin, RSSOptions } from 'vitepress-plugin-rss'

const RSS: RSSOptions = {
  title: 'CodeMyHappy',
  baseUrl: 'https://codemyhappy.github.io/',
  'language': 'zh-cn',
  'author': {
    name: 'CodeMyHappy',
  },
  'filename': 'rss.xml',
  'ignoreHome': true

}

// https://vitepress.dev/reference/site-config
export default defineConfig({
  outDir: './docs',
  srcDir: './wwwroot',
  title: "CodeMyHappy",
  description: "private site",


  // 主题配置的参考： https://vitepress.dev/zh/reference/default-theme-config
  themeConfig: {
    // 顶部的菜单导航
    nav: [
      { text: '首页', link: '/' },
      { text: 'Blogs', link: '/blog/' },
      { text: '关于', link: '/blog/关于我.html' }
    ],
    // 社交按钮图标，会显示在顶部的nav中
    socialLinks: [
      { icon: 'github', link: 'https://github.com/codemyhappy/codemyhappy.github.io' },
      { icon: 'xiaohongshu', link: 'https://xiaohongshu.com/user/profile/610e50bd00000000010088fd' },
      { icon: 'csdn', link: 'https://blog.csdn.net/qq_21197033' }
    ],

    // 页面的大纲、内容快速定位
    outline:{
      level: 'deep',
      'label': '本面内容导航'
    },

    // sidebar: [
    //   {
    //     text: 'Examples',
    //     items: [
    //       { text: 'Home', link: '/' },
    //       { text: 'Blogs', link: '/blog/' }
    //     ]
    //   }
    // ],



    // 页脚
    // footer: {
    //   message: 'Released under the MIT License.',
    //   copyright: 'Copyright © 2019-present Evan You'
    // },

    // 最后更新时间
    lastUpdated: {
      text: 'Updated at',
      formatOptions: {
        dateStyle: 'full',
        timeStyle: 'medium'
      }
    },
  },
  
  // 插件配置
  vite:{
    plugins: [
      RssPlugin(RSS)
    ]
  },
})
