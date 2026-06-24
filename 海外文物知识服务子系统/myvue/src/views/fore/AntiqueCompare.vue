<template>
  <div class="compare-page">
    <MainHeader></MainHeader>
    
    <el-container class="compare-container">
      <el-main>
        <!-- 页面标题 -->
        <div class="page-header">
          <h1 class="page-title">文物对比</h1>
          <p class="page-subtitle">选择2-3件文物进行横向对比，直观展示属性差异</p>
        </div>

        <!-- 对比列表 -->
        <div class="compare-list-section">
          <el-card class="compare-list-card">
            <h3 class="section-title">
              <i class="el-icon-list"></i>
              已选择的文物
              <span class="count-badge">{{ compareList.length }}/3</span>
            </h3>
            
            <div v-if="compareList.length === 0" class="empty-compare">
              <el-empty description="暂无选择的文物，请从文物列表中添加"></el-empty>
              <el-button type="primary" @click="goToBrowse">
                <i class="el-icon-search"></i>
                去浏览文物
              </el-button>
            </div>
            
            <div v-else class="selected-items">
              <div 
                v-for="(item, index) in compareList" 
                :key="index"
                class="selected-item"
              >
                <div class="item-image">
                  <img :src="getValidImageUrl(item)" alt="">
                </div>
                <div class="item-info">
                  <h4>{{ item.title }}</h4>
                  <p>{{ item.dynasty }} · {{ item.type }}</p>
                  <p>{{ item.museum }}</p>
                </div>
                <button class="remove-btn" @click="removeFromCompare(index)">
                  ×
                </button>
              </div>
            </div>
          </el-card>
        </div>

        <!-- 对比表格 -->
        <div v-if="compareList.length >= 2" class="compare-table-section">
          <el-card class="compare-table-card">
            <h3 class="section-title">
              <i class="el-icon-menu"></i>
              属性对比
            </h3>
            
            <div class="compare-table-wrapper">
              <table class="compare-table">
                <thead>
                  <tr>
                    <th class="attribute-header">属性</th>
                    <th 
                      v-for="(item, index) in compareList" 
                      :key="index"
                      class="artifact-header"
                    >
                      <div class="artifact-header-content">
                        <img :src="getValidImageUrl(item)" alt="" class="header-image">
                        <span class="header-title">{{ item.title }}</span>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="attribute-cell">文物名称</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ item.title || '-' }}
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">朝代</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      <span :class="{ 'highlight': hasDifference('dynasty', index) }">
                        {{ item.dynasty || '-' }}
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">年代</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ formatYearRange(item.period_start_year, item.period_end_year) }}
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">类型</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      <span :class="{ 'highlight': hasDifference('type', index) }">
                        {{ item.type || '-' }}
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">材质</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      <span :class="{ 'highlight': hasDifference('material', index) }">
                        {{ item.material || '-' }}
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">博物馆</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      <span :class="{ 'highlight': hasDifference('museum', index) }">
                        {{ item.museum || '-' }}
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">作者</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ item.artist || '-' }}
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">尺寸</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ item.dimensions || '-' }}
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">藏品编号</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ item.accession_number || '-' }}
                    </td>
                  </tr>
                  <tr>
                    <td class="attribute-cell">文化/地域</td>
                    <td v-for="(item, index) in compareList" :key="index" class="value-cell">
                      {{ item.culture || '-' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- 差异总结 -->
            <div class="difference-summary">
              <h4>
                <i class="el-icon-alert"></i>
                差异总结
              </h4>
              <div class="difference-tags">
                <el-tag 
                  v-for="(diff, index) in differenceList" 
                  :key="index"
                  type="warning"
                  size="small"
                >
                  {{ diff }}
                </el-tag>
                <span v-if="differenceList.length === 0" class="no-difference">
                  所选文物在以上属性上没有差异
                </span>
              </div>
            </div>
          </el-card>
        </div>

        <!-- 操作提示 -->
        <div v-if="compareList.length === 1" class="hint-section">
          <el-card class="hint-card">
            <el-alert 
              title="提示" 
              type="info" 
              :closable="false"
            >
              请再选择 {{ 3 - compareList.length }} 件文物进行对比
            </el-alert>
          </el-card>
        </div>
      </el-main>
    </el-container>

    <MainFooter></MainFooter>
  </div>
</template>

<script>
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'

export default {
  name: 'AntiqueCompare',
  components: { MainHeader, MainFooter },
  data () {
    return {
      compareList: [],
      defaultImage: 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200"%3E%3Crect fill="%23f5f5f5" width="200" height="200"/%3E%3Ctext fill="%23999" font-family="sans-serif" font-size="14" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E暂无图片%3C/text%3E%3C/svg%3E',
      serverApiBase: 'http://47.96.152.190:8000'
    }
  },
  created () {
    this.loadCompareList()
  },
  computed: {
    differenceList () {
      if (this.compareList.length < 2) return []
      
      const attributes = ['dynasty', 'type', 'material', 'museum']
      const attributeNames = {
        dynasty: '朝代不同',
        type: '类型不同',
        material: '材质不同',
        museum: '博物馆不同'
      }
      
      const differences = []
      attributes.forEach(attr => {
        const values = this.compareList.map(item => item[attr])
        const uniqueValues = [...new Set(values)]
        if (uniqueValues.length > 1) {
          differences.push(attributeNames[attr])
        }
      })
      
      return differences
    }
  },
  methods: {
    // 加载对比列表
    loadCompareList () {
      const stored = localStorage.getItem('compareList')
      if (stored) {
        try {
          this.compareList = JSON.parse(stored)
        } catch (e) {
          this.compareList = []
        }
      }
    },
    
    // 保存对比列表
    saveCompareList () {
      localStorage.setItem('compareList', JSON.stringify(this.compareList))
    },
    
    // 从对比列表中移除
    removeFromCompare (index) {
      this.compareList.splice(index, 1)
      this.saveCompareList()
      this.$message.success('已移除')
    },
    
    // 判断属性是否有差异
    hasDifference (attr, index) {
      if (this.compareList.length < 2) return false
      const currentValue = this.compareList[index][attr]
      return this.compareList.some(item => item[attr] !== currentValue)
    },
    
    // 格式化年代范围
    formatYearRange (start, end) {
      const startYear = start ? (start < 0 ? `公元前${Math.abs(start)}年` : `${start}年`) : '未知'
      const endYear = end ? (end < 0 ? `公元前${Math.abs(end)}年` : `${end}年`) : '未知'
      return start === end ? startYear : `${startYear} - ${endYear}`
    },
    
    // 获取有效的图片URL（与AntiqueList一致的逻辑）
    getValidImageUrl (item) {
      const { image_url, img_url, museum_id, object_id } = item
      const imageUrl = image_url || img_url
      const museumIdNum = parseInt(museum_id)
      
      // 仅博物馆2、3调用服务器API
      if (museumIdNum === 2 || museumIdNum === 3) {
        if (object_id && object_id !== 'null' && object_id !== 'undefined') {
          return `${this.serverApiBase}/api/img/${museumIdNum}/${object_id}`
        }
        return this.defaultImage
      }
      
      // 其他博物馆使用原有逻辑
      if (!imageUrl || imageUrl === 'null' || imageUrl === 'undefined') {
        return this.defaultImage
      }
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        return this.defaultImage
      }
      return imageUrl
    },
    
    // 跳转到分类浏览页面
    goToBrowse () {
      this.$router.push('/classify')
    },
    
    // 清空对比列表
    clearCompareList () {
      this.compareList = []
      this.saveCompareList()
      this.$message.success('已清空对比列表')
    }
  }
}
</script>

<style lang="scss" scoped>
.compare-page {
  min-height: 100vh;
  background-color: #f5f7fa;
}

.compare-container {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

/* 页面头部 */
.page-header {
  text-align: center;
  margin-bottom: 30px;
  padding: 30px 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 8px;
  color: white;
}

.page-title {
  font-size: 32px;
  font-weight: bold;
  margin: 0 0 10px 0;
}

.page-subtitle {
  font-size: 16px;
  opacity: 0.9;
  margin: 0;
}

/* 对比列表区域 */
.compare-list-section {
  margin-bottom: 20px;
}

.compare-list-card {
  padding: 20px;
}

.section-title {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.count-badge {
  background-color: #409eff;
  color: white;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 10px;
}

.empty-compare {
  text-align: center;
  padding: 40px;
}

.selected-items {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.selected-item {
  display: flex;
  align-items: center;
  padding: 15px;
  background-color: #f5f7fa;
  border-radius: 8px;
  width: calc(33.33% - 10px);
  position: relative;
  
  @media (max-width: 768px) {
    width: 100%;
  }
}

.item-image {
  width: 80px;
  height: 80px;
  border-radius: 8px;
  overflow: hidden;
  margin-right: 15px;
  flex-shrink: 0;
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-info {
  flex: 1;
  min-width: 0;
}

.item-info h4 {
  margin: 0 0 5px 0;
  font-size: 14px;
  font-weight: bold;
  color: #303133;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-info p {
  margin: 3px 0;
  font-size: 12px;
  color: #606266;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.remove-btn {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 28px;
  height: 28px;
  border: 1px solid #d9d9d9;
  background-color: #fff;
  border-radius: 50%;
  color: #606266;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  line-height: 1;
  
  &:hover {
    background-color: #fef0f0;
    border-color: #ffccc7;
    color: #f56c6c;
  }
}

/* 对比表格区域 */
.compare-table-section {
  margin-bottom: 20px;
}

.compare-table-card {
  padding: 20px;
}

.compare-table-wrapper {
  overflow-x: auto;
}

.compare-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 800px;
}

.compare-table th,
.compare-table td {
  padding: 15px;
  border-bottom: 1px solid #e8e8e8;
  text-align: left;
}

.attribute-header {
  background-color: #f5f7fa;
  font-weight: bold;
  color: #606266;
  width: 120px;
  position: sticky;
  left: 0;
  z-index: 1;
}

.artifact-header {
  background-color: #409eff;
  color: white;
  text-align: center;
  width: calc((100% - 120px) / 3);
}

.artifact-header-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.header-image {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid white;
}

.header-title {
  font-size: 14px;
  font-weight: bold;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.attribute-cell {
  background-color: #fafafa;
  font-weight: bold;
  color: #606266;
  position: sticky;
  left: 0;
  z-index: 1;
}

.value-cell {
  color: #303133;
  
  .highlight {
    background-color: #fff7e6;
    padding: 4px 8px;
    border-radius: 4px;
    color: #e6a23c;
    font-weight: bold;
  }
}

/* 差异总结 */
.difference-summary {
  margin-top: 20px;
  padding: 15px;
  background-color: #fff7e6;
  border-radius: 8px;
}

.difference-summary h4 {
  margin: 0 0 10px 0;
  color: #e6a23c;
  display: flex;
  align-items: center;
  gap: 8px;
}

.difference-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.no-difference {
  color: #67c23a;
  font-size: 14px;
}

/* 提示区域 */
.hint-section {
  margin-bottom: 20px;
}

.hint-card {
  padding: 0;
}

/* 响应式调整 */
@media (max-width: 768px) {
  .page-title {
    font-size: 24px;
  }
  
  .selected-item {
    flex-direction: column;
    text-align: center;
  }
  
  .item-image {
    margin-right: 0;
    margin-bottom: 10px;
  }
  
  .item-info p {
    white-space: normal;
  }
}
</style>
