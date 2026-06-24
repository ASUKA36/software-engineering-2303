<template>
  <div>
    <div class="history-header">
      <h2>浏览记录</h2>
      <el-button v-if="historyList.length > 0" type="danger" size="small" @click="clearAll">
        一键清除
      </el-button>
    </div>
    <br>
    <el-empty v-if="historyList.length === 0" description="暂无浏览记录"></el-empty>
    <div v-else class="card-list">
      <smallAntique 
        v-for="(item, index) in historyList" 
        :key="index"
        :title="item.object_name"
        :pic="item.img_url"
        :info="item.time_period"
        :time="item.browse_time"
        :museumId="item.museum_id"
        :objectId="item.object_id"
        :showRemove="true"
        @remove="removeItem"
      />
    </div>
  </div>
</template>

<script>
import smallAntique from '../../components/smallAntique/smallAntique.vue'
var storage = window.localStorage
export default {
  name: 'browse_history',
  components: {
    smallAntique
  },
  data () {
    return {
      historyList: []
    }
  },
  created () {
    this.loadHistory()
  },
  methods: {
    loadHistory () {
      const history = storage.getItem('browse_history')
      if (history) {
        try {
          this.historyList = JSON.parse(history)
        } catch (e) {
          this.historyList = []
        }
      }
    },
    clearAll () {
      this.$confirm('确定要清除所有浏览记录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        storage.removeItem('browse_history')
        this.historyList = []
        this.$message({
          type: 'success',
          message: '已清除所有浏览记录'
        })
      }).catch(() => {})
    },
    removeItem (data) {
      this.$confirm('确定要删除这条浏览记录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const history = storage.getItem('browse_history')
        if (history) {
          let list = JSON.parse(history)
          const museumId = data.museumId
          const objectId = data.objectId
          list = list.filter(h => !(String(h.museum_id) === String(museumId) && String(h.object_id) === String(objectId)))
          storage.setItem('browse_history', JSON.stringify(list))
          this.historyList = list
          this.$message({
            type: 'success',
            message: '已删除'
          })
        }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.history-header {
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