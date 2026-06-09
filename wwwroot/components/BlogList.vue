<script setup>
import { data } from './BlogList.data.mjs'
const vm = data.filter(item => item.title !== 'index')
console.log('\r\n所有博文列表：',data.map(item=> item.title))
</script>

<template>
  <ul>
    <li v-for="item in vm" :key="item.title">
      <a :href="`./${item.title}`">{{ item.title }}</a>
      <span>上次更新： {{ new Date(item.lastUpdated).toLocaleString() }}</span>
    </li>
  </ul>
</template>

<style scoped>
  span {
    font-size: 12px;
    color: #999;
    padding-left: 24px;
  }
</style>