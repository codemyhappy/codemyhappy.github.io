<script setup>
import mediumZoom from 'medium-zoom'
import { onMounted } from 'vue';

onMounted(() => {
  mediumZoom('img',{
    background: '#000',
    container: document.body,
  })
})
</script>

<template>

</template>

<style>
.medium-zoom-overlay{
    z-index: 9999999;
}
.medium-zoom-image--opened{
    z-index: 99999999;
}

.content img{
    box-shadow:  1px 1px 6px rgba(0,0,0,.2), -1px -1px 6px rgba(0,0,0,.2);
    border-radius: 8px;
    max-width: 400px;
    margin: 0 auto;
}
</style>