<template>
    <el-card :body-style="{ padding: '0px' }">
      <div class="block">
        <span class="demonstration"></span>
        <el-carousel height="150px">
          <el-carousel-item v-for="item in 3" :key="item">
            <img :src="pic" class="image">
          </el-carousel-item>
        </el-carousel>
      </div>
      <div style="padding: 14px;">
        <span>文物名称：{{name}}</span>
        <br>
        <span>文物时期：{{period}}</span>
        <br>
        <span>文物详情请访问：{{url}}</span>
        <div class="bottom clearfix">
          <el-button type="primary" @click="changeButton" v-if="!isStared">
            收藏
            <i class="el-icon-star-off"></i>
          </el-button>
        </div>
        <div class="bottom clearfix">
          <el-button type="primary" @click="changeButton" v-if="isStared">
            已收藏
            <i class="el-icon-star-on"></i>
          </el-button>
        </div>
      </div>
    </el-card>
</template>

<script>
import axios from 'axios'
var storage = window.localStorage
export default {
  data () {
    return {
      isStared: 0,
      antiqueId: '',
      name: '',
      pic: '',
      period: '',
      url: '',
      reid: this.$route.query.id,
      form: {
        rid: this.reid
      }
    }
  },
  created () {
    this.pageInit()
  },
  methods: {
    pageInit () {
      axios.post('http://localhost:8085/search/searchById', this.form
      ).then((response) => {
        this.name = response.data.data.object_name
        this.pic = response.data.data.img_url
        this.period = response.data.data.cat2
        this.url = response.data.data.url
        // this.isStared = response.data.isStared
      })
        .catch(function (error) {
          console.log(error)
        })
      console.log(this.isStared)
      console.log(typeof (this.isStared))
    },
    changeButton () {
      if (storage.getItem('isStared') === '1') {
        console.log(this.isStared)
        axios.post('', this.isStared// 注意数据是直接保存到json对象
        ).then(function (response) {
          if (response.data.state === 200) {
            this.$message({
              showClose: true,
              type: 'warning',
              message: '已取消收藏'
            })
          }
        }
        ).catch(function (error) {
          console.log(error)
        })
        this.isStared = 0
        storage.setItem('isStared', this.isStared)
      } else {
        axios.post('', this.isStared// 注意数据是直接保存到json对象
        ).then(function (response) {
          if (response.data.state === 200) {
            this.$message({
              showClose: true,
              type: 'success',
              message: '已收藏'
            })
          }
        }
        ).catch(function (error) {
          console.log(error)
        })
        this.isStared = 1
        console.log(this.isStared)
        storage.setItem('isStared', this.isStared)
      }
    }
  }
}
</script>

<style scoped>
.time {
  font-size: 13px;
  color: #999;
}

.bottom {
  margin-top: 13px;
  line-height: 12px;
}

.button {
  padding: 0;
  float: right;
}

.image {
  width: 100%;
  display: block;
}

.clearfix:before,
.clearfix:after {
  display: table;
  content: "";
}

.clearfix:after {
  clear: both
}
.el-carousel__item h3 {
  color: #475669;
  font-size: 14px;
  opacity: 0.75;
  line-height: 150px;
  margin: 0;
}

.el-carousel__item:nth-child(2n) {
  background-color: #99a9bf;
}

.el-carousel__item:nth-child(2n+1) {
  background-color: #d3dce6;
}
</style>
