<template>

</template>

<script>
import axios from '_axios@0.27.2@axios'

export default {
  name: 'try_post'
}

axios({
  // 请求方式
  method: 'POST',
  // 请求地址
  url: '',
  // 传给服务器的查询参数
  params: {
    id: 1
  },
  // 请求体参数
  data: {
    name: 'zs',
    age: 20
  }
}).then(function (result) {
  console.log(result)
})

axios.post('', {
  name: 'zs',
  sex: ''
})

</script>

<style scoped>

</style>
