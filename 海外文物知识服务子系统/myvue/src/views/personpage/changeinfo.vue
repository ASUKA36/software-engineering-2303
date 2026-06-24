<template>
  <div class="changeinfo-container">
    <el-form ref="form" :model="form" label-width="100px" :rules="rules">
      <el-form-item label="头像">
        <div class="avatar-upload-container">
          <img :src="avatarPreview" class="avatar-preview-img" />
          <div class="avatar-upload-btn" @click="triggerFileInput">
            <i class="el-icon-plus"></i>
            <span>选择图片</span>
          </div>
          <input 
            type="file" 
            accept="image/jpeg,image/png,image/jpg" 
            @change="handleAvatarChange"
            class="avatar-file-input"
          />
        </div>
      </el-form-item>
      <el-form-item label="用户名" prop="username">
        <el-input v-model="form.username" placeholder="请输入用户名"></el-input>
      </el-form-item>
      <el-form-item label="昵称" prop="nickname">
        <el-input v-model="form.nickname" placeholder="请输入昵称"></el-input>
      </el-form-item>
      <el-form-item label="性别">
        <el-radio v-model="form.sex" :label="0">未知</el-radio>
        <el-radio v-model="form.sex" :label="1">男</el-radio>
        <el-radio v-model="form.sex" :label="2">女</el-radio>
      </el-form-item>
      <el-form-item label="手机号" prop="phone">
        <el-input v-model="form.phone" placeholder="请输入手机号"></el-input>
      </el-form-item>
      <el-form-item label="邮箱" prop="email">
        <el-input v-model="form.email" placeholder="请输入邮箱"></el-input>
      </el-form-item>
      <el-form-item label="原密码" prop="old_password">
        <el-input type="password" v-model="form.old_password" placeholder="请输入原密码"></el-input>
      </el-form-item>
      <el-form-item label="新密码" prop="password">
        <el-input type="password" v-model="form.password" placeholder="请输入新密码（不修改请留空）"></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onSubmit">保存修改</el-button>
        <el-button @click="resetForm">重置</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script>
import axios from 'axios'
var storage = window.localStorage
export default {
  data () {
    return {
      form: {
        id: storage.getItem('username'),
        username: '',
        nickname: '',
        sex: 0,
        phone: '',
        email: '',
        avatar_url: '',
        old_password: '',
        password: ''
      },
      avatarPreview: '/src/assets/timg.jpeg',
      avatarFile: null,
      rules: {
        username: [
          { required: true, message: '请输入用户名', trigger: 'blur' }
        ],
        old_password: [
          { required: true, message: '请输入原密码', trigger: 'blur' }
        ],
        phone: [
          { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
        ],
        email: [
          { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
        ]
      }
    }
  },
  mounted () {
    this.pageInit()
  },
  methods: {
    pageInit () {
      const userId = storage.getItem('username')
      axios.post('http://localhost:8085/users/get_detail', { id: userId })
        .then((response) => {
          const user = response.data.data
          this.form.username = user.username || ''
          this.form.nickname = user.nickname || ''
          this.form.sex = user.sex || 0
          this.form.phone = user.phone || ''
          this.form.email = user.email || ''
          this.form.avatar_url = user.avatar_url || ''
          // 设置头像预览
          this.avatarPreview = this.getAvatarUrl(user.avatar_url)
        })
        .catch(function (error) {
          console.log(error)
        })
    },
    resetForm () {
      this.pageInit()
      this.$refs.form.resetFields()
      this.avatarFile = null
    },
    // 统一的头像URL处理函数
    getAvatarUrl (avatar) {
      if (!avatar) return '/src/assets/timg.jpeg'
      if (avatar.startsWith('http')) return avatar
      return 'http://localhost:8085' + avatar
    },
    // 触发文件选择
    triggerFileInput () {
      document.querySelector('.avatar-file-input').click()
    },
    // 处理头像选择
    handleAvatarChange (event) {
      const file = event.target.files[0]
      if (!file) return
      
      // 检查文件大小（最大2MB）
      if (file.size > 2 * 1024 * 1024) {
        this.$message.error('图片大小不能超过2MB')
        event.target.value = ''
        return
      }
      
      // 检查文件格式
      const validTypes = ['image/jpeg', 'image/png', 'image/jpg']
      if (!validTypes.includes(file.type)) {
        this.$message.error('只支持JPG/JPEG/PNG格式')
        event.target.value = ''
        return
      }
      
      // 预览图片（base64）
      const reader = new FileReader()
      reader.onload = (e) => {
        this.avatarPreview = e.target.result
      }
      reader.readAsDataURL(file)
      
      // 保存文件对象（用于后续上传）
      this.avatarFile = file
    },
    // 上传头像
    uploadAvatar () {
      return new Promise((resolve, reject) => {
        if (!this.avatarFile) {
          resolve()
          return
        }
        
        const formData = new FormData()
        formData.append('file', this.avatarFile)
        
        axios.post('http://localhost:8085/users/upload_avatar', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        }).then((response) => {
          if (response.data.state === 200) {
            this.form.avatar_url = response.data.data
            resolve()
          } else {
            reject(new Error(response.data.message))
          }
        }).catch((error) => {
          reject(error)
        })
      })
    },
    onSubmit () {
      this.$refs.form.validate((valid) => {
        if (valid) {
          // 先上传头像（如果有新头像），再更新用户信息
          this.uploadAvatar().then(() => {
            axios.post('http://localhost:8085/users/update', this.form)
              .then((response) => {
                if (response.data.state === 200) {
                  // 更新 localStorage 中的头像信息
                  storage.setItem('user_avatar', this.form.avatar_url)
                  this.$message({
                    type: 'success',
                    message: '修改成功！'
                  })
                  this.$router.push('/personpage/info')
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
                  message: '修改失败，请稍后重试'
                })
              })
          }).catch((error) => {
            console.log(error)
            this.$message({
              type: 'error',
              message: '头像上传失败，请稍后重试'
            })
          })
        }
      })
    }
  }
}
</script>

<style scoped>
.changeinfo-container {
  padding: 20px;
}

.avatar-upload-container {
  display: flex;
  align-items: center;
  gap: 20px;
}

.avatar-preview-img {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #ddd;
}

.avatar-upload-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100px;
  height: 100px;
  border: 2px dashed #ddd;
  border-radius: 50%;
  cursor: pointer;
  color: #999;
  transition: all 0.3s;
}

.avatar-upload-btn:hover {
  border-color: #409EFF;
  color: #409EFF;
}

.avatar-upload-btn i {
  font-size: 24px;
  margin-bottom: 5px;
}

.avatar-file-input {
  display: none;
}
</style>