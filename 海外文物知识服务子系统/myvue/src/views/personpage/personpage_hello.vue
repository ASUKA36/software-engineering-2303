<template>
  <div style="background-color: white">
    <h2>欢迎访问个人资料页，{{ user.username }}!</h2>
  </div>
</template>

<script>
var storage = window.localStorage
export default {
  name: 'personpage_hello',
  data () {
    return {
      user: {
        userpic: '@/assets/timg.jpeg',
        username: '游客'
      }
    }
  },
  created () {
    this.pageInit()
  },
  methods: {
    pageInit () {
      // 从 localStorage 读取用户信息
      const isLogin = storage.getItem('islogin')
      const username = storage.getItem('user_username')
      const nickname = storage.getItem('user_nickname')
      const avatar = storage.getItem('user_avatar')
      
      if (isLogin === '1' && username) {
        // 优先显示昵称，没有则显示用户名
        this.user.username = nickname || username
        
        // 处理头像URL
        if (avatar) {
          this.user.userpic = avatar.startsWith('http') 
            ? avatar 
            : 'http://localhost:8085' + avatar
        }
      }
    }
  }
}
</script>

<style scoped>
.el-header {
  background-color: #B3C0D1;
  color: #333;
  line-height: 60px;
}

.el-aside {
  color: #333;
}
.alink{

  text-decoration: none;
}
</style>
