<script setup lang="ts">
import { createClient } from "@supabase/supabase-js";
import { onMounted, ref } from "vue";

// todo:  不能放到代码里 会造成key泄露
// 放到用户的localStorage里，让用户输入一次，后续不再输入
const VITE_SUPABASE_URL='https://ydlxxqwezxpahumndhfg.supabase.co'
const VITE_SUPABASE_PUBLISHABLE_KEY='sb_publishable_z3PKIshyxXFJ3PaMxKl17A_s0y6-ONe'

const supabase = createClient(VITE_SUPABASE_URL, VITE_SUPABASE_PUBLISHABLE_KEY);

const datas = ref()
onMounted(async ()=>{
    datas.value = (await supabase.from('test').select()).data
    console.log(datas.value)
})


// 方式2 通过云函数获取数据 todo：测试失败
const data2 = ref()
async function cloudFunction(){
    const { data, error } = await supabase.functions.invoke('database-access', {
        body: { name: 'Functions' },
    })
    data2.value = data
    return data
}

// cloudFunction()


</script>

<template>
    <div v-for="value in datas">{{value}}</div>
</template>
