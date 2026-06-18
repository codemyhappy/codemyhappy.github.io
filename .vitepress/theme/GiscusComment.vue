<script setup>
import { onMounted, ref } from 'vue';

const commentState = ref(1)

onMounted(()=>{
  const script = document.createElement('script');
  script.src = 'https://giscus.app/client.js';
  script.async = true;
  script.crossOrigin = 'anonymous';
  script.setAttribute('data-repo', 'codemyhappy/codemyhappy.github.io');
  script.setAttribute('data-repo-id', 'R_kgDOIr5QXA');
  script.setAttribute('data-category', 'Announcements');
  script.setAttribute('data-category-id', 'DIC_kwDOIr5QXM4C_T_S');
  script.setAttribute('data-mapping', 'title');
  script.setAttribute('data-strict', '0');
  script.setAttribute('data-reactions-enabled', '1');
  script.setAttribute('data-emit-metadata', '0');
  script.setAttribute('data-input-position', 'top');
  script.setAttribute('data-theme', 'preferred_color_scheme');
  script.setAttribute('data-lang', 'zh-CN');
  document.getElementById('code-my-happy-giscus-comment').appendChild(script);
  script.onload = function () {
    console.log('giscus loaded');
    commentState.value = 3;
  };
  script.onerror = function () {
    commentState.value = 2;
  };
})

</script>

<template>
  <div>
      {{ commentState===1 ? '评论加载中...' : '' }}
      {{ commentState===2 ? '评论组件加载失败，刷新重试一下吧' : '' }}
      <div id="code-my-happy-giscus-comment"></div>
  </div>
</template>