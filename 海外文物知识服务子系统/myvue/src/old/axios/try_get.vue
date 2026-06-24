<template>

</template>

<script>
import axios from 'axios'

export default {
  name: 'try_get'
}

const {data: res} = axios({         /* '{data: res}'是解构赋值，抽取了promise对象result里的data属性,并重命名为res */
  // 请求方式
  method: 'GET',
  // 请求地址
  url: '',
  // 传给服务器的查询参数
  params: {
    id: 1
  },
  // 请求体参数
  data: {}
}).then(function (result) {
  console.log(res.data)
})


axios.get('', {
  params: {id: 1}
})

</script>

<style scoped>

</style>
