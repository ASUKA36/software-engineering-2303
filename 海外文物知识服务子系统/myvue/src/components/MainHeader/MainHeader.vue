<template>
  <div class="main-header">
    <el-menu class="el-menu" mode="horizontal">
      <el-menu-item class="menu-logo-holder" index="logo">
        <div class="logo-text">
          <span class="logo-icon">🏛️</span>
          <span class="logo-title">数字博物馆云平台</span>
        </div>
      </el-menu-item>

      <router-link to="/index">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="index">首页</el-menu-item>
        </div>
      </router-link>

      <router-link to="/classify">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="classify">浏览</el-menu-item>
        </div>
      </router-link>

      <router-link to="/dataQuery">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="dataQuery">文物搜索</el-menu-item>
        </div>
      </router-link>

      <router-link to="/knowledge-graph">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="knowledge-graph">知识图谱</el-menu-item>
        </div>
      </router-link>

      <router-link to="/timeline">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="timeline">文物时间轴</el-menu-item>
        </div>
      </router-link>

      <router-link to="/statistics">
        <div class="float-left">
          <el-menu-item class="disable-element-hover" index="statistics">统计分析</el-menu-item>
        </div>
      </router-link>

      <router-link to="/museum-map">
  <div class="float-left">
    <el-menu-item class="disable-element-hover" index="museum-map">地理分布</el-menu-item>
  </div>
</router-link>

      <router-link to="/login" v-if="!isLogin">
        <div class="float-right">
          <el-menu-item class="disable-element-hover" index="login">登录</el-menu-item>
        </div>
      </router-link>

      <router-link to="/personpage" v-if="isLogin">
        <div class="float-right">
          <el-menu-item class="disable-element-hover" index="personpage">个人中心</el-menu-item>
        </div>
      </router-link>
      <div v-if="isLogin">
        <div class="float-right">
          <el-menu-item class="disable-element-hover" index="logout" v-on:click="off_log" >登出</el-menu-item>
        </div>
      </div>
    </el-menu>
  </div>
</template>

<script>
export default {
  data () {
    return {
      isLogin: false
    }
  },
  created () {
    this.loadUser()
  },
  methods: {
    loadUser () {
      if (localStorage.getItem('username')) {
        this.isLogin = true
      } else {
        this.isLogin = false
      }
    },
    off_log () {
      localStorage.removeItem('username')
      localStorage.removeItem('userpassword')
      localStorage.setItem('islogin', 0)
      this.$router.go(0)
    }
  }
}
</script>

<style lang="scss" scoped>
.main-header {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  padding: 8px 0;
}

:deep(.el-menu) {
  background: transparent !important;
  border: none;
}

:deep(.el-menu-item) {
  color: rgba(255, 255, 255, 0.9) !important;
  font-size: 15px;
  margin: 0 8px;
  border-radius: 8px;
  transition: all 0.3s ease;
  height: 45px;
  line-height: 45px;
  
  &:hover {
    background: rgba(255, 255, 255, 0.1) !important;
    color: #fff !important;
  }
  
  &.is-active {
    background: rgba(255, 255, 255, 0.15) !important;
    color: #fff !important;
  }
}

.float-left {
  float: left;
}

.float-right {
  float: right;
}

.disable-element-hover:hover {
  background: rgba(255, 255, 255, 0.1) !important;
}

.disable-element-hover {
  background: transparent !important;
}

.menu-logo-holder {
  width: 180px;
  margin-right: 20px;
}

.logo-text {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.logo-icon {
  font-size: 24px;
}

.logo-title {
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 1px;
}
</style>
