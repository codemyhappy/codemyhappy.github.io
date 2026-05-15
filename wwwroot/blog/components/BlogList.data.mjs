import fs from 'node:fs'

export default {
  watch: ['../*.md'],
  load(watchedFiles) {
    // watchFiles 是一个所匹配文件的绝对路径的数组。
    // 生成一个博客文章元数据数组
    // 可用于在主题布局中呈现列表。
    return watchedFiles
    // 格式标准化
    .map((file) => {
      return {
        title: file.split('/').reverse()?.[0].replace('.md',''),
        content: fs.readFileSync(file, 'utf-8'),
        lastUpdated: fs.statSync(file).mtime.getTime()
      }
    })
    // 排序
    .sort((a,b)=>b.lastUpdated-a.lastUpdated)
  }
}
