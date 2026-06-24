<template>
  <div>
    <MainHeader></MainHeader>
    <div>
      <el-form ref="registerForm" :model="form" :rules="rules" label-width="80px" class="login-box">
        <h3 class="login-title">注册</h3>
        <el-form-item label="用户名" prop="username">
          <el-input type="text" placeholder="请输入用户名" v-model="form.username"/>
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input type="password" placeholder="请输入密码" v-model="form.password"/>
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input type="password" placeholder="请再次输入密码" v-model="form.confirmPassword"/>
        </el-form-item>
        <el-form-item label="性别">
          <el-radio v-model="form.sex" :label="1">男</el-radio>
          <el-radio v-model="form.sex" :label="2">女</el-radio>
          <el-radio v-model="form.sex" :label="0">保密</el-radio>
        </el-form-item>
        <el-form-item label="手机号" prop="tele">
          <el-input type="text" placeholder="请输入手机号" v-model="form.tele"/>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="onSubmit">注册</el-button>
          <el-button @click="turn_to_login">返回登录</el-button>
        </el-form-item>
      </el-form>
    </div>
    <MainFooter></MainFooter>
  </div>
</template>

<script>
import axios from 'axios'
import MainFooter from '../../components/MainFooter/MainFooter'
import MainHeader from '../../components/MainHeader/MainHeader'
export default {
  name: 'Register',
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    const validateConfirmPassword = (rule, value, callback) => {
      if (value !== this.form.password) {
        callback(new Error('两次输入的密码不一致'))
      } else {
        callback()
      }
    }

    return {
      form: {
        username: '',
        password: '',
        confirmPassword: '',
        sex: 0,
        tele: ''
      },
      rules: {
        username: [
          { required: true, message: '用户名不能为空', trigger: 'blur' },
          { min: 3, max: 20, message: '用户名长度在3-20个字符', trigger: 'blur' }
        ],
        password: [
          { required: true, message: '密码不能为空', trigger: 'blur' },
          { min: 6, message: '密码长度至少6位', trigger: 'blur' }
        ],
        confirmPassword: [
          { required: true, message: '请确认密码', trigger: 'blur' },
          { validator: validateConfirmPassword, trigger: 'blur' }
        ],
        tele: [
          { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
        ]
      }
    }
  },
  methods: {
    onSubmit () {
      this.$refs.registerForm.validate((valid) => {
        if (valid) {
          axios.post('http://localhost:8085/users/register', {
            username: this.form.username,
            password: this.form.password,
            sex: this.form.sex.toString(),
            tele: this.form.tele
          }).then((response) => {
            if (response.data.state === 200) {
              this.$message({
                type: 'success',
                message: '注册成功！您的用户ID: ' + response.data.data
              })
              this.$router.push('/login')
            } else {
              this.$message({
                type: 'error',
                message: response.data.message
              })
            }
          }).catch((error) => {
            console.log(error)
            this.$message({
              type: 'error',
              message: '注册失败，请稍后重试'
            })
          })
        }
      })
    },
    turn_to_login () {
      this.$router.push('/login')
    }
  }
}
</script>

<style lang="scss" scoped>
.login-box {
  border: 1px solid #DCDFE6;
  width: 350px;
  margin: 120px auto;
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