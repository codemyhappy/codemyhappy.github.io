<script setup>
import { data } from './BlogList.data.mjs'
const vm = data.filter(item => item.title !== 'index')
console.log(data)
</script>

<template>
  <ul>
    <li v-for="item in vm" :key="item.title">
      <a :href="`./${item.title}`">{{ item.title }}</a>
    </li>
  </ul>
</template>

