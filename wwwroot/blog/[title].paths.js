
import fs from 'fs'
import path from 'path'

const PRE_DEPLOY_ROOT = path.resolve(__dirname)


export default {
  paths() {

    // 获取所有博客
    let pathList = fs.readdirSync(PRE_DEPLOY_ROOT)
    // 过滤出md文件
    .filter(filename=>filename.toLocaleLowerCase().endsWith('.md')&&filename!=='[title].md')
    // 生成标准路径格式
    .map(filename=>{
      return {
        // 页面参数
        params: {
          title: filename.replace('.md',''),
        },
        // 页面md内容
        content: fs.readFileSync(PRE_DEPLOY_ROOT+'/'+filename, 'utf-8')
      }
    })



    // 渲染首页
    pathList.push(renderBlogIndex(pathList))

    return pathList;
  }
}






function renderBlogIndex(pathList){
  const allBlogs = pathList.map(item=>{
    return `- [${item.params.title}](./${item.params.title}.md)`
  });

  return {
      params: {
        title: 'index'
      },
      content: `# 博客

这是我的技术博客页面，记录了我的编程经验、技术思考和项目实践。

## 文章列表

${allBlogs.length===0?'暂无数据':allBlogs.join('\r\n')}
`}
}