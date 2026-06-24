<template>
  <div class="info-container">
    <el-descriptions title="个人信息" direction="vertical" :column="2" border>
      <el-descriptions-item label="用户名">
        <span>{{ userInfo.username }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="昵称">
        <span>{{ userInfo.nickname || '未设置' }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="性别">
        <span>{{ getSexText(userInfo.sex) }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="手机号">
        <span>{{ userInfo.phone || '未绑定' }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="邮箱">
        <span>{{ userInfo.email || '未绑定' }}</span>
      </el-descriptions-item>
    </el-descriptions>
  </div>
</template>

<script>
import axios from 'axios'
var storage = window.localStorage
export default {
  data () {
    return {
      userInfo: {}
    }
  },
  methods: {
    pageInit () {
      const userId = storage.getItem('username')
      axios.post('http://localhost:8085/users/get_detail', { id: userId })
        .then((response) => {
          this.userInfo = response.data.data
        })
        .catch(function (error) {
          console.log(error)
        })
    },
    getSexText (sex) {
      const sexMap = { 0: '未知', 1: '男', 2: '女' }
      return sexMap[sex] || '未知'
    },
    formatDate (dateStr) {
      if (!dateStr) return '未登录'
      const date = new Date(dateStr)
      return date.toLocaleString('zh-CN')
    }
  },
  created () {
    this.pageInit()
  }
}
</script>

<style scoped>
.info-container {
  padding: 20px;
}

.avatar {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  object-fit: cover;
}
</style>