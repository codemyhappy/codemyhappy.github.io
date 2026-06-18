import { h } from 'vue'
import DefaultTheme from 'vitepress/theme'
import CodyMyHappyTheme from './CodyMyHappyTheme.vue'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'doc-after': () => h(CodyMyHappyTheme)
    })
  }
}