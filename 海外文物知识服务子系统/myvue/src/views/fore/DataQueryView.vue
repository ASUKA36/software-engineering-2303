<template>
  <div>
    <MainHeader></MainHeader>

    <div class="data-query-page">
      <div class="page-header">
        <h1 class="page-title">文物搜索</h1>
        <p class="page-subtitle">海外中国文物知识服务系统 - 文物搜索模块</p>
      </div>

      <el-tabs v-model="activeTab" class="query-tabs">
        <el-tab-pane label="简单搜索" name="simple">
          <el-card class="search-card">
            <div class="simple-search">
              <el-input
                v-model="keyword"
                placeholder="请输入关键词（文物名称、作者、朝代、描述等）"
                size="large"
                clearable
                @keyup.enter="handleSimpleSearch"
              >
                <template #append>
                  <el-button @click="handleSimpleSearch" type="primary">搜索</el-button>
                </template>
              </el-input>
            </div>
          </el-card>
        </el-tab-pane>

        <el-tab-pane label="高级查询" name="advanced">
          <el-card class="search-card">
            <el-form :model="queryForm" inline class="advanced-form">
              <el-row :gutter="20">
                <el-col :span="8">
                  <el-form-item label="关键词">
                    <el-input v-model="queryForm.keyword" placeholder="搜索关键词" clearable />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="文物名称">
                    <el-input v-model="queryForm.title" placeholder="文物名称" clearable />
                  </el-form-item>
                </el-col>
                <el-col :span="8">
                  <el-form-item label="作者">
                    <el-input v-model="queryForm.artist" placeholder="作者" clearable />
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="20">
                <el-col :span="12">
                  <el-form-item label="朝代">
                    <el-select v-model="queryForm.dynasty" placeholder="全部朝代" clearable filterable style="width: 100%">
                      <el-option v-for="d in filterOptions.dynasties" :key="d" :label="d" :value="d" />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="类型">
                    <el-select v-model="queryForm.type" placeholder="全部类型" clearable filterable style="width: 100%">
                      <el-option v-for="t in filterOptions.types" :key="t" :label="t" :value="t" />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="20">
                <el-col :span="12">
                  <el-form-item label="材质">
                    <el-select v-model="queryForm.material" placeholder="全部材质" clearable filterable style="width: 100%">
                      <el-option v-for="m in filterOptions.materials" :key="m" :label="m" :value="m" />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="博物馆">
                    <el-select v-model="queryForm.museum" placeholder="全部博物馆" clearable filterable style="width: 100%">
                      <el-option v-for="m in filterOptions.museums" :key="m" :label="m" :value="m" />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="20">
                <el-col :span="12">
                  <el-form-item label="时期">
                    <el-input v-model="queryForm.period" placeholder="时期" clearable />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="文化">
                    <el-input v-model="queryForm.culture" placeholder="文化" clearable />
                  </el-form-item>
                </el-col>
              </el-row>
              <el-row :gutter="20">
                <el-col :span="12">
                  <el-form-item label="排序字段">
                    <el-select v-model="queryForm.sortField" placeholder="请选择排序字段" style="width: 100%">
                      <el-option label="名称" value="title" />
                      <el-option label="朝代" value="dynasty" />
                      <el-option label="时期" value="periodStartYear" />
                      <el-option label="更新时间" value="crawlDate" />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="排序方式">
                    <el-select v-model="queryForm.sortOrder" placeholder="请选择排序方式" style="width: 100%">
                      <el-option label="升序" value="asc" />
                      <el-option label="降序" value="desc" />
                    </el-select>
                  </el-form-item>
                </el-col>
              </el-row>
              <el-form-item>
                <el-button type="primary" @click="handleAdvancedSearch" icon="el-icon-search">查询</el-button>
                <el-button @click="handleReset" icon="el-icon-refresh">重置</el-button>
              </el-form-item>
            </el-form>
          </el-card>
        </el-tab-pane>
      </el-tabs>

      <div v-if="resultList.length > 0" class="result-section">
        <div class="action-bar">
          <span class="result-count">共 {{ total }} 条结果</span>
          <div class="export-buttons">
            <el-button type="success" size="small" icon="el-icon-download" @click="handleExportCSV">导出 CSV</el-button>
            <el-button type="warning" size="small" icon="el-icon-document" @click="handleExportJSON">导出 JSON</el-button>
          </div>
        </div>

        <div class="pagination-top">
          <el-pagination
            background
            layout="prev, pager, next, sizes"
            :total="total"
            :page-size="queryForm.pageSize"
            :current-page="queryForm.pageNum"
            :page-sizes="[10, 20, 50, 100]"
            @current-change="handlePageChange"
            @size-change="handleSizeChange"
          />
        </div>

        <el-table :data="resultList" stripe style="width: 100%" v-loading="loading">
          <el-table-column type="index" label="序号" width="60" />
          <el-table-column prop="museumId" label="博物馆ID" width="100" show-overflow-tooltip />
          <el-table-column prop="objectId" label="文物ID" width="120" show-overflow-tooltip />
          <el-table-column prop="title" label="文物名称" min-width="200" show-overflow-tooltip />
          <el-table-column prop="artist" label="作者" width="150" show-overflow-tooltip />
          <el-table-column prop="dynasty" label="朝代" width="120" show-overflow-tooltip />
          <el-table-column prop="period" label="时期" width="120" show-overflow-tooltip />
          <el-table-column prop="type" label="类型" width="120" show-overflow-tooltip />
          <el-table-column prop="material" label="材质" width="120" show-overflow-tooltip />
          <el-table-column prop="culture" label="文化" width="120" show-overflow-tooltip />
          <el-table-column prop="museum" label="博物馆" width="200" show-overflow-tooltip />
          <el-table-column label="操作" width="100" fixed="right">
            <template #default="scope">
              <el-button
                type="text"
                size="small"
                @click="goToDetail(scope.row)"
              >详情</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="pagination-bottom">
          <el-pagination
            background
            layout="prev, pager, next"
            :total="total"
            :page-size="queryForm.pageSize"
            :current-page="queryForm.pageNum"
            @current-change="handlePageChange"
          />
        </div>
      </div>

      <el-empty v-else-if="hasSearched" description="暂无搜索结果" />
    </div>

    <MainFooter></MainFooter>
  </div>
