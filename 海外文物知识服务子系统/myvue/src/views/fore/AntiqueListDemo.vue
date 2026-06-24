<template>
  <div>
    <MainHeader></MainHeader>

    <div class="antique-list-page">
      <div class="page-header">
        <h1 class="page-title">文物浏览</h1>
        <p class="page-subtitle">探索海外馆藏中国文物</p>
      </div>

      <div class="filter-section">
        <el-card class="filter-card">
          <el-form :model="filterForm" inline>
            <el-form-item label="关键词">
              <el-input v-model="filterForm.title" placeholder="输入文物名称" clearable style="width: 200px" @keyup.enter="handleSearch" />
            </el-form-item>
            <el-form-item label="朝代">
              <el-select v-model="filterForm.dynasty" placeholder="全部朝代" clearable style="width: 150px">
                <el-option v-for="d in filterOptions.dynasties" :key="d" :label="d" :value="d" />
              </el-select>
            </el-form-item>
            <el-form-item label="类型">
              <el-select v-model="filterForm.type" placeholder="全部类型" clearable style="width: 150px">
                <el-option v-for="t in filterOptions.types" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
            <el-form-item label="博物馆">
              <el-select v-model="filterForm.museum" placeholder="全部博物馆" clearable style="width: 200px">
                <el-option v-for="m in filterOptions.museums" :key="m" :label="m" :value="m" />
              </el-select>
            </el-form-item>
            <el-form-item label="材质">
              <el-select v-model="filterForm.material" placeholder="全部材质" clearable style="width: 150px">
                <el-option v-for="m in filterOptions.materials" :key="m" :label="m" :value="m" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleSearch" icon="el-icon-search">搜索</el-button>
              <el-button @click="handleReset" icon="el-icon-refresh">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </div>

      <div class="pagination-bar">
        <span class="total-info">共 {{ total }} 件文物</span>
        <el-pagination
          background
          layout="prev, pager, next, sizes"
          :total="total"
          :page-size="pageSize"
          :current-page="pageNum"
          :page-sizes="[12, 24, 48, 96]"
          @current-change="handlePageChange"
          @size-change="handleSizeChange"
        />
      </div>

      <div v-loading="loading" class="list-wrapper">
        <AntiqueList
          :data="artifactList"
          :default-sort="'updateTime'"
          :default-order="'desc'"
        />
      </div>

      <div class="pagination-bar bottom">
        <el-pagination
          background
          layout="prev, pager, next"
          :total="total"
          :page-size="pageSize"
          :current-page="pageNum"
          @current-change="handlePageChange"
        />
      </div>
    </div>

    <MainFooter></MainFooter>
  </div>
</template>

<script>
import axios from 'axios'
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'
import AntiqueList from '../../components/AntiqueList/AntiqueList.vue'

export default {
  name: 'AntiqueListDemo',
  components: {
    MainHeader,
    MainFooter,
    AntiqueList
  },
  data () {
    return {
      filterForm: {
        title: '',
        dynasty: '',
        type: '',
        museum: '',
        material: ''
      },
      filterOptions: {
        types: [],
        dynasties: [],
        museums: [],
        materials: []
      },
      artifactList: [],
      pageNum: 1,
      pageSize: 12,
      total: 0,
      loading: false
    }
  },
  created () {
    this.loadFilters()
    this.loadData()
  },
  methods: {
    loadFilters () {
      axios.get('/search/filters').then(res => {
        if (res.data.state === 200 && res.data.data) {
          this.filterOptions = res.data.data
        }
      }).catch(() => {})
    },
    loadData () {
      this.loading = true
      const params = {
        pageNum: this.pageNum,
        pageSize: this.pageSize,
        sortBy: 'crawlDate',
        sortOrder: 'desc'
      }
      Object.keys(this.filterForm).forEach(key => {
        if (this.filterForm[key]) {
          params[key] = this.filterForm[key]
        }
      })
      axios.post('/search/list', params).then(res => {
        if (res.data.state === 200 && res.data.data) {
          this.artifactList = res.data.data.list || []
          this.total = res.data.data.total || 0
        }
      }).catch(() => {
        this.artifactList = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },
    handleSearch () {
      this.pageNum = 1
      this.loadData()
    },
    handleReset () {
      this.filterForm = {
        title: '',
        dynasty: '',
        type: '',
        museum: '',
        material: ''
      }
      this.pageNum = 1
      this.loadData()
    },
    handlePageChange (page) {
      this.pageNum = page
      this.loadData()
      window.scrollTo({ top: 300, behavior: 'smooth' })
    },
    handleSizeChange (size) {
      this.pageSize = size
      this.pageNum = 1
      this.loadData()
    }
  }
}
</script>

<style lang="scss" scoped>
.antique-list-page {
  min-height: 80vh;
  padding: 20px 5% 60px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.page-header {
  text-align: center;
  margin-bottom: 30px;
  padding: 30px 0;
}

.page-title {
  font-size: 36px;
  font-weight: 700;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0 0 10px 0;
}

.page-subtitle {
  font-size: 16px;
  color: #999;
  margin: 0;
}

.filter-section {
  margin-bottom: 20px;
}

.filter-card {
  :deep(.el-form) {
    display: flex;
    flex-wrap: wrap;
  }
}

.pagination-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.total-info {
  color: #999;
  font-size: 14px;
}

.pagination-bar.bottom {
  margin-top: 20px;
  justify-content: center;
}

.list-wrapper {
  min-height: 400px;
}
</style>
