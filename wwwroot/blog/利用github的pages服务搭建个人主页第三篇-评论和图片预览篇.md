# 利用github的pages服务搭建个人主页第三篇-评论和图片预览篇

这里测试一下评论功能


<template>
<Giscus
    id="comments"
    repo="codemyhappy/codemyhappy.github.io"
    repoId="R_kgDOIr5QXA"
    category="Announcements"
    categoryId="DIC_kwDOIr5QXM4C_T_S"
    mapping="pathname"
    reactionsEnabled="1"
    emitMetadata="1"
    inputPosition="top"
    theme="catppuccin_latte"
    crossorigin="anonymous"
    lang="zh-CN"
    strict="0"
/>
</template>

<script setup>
    import Giscus from '@giscus/vue';
</script>
