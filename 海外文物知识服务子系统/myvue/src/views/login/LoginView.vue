<template>
  <div>
    <MainHeader></MainHeader>
    <div>
      <el-form ref="loginForm" :model="form" :rules="rules" label-width="80px" class="login-box">
        <h3 class="login-title">登录</h3>
        <el-form-item label="账号" prop="username">
          <el-input type="text" placeholder="请输入账号" v-model="form.username"/>
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input type="password" placeholder="请输入密码" v-model="form.password"/>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" v-on:click="onSubmit()">登录</el-button>
          <el-button type="primary" v-on:click="turn_to_register()">注册</el-button>
        </el-form-item>
      </el-form>

      <el-dialog
        title="温馨提示"
        :visible.sync="dialogVisible"
        width="30%"
        :before-close="handleClose">
        <span>请输入账号和密码</span>
        <span slot="footer" class="dialog-footer">
          <el-button type="primary" @click="dialogVisible = false">确 定</el-button>
        </span>
      </el-dialog>
    </div>
    <MainFooter></MainFooter>
  </div>
</template>

<script>
import MainFooter from '../../components/MainFooter/MainFooter'
import MainHeader from '../../components/MainHeader/MainHeader'
import axios from 'axios'
export default {
  name: 'Login',
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    return {
      form: {
        username: '',
        password: ''
      },
      dialogVisible: false
    }
  },
  methods: {
    handleClose () {
      this.dialogVisible = false
    },
    onSubmit () {
      if (!this.form.username || !this.form.password) {
        this.dialogVisible = true
        return
      }

      axios.post('http://localhost:8085/users/login', this.form)
        .then((response) => {
          console.log(response.data)
          if (response.data.state === 200) {
            const user = response.data.data
            const storage = window.localStorage
            
            storage.setItem('username', user.user_id)
            storage.setItem('token', response.data.token)
            storage.setItem('user_username', user.username)
            storage.setItem('user_nickname', user.nickname || '')
            storage.setItem('user_avatar', user.avatar_url || '')
            storage.setItem('can_comment', user.canComment || 1)
            storage.setItem('can_upload', user.canUpload || 1)
            storage.setItem('islogin', 1)
            
            this.$message({
              type: 'success',
              message: '登录成功！欢迎 ' + (user.nickname || user.username)
            })
            this.$router.push('/index')
          } else {
            this.$message({
              type: 'error',
              message: response.data.message
            })
          }
        }).catch(function (error) {
          console.log(error)
          this.$message({
            type: 'error',
            message: '登录失败，请稍后重试'
          })
        })
    },
    turn_to_register () {
      this.$router.push('register')
    }
  }
}
</script>

<style lang="scss" scoped>
.login-box {
  border: 1px solid #DCDFE6;
  width: 350px;
  margin: 180px auto;
  padding: 35px 35px 15px 35px;
  border-radius: 5px;
  -webkit-border-radius: 5px;
  -moz-border-radius: 5px;
  box-shadow: 0 0 25px #909399;
  background-image: url("https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fimg.pptjia.com%2Fimage%2F20180321%2F388ab9a0b82be807d876ac2aa0271a2e.png&refer=http%3A%2F%2Fimg.pptjia.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1654419512&t=ec62ac8ce9c4edf0ec2e9b18c0223873");
}

.login-title {
  text-align: center;
  margin: 0 auto 40px auto;
  color: #303133;
}
</style>