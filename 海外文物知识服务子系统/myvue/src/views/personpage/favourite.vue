<template>
  <div>
    <div class="favorite-header">
      <h2>我的收藏</h2>
    </div>
    <br>
    <el-empty v-if="collectList.length === 0" description="暂无收藏"></el-empty>
    <div v-else class="card-list">
      <smallAntique 
        v-for="(item, index) in collectList" 
        :key="index"
        :title="item.objectName"
        :pic="item.imgUrl"
        :info="item.timePeriod"
        :museumId="item.museumId"
        :objectId="item.objectId"
        :showRemove="true"
        @remove="handleRemove"
      />
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import smallAntique from '../../components/smallAntique/smallAntique.vue'
export default {
  name: 'favourite',
  components: {
    smallAntique
  },
  data () {
    return {
      collectList: [],
      form: {
        id: ''
      }
    }
  },
  methods: {
    pageInit () {
      const userId = localStorage.getItem('user_id') || localStorage.getItem('username')
      if (!userId) {
        this.collectList = []
        return
      }
      this.form.id = userId
      axios.post('http://localhost:8085/user_admin/collect', this.form)
        .then((response) => {
          if (response.data.state === 200) {
            this.collectList = response.data.data
          }
        })
        .catch(function (error) {
          console.log(error)
        })
    },
    handleRemove (data) {
      this.$confirm('确定要取消收藏吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        axios.post('http://localhost:8085/user_admin/deleteCollect', {
          userId: localStorage.getItem('user_id') || localStorage.getItem('username'),
          museumId: String(data.museumId),
          objectId: String(data.objectId)
        })
          .then((response) => {
            if (response.data.state === 200) {
              this.collectList = this.collectList.filter(c => c.objectId !== data.objectId)
              this.$message.success('已取消收藏')
            }
          })
          .catch((error) => {
            console.log(error)
          })
      }).catch(() => {})
    }
  },
  created () {
    this.pageInit()
  },
  mounted () {
    window.addEventListener('collectChange', () => {
      this.pageInit()
    })
  },
  beforeUnmount () {
    window.removeEventListener('collectChange', () => {
      this.pageInit()
    })
  }
}
</script>

<style scoped>
.favorite-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
</style>