</template>

<script>
import axios from 'axios'
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'

export default {
  name: 'DataQueryView',
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    return {
      activeTab: 'simple',
      keyword: '',
      queryForm: {
        keyword: '',
        title: '',
        artist: '',
        dynasty: '',
        period: '',
        type: '',
        material: '',
        culture: '',
        museum: '',
        museumId: null,
        pageNum: 1,
        pageSize: 10,
        sortField: 'title',
        sortOrder: 'asc'
      },
      filterOptions: {
        types: [],
        dynasties: [],
        museums: [],
        materials: []
      },
      resultList: [],
      total: 0,
      loading: false,
      hasSearched: false
    }
  },
  created () {
    this.loadFilterOptions()
  },
  methods: {
    loadFilterOptions () {
      axios.get('/search/filters').then(res => {
        if (res.data.state === 200 && res.data.data) {
          this.filterOptions = res.data.data
        }
      }).catch(err => {
        console.error('加载筛选选项失败', err)
      })
    },

    handleSimpleSearch () {
      if (!this.keyword.trim()) {
        this.$message.warning('请输入搜索关键词')
        return
      }
      this.loading = true
      this.hasSearched = true
      axios.get('/search/keyword', {
        params: { keyword: this.keyword }
      }).then(res => {
        if (res.data.state === 200) {
          this.resultList = res.data.data || []
          this.total = this.resultList.length
        } else {
          this.$message.error(res.data.message || '搜索失败')
          this.resultList = []
          this.total = 0
        }
      }).catch(err => {
        console.error('搜索失败', err)
        this.$message.error('搜索失败，请稍后重试')
        this.resultList = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },

    handleAdvancedSearch () {
      this.queryForm.pageNum = 1
      this.doAdvancedSearch()
    },

    doAdvancedSearch () {
      this.loading = true
      this.hasSearched = true
      axios.post('/search/advanced', this.queryForm).then(res => {
        if (res.data.state === 200) {
          this.resultList = res.data.data.list || []
          this.total = res.data.data.total || 0
        } else {
          this.$message.error(res.data.message || '查询失败')
          this.resultList = []
          this.total = 0
        }
      }).catch(err => {
        console.error('查询失败', err)
        this.$message.error('查询失败，请稍后重试')
        this.resultList = []
        this.total = 0
      }).finally(() => {
        this.loading = false
      })
    },

    handleReset () {
      this.queryForm = {
        keyword: '',
        title: '',
        artist: '',
        dynasty: '',
        period: '',
        type: '',
        material: '',
        culture: '',
        museum: '',
        museumId: null,
        pageNum: 1,
        pageSize: 10,
        sortField: 'title',
        sortOrder: 'asc'
      }
      this.resultList = []
      this.total = 0
      this.hasSearched = false
    },

    handlePageChange (page) {
      this.queryForm.pageNum = page
      if (this.activeTab === 'advanced') {
        this.doAdvancedSearch()
      }
      window.scrollTo({ top: 300, behavior: 'smooth' })
    },

    handleSizeChange (size) {
      this.queryForm.pageSize = size
      this.queryForm.pageNum = 1
      if (this.activeTab === 'advanced') {
        this.doAdvancedSearch()
      }
    },

    handleExportCSV () {
      const exportData = this.activeTab === 'simple'
        ? { keyword: this.keyword }
        : { ...this.queryForm }

      axios.post('/search/export/csv', exportData, {
        responseType: 'blob'
      }).then(res => {
        const url = window.URL.createObjectURL(new Blob([res.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', 'cultural_relics_export.csv')
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        this.$message.success('CSV导出成功')
      }).catch(err => {
        console.error('CSV导出失败', err)
        this.$message.error('CSV导出失败')
      })
    },

    handleExportJSON () {
      const exportData = this.activeTab === 'simple'
        ? { keyword: this.keyword }
        : { ...this.queryForm }

      axios.post('/search/export/json', exportData, {
        responseType: 'blob'
      }).then(res => {
        const url = window.URL.createObjectURL(new Blob([res.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', 'cultural_relics_export.json')
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        this.$message.success('JSON导出成功')
      }).catch(err => {
        console.error('JSON导出失败', err)
        this.$message.error('JSON导出失败')
      })
    },

    goToDetail (row) {
      this.$router.push({
        path: '/antiqueDetail',
        query: {
          museum_id: row.museumId,
          object_id: row.objectId
        }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.data-query-page {
  min-height: 80vh;
  padding: 60px 5% 80px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

:deep(.el-form-item__content) {
  flex: 1;
  min-width: 200px;
}

:deep(.el-select) {
  width: 100% !important;
  min-width: 200px;
}

:deep(.el-input) {
  width: 100% !important;
  min-width: 200px;
}

.page-header {
  text-align: center;
  margin-bottom: 50px;
}

.page-title {
  font-family: 'Ma Shan Zheng', 'STKaiti', 'KaiTi', 'ZCOOL XiaoWei', 'Noto Serif SC', serif;
  font-size: 48px;
  font-weight: 400;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0 0 15px 0;
  letter-spacing: 12px;
}

.page-subtitle {
  font-size: 18px;
  color: #666;
  margin: 0;
  letter-spacing: 3px;
}

.query-tabs {
  max-width: 1200px;
  margin: 0 auto;
  
  :deep(.el-tabs__header) {
    margin-bottom: 0;
    border-radius: 12px 12px 0 0;
    overflow: hidden;
  }
  
  :deep(.el-tabs__nav-wrap) {
    background: #ffffff;
    padding: 10px 20px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
  }
  
  :deep(.el-tabs__item) {
    font-size: 16px;
    padding: 12px 35px;
    margin-right: 40px;
    border-radius: 8px;
    transition: all 0.3s ease;
    line-height: 1;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 100px;
    
    &:hover {
      background: rgba(26, 26, 46, 0.05);
    }
    
    &.is-active {
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: #ffffff;
      line-height: 1;
      padding: 12px 40px;
    }
  }
}

.search-card {
  max-width: 1200px;
  margin: -1px auto 25px;
  border-radius: 0 0 12px 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border: none;
  overflow: hidden;
}

.simple-search {
  max-width: 900px;
  margin: 30px auto;
  padding: 0 30px;
}

.advanced-form {
  padding: 25px 30px;
  
  :deep(.el-form-item) {
    margin-bottom: 20px;
  }
  
  :deep(.el-form-item__label) {
    font-weight: 500;
    color: #333;
    padding-right: 15px;
  }
}

.result-section {
  margin-top: 30px;
}

.action-bar {
  max-width: 1200px;
  margin: 0 auto 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background: #ffffff;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
}

.result-count {
  font-size: 15px;
  color: #555;
  font-weight: 500;
}

.export-buttons {
  display: flex;
  gap: 12px;
}

:deep(.el-table) {
  max-width: 1200px;
  margin: 0 auto;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

:deep(.el-table__header) {
  background: #f8f9fa;
}

:deep(.el-table__header th) {
  color: #1a1a2e;
  font-weight: 600;
  border-bottom: 2px solid #e0e0e0;
}

:deep(.el-table__body tr) {
  transition: background-color 0.2s ease;
}

:deep(.el-table__body tr:hover) {
  background: rgba(26, 26, 46, 0.03);
}

:deep(.el-pagination .el-pager li) {
  border-radius: 6px;
  margin: 0 4px;
}

:deep(.el-pagination .el-pager li.is-active) {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  border-color: transparent;
}

:deep(.el-pagination .btn-prev),
:deep(.el-pagination .btn-next) {
  border-radius: 6px;
}

.pagination-top,
.pagination-bottom {
  display: flex;
  justify-content: center;
  margin: 25px 0;
}

:deep(.el-empty) {
  max-width: 1200px;
  margin: 40px auto;
}
</style>
