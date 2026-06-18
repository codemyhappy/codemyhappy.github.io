import { h } from 'vue'
import DefaultTheme from 'vitepress/theme'
import GiscusComment from './GiscusComment.vue'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'doc-after': () => h(GiscusComment)
    })
  }
}