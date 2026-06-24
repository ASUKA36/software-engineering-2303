<template>
<div>
  <MainHeader></MainHeader>
  
  <!-- 对比导航栏 -->
  <div v-if="compareCount >= 2" class="compare-nav-bar">
    <el-card class="compare-nav-card">
      <div class="compare-nav-content">
        <div class="compare-nav-info">
          <i class="el-icon-data-line"></i>
          <span>已选择 <strong>{{ compareCount }}</strong> 件文物进行对比</span>
        </div>
        <div class="compare-nav-actions">
          <el-button type="warning" size="medium" @click="goToCompare">
            <i class="el-icon-s-data"></i>
            查看对比
          </el-button>
          <el-button size="medium" @click="clearCompare">
            清空
          </el-button>
        </div>
      </div>
    </el-card>
  </div>
  
    <div class="filter-page">
      <div v-if="flag" class="filter-container">
        <div class="filter-header">
          <h2 class="filter-title">选择博物馆</h2>
          <p class="filter-desc">浏览不同博物馆收藏的珍贵文物</p>
        </div>
        
        <div class="filter-card">
          <div class="radio-grid">
            <el-radio v-model="searchForm.v_4" label="Smithsonian Institution">史密斯博物馆</el-radio>
            <el-radio v-model="searchForm.v_4" label="Harvard Art Museums">哈佛大学博物馆</el-radio>
            <el-radio v-model="searchForm.v_4" label="Museum of Fine Arts, Boston">波士顿美术馆</el-radio>
          </div>
          
          <div class="filter-actions">
            <el-button type="primary" size="large" @click="onSubmit_to_search">
              <i class="el-icon-search"></i>
              确 定
            </el-button>
          </div>
        </div>
      </div>
      
      <div v-else class="result-container">
        <div class="back-button-wrapper">
          <el-button type="primary" @click="flag = true">
            <i class="el-icon-arrow-left"></i>
            返回选择
          </el-button>
        </div>
        
        <AntiqueList 
          :data="res_form"
          :default-sort="'title'"
          :default-order="'asc'"
          :compare-count="compareCount"
          @view-change="handleViewChange"
          @sort-change="handleSortChange"
          @compare-change="handleCompareChange"
        ></AntiqueList>
      </div>
    </div>
    <MainFooter></MainFooter>
  </div>
</template>

<script>
import axios from 'axios'
import MainFooter from '../../components/MainFooter/MainFooter'
import MainHeader from '../../components/MainHeader/MainHeader'
import AntiqueList from '../../components/AntiqueList/AntiqueList.vue'
export default {
  name: 'classify_muse',
  components: {
    MainHeader,
    MainFooter,
    AntiqueList
  },
  data () {
    return {
      searchForm: {
        c: 'museum',
        v_4: ''
      },
      res_form: [],
      flag: true,
      compareCount: 0
    }
  },
  created () {
    this.updateCompareCount()
  },
  beforeDestroy () {
    window.removeEventListener('storage', this.handleStorageChange)
  },
  methods: {
    // 更新对比数量
    updateCompareCount () {
      const compareList = JSON.parse(localStorage.getItem('compareList') || '[]')
      this.compareCount = compareList.length
      window.addEventListener('storage', this.handleStorageChange)
    },
    
    // 处理 storage 变化
    handleStorageChange (e) {
      if (e.key === 'compareList') {
        this.updateCompareCount()
      }
    },
    
    // 跳转到对比页面
    goToCompare () {
      this.$router.push('/antiqueCompare')
    },
    
    // 清空对比列表
    clearCompare () {
      localStorage.removeItem('compareList')
      this.updateCompareCount()
      this.$message.success('已清空对比列表')
    },
    
    handleViewChange (mode) {
      console.log('视图模式切换:', mode)
    },
    handleSortChange (params) {
      console.log('排序参数:', params)
    },
    handleCompareChange (count) {
      this.compareCount = count
    },
    onSubmit_to_search () {
      if (this.searchForm.v_4 === '') { 
        alert('请选择博物馆') 
      } else {
        this.$axios.post('http://localhost:8085/search/classification', this.searchForm).then((response) => {
          console.log(response.data)
          if (response.data.state === 200) {
            this.res_form = response.data.data
            this.flag = false
          } else {
            alert(response.data)
          }
        }).catch((error) => { 
          console.log(error)
          this.$message.error('数据加载失败，请稍后重试')
        })
        console.log('Received values of form: ', this.searchForm)
      }
    }
  }
}
</script>

<style scoped>
/* 对比导航栏 */
.compare-nav-bar {
  position: sticky;
  top: 0;
  z-index: 100;
  padding: 10px 20px;
  background-color: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.compare-nav-card {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  color: white;
  margin: 0;
}

.compare-nav-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.compare-nav-info {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
}

.compare-nav-info i {
  font-size: 24px;
}

.compare-nav-info strong {
  color: #ffd700;
}

.compare-nav-actions {
  display: flex;
  gap: 10px;
}

/* 筛选页面主体 */
.filter-page {
  min-height: calc(100vh - 180px);
  padding: 40px 5%;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

/* 筛选容器 */
.filter-container {
  max-width: 800px;
  margin: 0 auto;
}

/* 筛选头部 */
.filter-header {
  text-align: center;
  margin-bottom: 30px;
}

.filter-title {
  font-family: 'Ma Shan Zheng', 'STKaiti', 'KaiTi', 'ZCOOL XiaoWei', 'Noto Serif SC', serif;
  font-size: 36px;
  font-weight: 400;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin: 0 0 10px 0;
  letter-spacing: 8px;
}

.filter-desc {
  font-size: 16px;
  color: #666;
  margin: 0;
}

/* 筛选卡片 */
.filter-card {
  background: #fff;
  border-radius: 16px;
  padding: 30px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* 单选框网格 */
.radio-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
  margin-bottom: 30px;
}

.radio-grid .el-radio {
  padding: 10px 15px;
  background: #f8f9fa;
  border-radius: 8px;
  transition: all 0.3s ease;
  
  &:hover {
    background: #e9ecef;
    transform: translateY(-2px);
  }
  
  &.is-checked {
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    
    .el-radio__label {
      color: #fff;
    }
    
    .el-radio__inner {
      border-color: #0f3460;
      background: #fff;
    }
    
    .el-radio__input.is-checked .el-radio__inner::after {
      background: #0f3460;
    }
  }
}

/* 筛选操作按钮 */
.filter-actions {
  display: flex;
  justify-content: center;
  gap: 20px;
}

.filter-actions .el-button {
  padding: 12px 30px;
  border-radius: 8px;
}

.filter-actions .el-button--primary {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  border: none;
}

/* 结果容器 */
.result-container {
  max-width: 1200px;
  margin: 0 auto;
}

/* 返回按钮包装 */
.back-button-wrapper {
  margin-bottom: 20px;
}

.back-button-wrapper .el-button {
  padding: 10px 25px;
  border-radius: 8px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  border: none;
}
</style>
