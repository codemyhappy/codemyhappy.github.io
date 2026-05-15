import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  outDir: './docs',
  srcDir: './wwwroot',
  title: "CodeMyHappy",
  description: "private site",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: '首页', link: '/' },
      { text: 'Blogs', link: '/blog/' },
      { text: '关于', link: '/blog/关于我.html' }
    ],

    // sidebar: [
    //   {
    //     text: 'Examples',
    //     items: [
    //       { text: 'Home', link: '/' },
    //       { text: 'Blogs', link: '/blog/' }
    //     ]
    //   }
    // ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/codemyhappy/codemyhappy.github.io' }
    ]
  }
})
