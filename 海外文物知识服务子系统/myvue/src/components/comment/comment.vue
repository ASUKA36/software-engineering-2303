<template>
  <div>
    <div
      v-for="(item, i) in comments"
      :key="i"
      class="author-title reply-father"
    >
      <div class="author-info">
        <span class="author-name">{{ item.name }}</span>
        <span class="author-time">{{ item.time }}</span>
      </div>
      <div class="talk-box">
        <p>
          <span class="reply">{{ item.comment }}</span>
        </p>
      </div>
    </div>
    <div  @click="inputFocus" v-clickoutside="hideReplyBtn" class="my-reply">
      <div class="reply-info">
        <div
          tabindex="0"
          contenteditable="true"
          id="replyInput"
          spellcheck="false"
          placeholder="输入评论..."
          class="reply-input"
          @focus="showReplyBtn"
          @input="onDivInput($event)"
        ></div>
      </div>
      <div class="reply-btn-box" v-show="btnShow">
        <el-button
          class="reply-btn"
          size="medium"
          @click="sendComment"
          type="primary"
        >
          发表评论
        </el-button>
      </div>          <!--发表评论按钮-->
    </div>
  </div>
</template>

<script>
  import axios from 'axios'

  const clickoutside = {
    // 初始化指令
    bind (el, binding, vnode) {
      function documentHandler (e) {
        // 这里判断点击的元素是否是本身，是本身，则返回
        if (el.contains(e.target)) {
          return false
        }
        // 判断指令中是否绑定了函数
        if (binding.expression) {
          // 如果绑定了函数 则调用那个函数，此处binding.value就是handleClose方法
          binding.value(e)
        }
      }
      // 给当前元素绑定个私有变量，方便在unbind中可以解除事件监听
      el.vueClickOutside = documentHandler
      document.addEventListener('click', documentHandler)
    },
    update () {},
    unbind (el, binding) {
      // 解除事件监听
      document.removeEventListener('click', el.vueClickOutside)
      delete el.vueClickOutside
    }
  }
  var storage = window.localStorage
  export default {
    data () {
      return {
        btnShow: false,
        replyComment: '',
        myName: '',
        myId: 19870621,
        comments: [
          {
            name: '',
            id: 0,
            comment: '',
            time: ''
          }
        ],
        form: {
          rid: this.$route.query.id
        }
      }
    },
    directives: {clickoutside},
    methods: {
      pageInit () {
        axios.post('', this.form// 注意数据是直接保存到json对象
        ).then(function (response) {
          if (response.data.state === 200) {
            alert('hello world!')
          }
          console.log(response.data)
        }).catch(function (error) {
          console.log(error)
        })
      },
      inputFocus () {
        var replyInput = document.getElementById('replyInput')
        replyInput.style.padding = '8px 8px'
        replyInput.style.border = '2px solid blue'
        replyInput.focus()
      },
      showReplyBtn () {
        this.btnShow = true
      },
      hideReplyBtn () {
        var replyInput = document.getElementById('replyInput')
        this.btnShow = false
        replyInput.style.padding = '10px'
        replyInput.style.border = 'none'
      },
      sendComment () {
        if (storage.getItem('cancomment') === '0') {
          this.$message({
            showClose: true,
            type: 'warning',
            message: '您没有评论权限！'
          })
        } else {
          if (!this.replyComment) {
            this.$message({
              showClose: true,
              type: 'warning',
              message: '评论不能为空'
            })
          } else {
            let a = {}
            let input = document.getElementById('replyInput')
            let timeNow = new Date().getTime()
            let time = this.dateStr(timeNow)
            a.name = storage.getItem('username')
            a.comment = this.replyComment
            a.time = time
            a.id = storage.getItem('userid')
            this.comments.push(a)
            this.replyComment = ''
            input.innerHTML = ''
            axios.post('', this.comments// 注意数据是直接保存到json对象
            ).then(function (response) {
              if (response.data.state === 200) {
                alert('success!')
              }
              console.log(response.data)
            }).catch(function (error) {
              console.log(error)
            })
          }
        }
      },
      onDivInput: function (e) {
        this.replyComment = e.target.innerHTML
      },
      dateStr (date) {
        // 获取js 时间戳
        var time = new Date().getTime()
        // 去掉 js 时间戳后三位，与php 时间戳保持一致
        time = parseInt((time - date) / 1000)
        // 存储转换值
        var s
        if (time < 60 * 10) {
          // 十分钟内
          return '刚刚'
        } else if (time < 60 * 60 && time >= 60 * 10) {
          // 超过十分钟少于1小时
          s = Math.floor(time / 60)
          return s + '分钟前'
        } else if (time < 60 * 60 * 24 && time >= 60 * 60) {
          // 超过1小时少于24小时
          s = Math.floor(time / 60 / 60)
          return s + '小时前'
        } else if (time < 60 * 60 * 24 * 30 && time >= 60 * 60 * 24) {
          // 超过1天少于30天内
          s = Math.floor(time / 60 / 60 / 24)
          return s + '天前'
        } else {
          // 超过30天ddd
          var date2 = new Date(parseInt(date))
          return (
            date2.getFullYear() +
            '/' +
            (date2.getMonth() + 1) +
            '/' +
            date2.getDate()
          )
        }
      }
    }
  }
</script>

<style lang="scss" scoped>
  .my-reply {
    padding: 10px;
    background-color: #fafbfc;
    .header-img {
      display: inline-block;
      vertical-align: top;
    }
    .reply-info {
      display: inline-block;
      margin-left: 5px;
      width: 90%;
      //根据屏幕宽度自适应
      @media screen and (max-width:1200px) {
        width: 80%;
      }
      .reply-input {
        min-height: 20px;
        line-height: 22px;
        padding: 10px 10px;
        color: black;
        background-color: #fff;
        border-radius: 5px;
        // &:empty::before{
        //   content attr(placeholder);
        // }
        &:empty:before {
          content: attr(placeholder);
        }
        &:focus:before {
          content: none;
        }
        &:focus {
          padding: 8px 8px;
          border: 2px solid blue;
          box-shadow: none;
          outline: none;
        }
      }
    }
    .reply-btn-box {
      margin-top:10px;
      height: 25px;
      display: inline-block;
      .reply-btn {
        position: relative;
        float: right;
        margin-left: 15px;
        // margin-right: 15px;
      }
    }
  }
  .my-comment-reply {
    margin-left: 50px;
    .reply-input {
      width: auto;
    }
  }
  .author-title:not(:last-child) {
    border-bottom: 1px solid rgba(74, 136, 199, .3)
  }
  .reply-father {
    padding: 10px;

    .header-img {
      display: inline-block;
      vertical-align: top;
    }

    .author-info {
      display: inline-block;
      margin-left: 5px;
      width: 60%;
      height: 40px;
      line-height: 20px;

      span {
        display: block;
        cursor: pointer;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;
      }

      .author-name {
        color: #000;
        font-size: 18px;
        font-weight: bold;
      }

      .author-time {
        font-size: 14px;
      }
    }

    .icon-btn {
      width: 30%;
      padding: 0 !important;
      float: right;
      @media screen and (max-width: 1200px) {
        width: 20%;
        padding: 7px;
      }

      span {
        cursor: pointer;
      }

      .iconfont {
        margin: 0 5px;
      }
    }

    .talk-box {
      margin: 0 50px;

      p {
        margin: 0;
      }

      .reply {
        font-size: 16px;
        color: #000;
      }
    }

    .reply-box {
      margin: 10px 0 0 50px;
      background-color: #efefef;
    }
  }
</style>
