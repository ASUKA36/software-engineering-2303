<template>
  <div class="antique-list-container">
    <!-- 视图切换和排序控制栏 -->
    <div class="controls-bar">
      <div class="view-toggle">
        <el-button-group>
          <el-button 
            :type="viewMode === 'card' ? 'primary' : 'default'"
            @click="viewMode = 'card'"
            icon="el-icon-s-grid"
          >
            卡片视图
          </el-button>
          <el-button 
            :type="viewMode === 'list' ? 'primary' : 'default'"
            @click="viewMode = 'list'"
            icon="el-icon-s-fold"
          >
            列表视图
          </el-button>
        </el-button-group>
      </div>
      
      <div class="sort-controls">
        <span style="color: #666;">排序方式：</span>
        <el-select 
          v-model="currentSort" 
          placeholder="请选择排序方式"
          style="width: 180px;"
          @change="handleSort"
        >
          <el-option label="按名称排序" value="name"></el-option>
          <el-option label="按年代排序" value="period"></el-option>
          <el-option label="按更新时间排序" value="updateTime"></el-option>
        </el-select>
        <el-button 
          type="text" 
          @click="toggleSortOrder"
          style="margin-left: 10px;"
        >
          {{ sortOrder === 'asc' ? '↑ 升序' : '↓ 降序' }}
        </el-button>
      </div>
    </div>

    <!-- 卡片视图 -->
    <div v-if="viewMode === 'card'" class="card-view">
      <el-row :gutter="20">
        <el-col 
          v-for="(item, index) in sortedData" 
          :key="index"
          :xs="24" 
          :sm="12" 
          :md="8" 
          :lg="6"
          :xl="4"
        >
          <div class="card-item">
            <el-card 
              :body-style="{ padding: '0px' }" 
              class="antique-card"
              shadow="hover"
            >
              <router-link 
                :to="{path: '/antiqueDetail', query: {museum_id: item.museum_id, object_id: item.object_id}}"
                class="card-link"
              >
                <div class="image-container">
                  <img 
                    :src="getValidImageUrl(item)" 
                    class="card-image" 
                    alt=""
                    @error="handleImageError($event)"
                  >
                </div>
                <div class="card-content">
                  <h3 class="card-title">{{ getTitle(item.title) }}</h3>
                  <p class="card-meta">{{ getDynasty(item.dynasty) }} · {{ getType(item.type) }}</p>
                  <p class="card-museum">{{ item.museum || '未知' }}</p>
                </div>
              </router-link>
              <div class="card-actions">
                <el-button 
                  :type="isInCompare(item) ? 'success' : 'default'"
                  size="small"
                  @click.stop="addToCompare(item)"
                  :icon="isInCompare(item) ? 'el-icon-check' : 'el-icon-s-plus'"
                >
                  {{ isInCompare(item) ? '已加入对比' : '加入对比' }}
                </el-button>
                <el-button 
                  v-if="getCompareList().length >= 2"
                  type="warning"
                  size="small"
                  @click.stop="goToCompare"
                  icon="el-icon-data-line"
                >
                  查看对比
                </el-button>
              </div>
            </el-card>
          </div>
        </el-col>
      </el-row>
    </div>

    <!-- 列表视图 -->
    <div v-if="viewMode === 'list'" class="list-view">
      <!-- 对比提示栏 -->
      <div v-if="getCompareList().length >= 2" class="compare-tip-bar">
        <span>已选择 {{ getCompareList().length }} 件文物</span>
        <el-button type="warning" size="small" @click="goToCompare">
          <i class="el-icon-data-line"></i>
          查看对比
        </el-button>
      </div>
      
      <el-table 
        :data="sortedData" 
        stripe 
        style="width: 100%"
        :default-sort="{ prop: 'title', order: 'ascending' }"
        @sort-change="handleTableSort"
      >
        <el-table-column label="图片" width="120">
          <template v-slot="scope">
            <router-link 
              :to="{path: '/antiqueDetail', query: {museum_id: scope.row.museum_id, object_id: scope.row.object_id}}"
            >
              <img :src="getValidImageUrl(scope.row)" class="list-image" alt="">
            </router-link>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="文物名称" width="200" sortable>
          <template v-slot="scope">
            <router-link 
              :to="{path: '/antiqueDetail', query: {museum_id: scope.row.museum_id, object_id: scope.row.object_id}}"
              class="table-link"
            >
              {{ getTitle(scope.row.title) }}
            </router-link>
          </template>
        </el-table-column>
        <el-table-column prop="dynasty" label="朝代" width="120">
          <template v-slot="scope">
            {{ getDynasty(scope.row.dynasty) }}
          </template>
        </el-table-column>
        <el-table-column prop="period_start_year" label="年代" width="100" sortable>
          <template v-slot="scope">
            {{ formatYear(scope.row.period_start_year) }}
          </template>
        </el-table-column>
        <el-table-column prop="type" label="类型" width="120" sortable>
          <template v-slot="scope">
            {{ getType(scope.row.type) }}
          </template>
        </el-table-column>
        <el-table-column prop="material" label="材质" width="120" sortable>
          <template v-slot="scope">
            {{ scope.row.material || '未知' }}
          </template>
        </el-table-column>
        <el-table-column prop="museum" label="博物馆" width="180" sortable>
          <template v-slot="scope">
            {{ scope.row.museum || '未知' }}
          </template>
        </el-table-column>
        <el-table-column prop="artist" label="作者" width="150" sortable>
          <template v-slot="scope">
            {{ scope.row.artist || '未知' }}
          </template>
        </el-table-column>
        <el-table-column prop="description" label="简介" min-width="200" show-overflow-tooltip>
          <template v-slot="scope">
            {{ scope.row.description || '暂无简介' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template v-slot="scope">
            <el-button 
              type="text" 
              size="small"
              @click="goToDetail(scope.row)"
            >
              查看详情
            </el-button>
            <el-button 
              :type="isInCompare(scope.row) ? 'success' : 'default'" 
              size="small"
              @click.stop="addToCompare(scope.row)"
            >
              {{ isInCompare(scope.row) ? '已对比' : '对比' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 空状态提示 -->
    <el-empty 
      v-if="!data || data.length === 0" 
      description="暂无文物数据"
    ></el-empty>
  </div>
</template>

<script>
export default {
  name: 'AntiqueList',
  props: {
    // 文物数据数组
    data: {
      type: Array,
      default: () => []
    },
    // 默认排序方式
    defaultSort: {
      type: String,
      default: 'name'
    },
    // 默认排序顺序
    defaultOrder: {
      type: String,
      default: 'asc'
    },
    // 对比数量（用于监听清空事件）
    compareCount: {
      type: Number,
      default: 0
    }
  },
  data () {
    return {
      viewMode: 'card', // 默认卡片视图
      currentSort: '',
      sortOrder: 'asc',
      defaultImage: 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200"%3E%3Crect fill="%23f5f5f5" width="200" height="200"/%3E%3Ctext fill="%23999" font-family="sans-serif" font-size="14" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E暂无图片%3C/text%3E%3C/svg%3E',
      // 服务器图片API地址（仅用于博物馆2、3）
      serverApiBase: 'http://47.96.152.190:8000',
      // 响应式对比列表
      compareList: []
    }
  },
  mounted () {
    // 延迟初始化排序参数，避免 el-select 初始化问题
    setTimeout(() => {
      this.currentSort = this.defaultSort || 'name'
      this.sortOrder = this.defaultOrder || 'asc'
    }, 100)
  },
  created () {
    // 初始化对比列表
    const stored = localStorage.getItem('compareList')
    if (stored) {
      try {
        this.compareList = JSON.parse(stored)
      } catch (e) {
        this.compareList = []
      }
    }
  },
  watch: {
    // 监听对比数量变化，当变为0时刷新状态
    compareCount (newVal) {
      if (newVal === 0) {
        this.compareList = []
      }
    }
  },
  computed: {
    sortedData () {
      console.log('AntiqueList - 原始数据:', this.data ? this.data.length : 'null/undefined')
      if (!this.data || this.data.length === 0) {
        console.log('AntiqueList - 数据为空')
        return []
      }
      
      // 过滤掉 undefined 或 null 的数据项
      const validData = this.data.filter(item => item !== undefined && item !== null)
      
      console.log('AntiqueList - 过滤后数据:', validData.length)
      
      if (validData.length === 0) {
        console.log('AntiqueList - 过滤后数据为空')
        return []
      }
      
      // 字段映射，兼容新旧字段名
      const mappedData = validData.map(item => {
        // 优先使用新字段名，其次使用旧字段名
        const mapped = {
          ...item,
          id: item.id,
          object_id: item.object_id || item.id,
          title: item.title || item.object_name || item.cat1 || '未知',
          dynasty: item.dynasty || item.cat2 || '未知',
          type: item.type || item.cat3 || '未知',
          material: item.material || item.cat1 || '未知',
          artist: item.artist || item.makers_name || '未知',
          image_url: item.image_url || item.img_url || ''
        }
        return mapped
      })
      
      const sorted = [...mappedData]
      const order = this.sortOrder === 'asc' ? 1 : -1
      
      // 朝代英文名称到序号的映射表（按历史时间先后）
      const dynastyOrder = {
        'Neolithic': 1,
        'Xia': 2,
        'Shang': 3,
        'Zhou': 4,
        'Western Zhou': 5,
        'Eastern Zhou': 6,
        'Spring and Autumn period': 7,
        'Warring States period': 8,
        'Qin': 9,
        'Han': 10,
        'Western Han': 11,
        'Eastern Han': 12,
        'Three Kingdoms': 13,
        'Wei': 14,
        'Jin': 15,
        'Western Jin': 16,
        'Eastern Jin': 17,
        'Southern and Northern Dynasties': 18,
        'Sui': 19,
        'Tang': 20,
        'Five Dynasties and Ten Kingdoms': 21,
        'Song': 22,
        'Northern Song': 23,
        'Southern Song': 24,
        'Liao': 25,
        'Jin': 26,
        'Yuan': 27,
        'Ming': 28,
        'Qing': 29,
        'Republic of China': 30,
        'Modern': 31
      }
      
      // 提取朝代名称的英文部分（处理各种格式）
      const extractDynastyKey = (dynasty) => {
        if (!dynasty) return ''
        // 匹配格式：英文部分（中文部分） 或 英文部分+乱码
        const match = dynasty.match(/^([A-Za-z][A-Za-z\s]*)/)
        return match ? match[1].trim() : dynasty
      }
      
      sorted.sort((a, b) => {
        let result = 0
        let yearA, yearB, dateA, dateB, dynastyA, dynastyB, dynastyOrderA, dynastyOrderB

        switch (this.currentSort) {
          case 'name':
            result = (a.title || '').localeCompare(b.title || '', 'zh-CN')
            break
          case 'period':
            yearA = a.period_start_year || 0
            yearB = b.period_start_year || 0
            result = yearA - yearB
            break
          case 'updateTime':
            dateA = a.crawl_date ? new Date(a.crawl_date).getTime() : 0
            dateB = b.crawl_date ? new Date(b.crawl_date).getTime() : 0
            result = dateA - dateB
            break
          case 'dynasty':
            // 按朝代历史时间顺序排序
            // 使用正则提取朝代名称的英文部分（处理编码问题）
            dynastyA = extractDynastyKey(a.dynasty)
            dynastyB = extractDynastyKey(b.dynasty)
            dynastyOrderA = dynastyOrder[dynastyA] || 999
            dynastyOrderB = dynastyOrder[dynastyB] || 999
            console.log('朝代排序:', a.dynasty, '->', dynastyA, '(', dynastyOrderA, ')', 'vs', b.dynasty, '->', dynastyB, '(', dynastyOrderB, ')')
            result = dynastyOrderA - dynastyOrderB
            break
          case 'type':
            result = (a.type || '').localeCompare(b.type || '', 'zh-CN')
            break
          case 'material':
            result = (a.material || '').localeCompare(b.material || '', 'zh-CN')
            break
          case 'museum':
            result = (a.museum || '').localeCompare(b.museum || '', 'zh-CN')
            break
          case 'artist':
            result = (a.artist || '').localeCompare(b.artist || '', 'zh-CN')
            break
          default:
            result = 0
        }
        
        return result * order
      })
      
      return sorted
    }
  },
  methods: {
    // 处理排序变化
    handleSort () {
      console.log('排序方式:', this.currentSort)
      this.$emit('sort-change', {
        sort: this.currentSort,
        order: this.sortOrder
      })
    },
    
    // 切换排序顺序
    toggleSortOrder () {
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc'
      this.handleSort()
    },
    
    // 处理表格列排序点击
    handleTableSort ({ prop, order }) {
      console.log('表格排序:', prop, order)
      // 根据表格列的prop映射到内部排序字段
      const propMap = {
        'title': 'name',
        'dynasty': 'dynasty',
        'period_start_year': 'period',
        'type': 'type',
        'material': 'material',
        'museum': 'museum',
        'artist': 'artist'
      }
      
      if (prop && propMap[prop]) {
        this.currentSort = propMap[prop]
        this.sortOrder = order === 'ascending' ? 'asc' : 'desc'
        this.handleSort()
      }
    },
    
    // 格式化年代显示
    formatYear (year) {
      if (!year) return '未知'
      if (year < 0) {
        return `公元前${Math.abs(year)}年`
      }
      return `${year}年`
    },
    
    // 校验图片URL是否有效
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
      
      // 其他博物馆（如博物馆1）使用原有逻辑
      if (!imageUrl || imageUrl === 'null' || imageUrl === 'undefined') {
        return this.defaultImage
      }
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        return this.defaultImage
      }
      return imageUrl
    },
    
    // 跳转到详情页
    goToDetail (item) {
      this.$router.push({
        path: '/antiqueDetail',
        query: {
          museum_id: item.museum_id,
          object_id: item.object_id
        }
      })
    },
    
    // 切换视图模式
    setViewMode (mode) {
      this.viewMode = mode
      this.$emit('view-change', mode)
    },
    
    // 检查文物是否已在对比列表中
    isInCompare (item) {
      if (!item) return false
      // 使用 img_url 作为唯一标识符（因为 id 和 object_id 都是 null）
      const itemId = item.image_url || item.img_url || item.object_id || item.id
      // 如果 itemId 不存在，直接返回 false
      if (!itemId || itemId === 'null' || itemId === null) return false
      return this.compareList.some(compareItem => {
        if (!compareItem) return false
        const compareId = compareItem.image_url || compareItem.img_url || compareItem.object_id || compareItem.id
        // 必须两边都有有效的 ID 才能匹配
        if (!compareId || compareId === 'null' || compareId === null) return false
        return compareId === itemId
      })
    },
    
    // 获取对比列表（用于模板中直接调用）
    getCompareList () {
      return this.compareList
    },
    
    // 添加到对比列表
    addToCompare (item) {
      // 验证item有效性
      if (!item) {
        this.$message.error('文物信息无效')
        return
      }
      // 使用 img_url 作为唯一标识符（因为 id 和 object_id 都是 null）
      const itemId = item.image_url || item.img_url || item.object_id || item.id
      // 严格验证 ID
      if (!itemId || itemId === 'null' || itemId === null) {
        this.$message.error('文物信息无效')
        return
      }
      
      // 检查是否已存在
      const existingIndex = this.compareList.findIndex(compareItem => {
        if (!compareItem) return false
        const compareId = compareItem.image_url || compareItem.img_url || compareItem.object_id || compareItem.id
        return compareId && compareId === itemId
      })
      
      if (existingIndex !== -1) {
        // 移除
        this.compareList.splice(existingIndex, 1)
        localStorage.setItem('compareList', JSON.stringify(this.compareList))
        this.$message.success('已从对比列表中移除')
        this.$emit('compare-change', this.compareList.length)
        return
      }
      
      // 检查是否超过3件
      if (this.compareList.length >= 3) {
        this.$message.warning('最多只能选择3件文物进行对比')
        return
      }
      
      // 添加
      const compareItem = {
        id: item.id,
        museum_id: item.museum_id,
        object_id: item.object_id,
        title: item.title || '未知',
        dynasty: item.dynasty || '未知',
        type: item.type || '未知',
        material: item.material || '未知',
        museum: item.museum || '未知',
        artist: item.artist || '未知',
        dimensions: item.dimensions || '',
        accession_number: item.accession_number || '',
        period_start_year: item.period_start_year,
        period_end_year: item.period_end_year,
        culture: item.culture || '',
        image_url: item.image_url || '',
        img_url: item.img_url || ''
      }
      this.compareList.push(compareItem)
      localStorage.setItem('compareList', JSON.stringify(this.compareList))
      
      this.$message.success(`已加入对比列表（${this.compareList.length}/3）`)
      this.$emit('compare-change', this.compareList.length)
      
      // 如果已选择2件以上，提示可以查看对比
      if (this.compareList.length >= 2) {
        this.$message.info('已选择2件以上文物，可以查看对比了')
      }
    },
    
    // 获取标题（处理未命名情况）
    getTitle (title) {
      if (!title || title === 'null' || title === 'undefined' || title === '') {
        return '未命名文物'
      }
      // 处理数据库中存储的 "(untitled)" 情况
      if (title.toLowerCase() === '(untitled)') {
        return '未命名文物'
      }
      return title
    },
    
    // 获取朝代（处理空值情况）
    getDynasty (dynasty) {
      if (!dynasty || dynasty === 'null' || dynasty === 'undefined' || dynasty === '') {
        return '未知朝代'
      }
      return dynasty
    },
    
    // 获取类型（处理空值情况）
    getType (type) {
      if (!type || type === 'null' || type === 'undefined' || type === '') {
        return '未知类型'
      }
      return type
    },
    
    // 处理图片加载失败
    handleImageError (event) {
      const img = event.target
      // 如果图片还没有被替换过，替换为默认图片
      if (!img.dataset.hasFallback) {
        img.src = this.defaultImage
        img.dataset.hasFallback = 'true'
      }
    },
    
    // 跳转到对比页面
    goToCompare () {
      this.$router.push('/antiqueCompare')
    }
  }
}
</script>

<style scoped>
.antique-list-container {
  width: 100%;
  padding: 20px;
  line-height: normal;
}

/* 控制栏样式 */
.controls-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 15px;
  background-color: #f5f7fa;
  border-radius: 4px;
}

.view-toggle {
  display: flex;
  gap: 10px;
}

.sort-controls {
  display: flex;
  align-items: center;
}

/* 卡片视图样式 */
.card-view {
  padding: 10px 0;
  line-height: normal;
}

.card-item {
  margin-bottom: 20px;
}

.antique-card {
  transition: all 0.3s ease;
  height: 100%;
}

.antique-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
}

.card-link {
  text-decoration: none;
  color: inherit;
  display: block;
}

.image-container {
  width: 100%;
  height: 280px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f5f5f5;
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-content {
  padding: 10px;
}

.card-title {
  margin: 0 0 6px 0;
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-meta {
  margin: 0 0 4px 0;
  font-size: 12px;
  color: #606266;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-museum {
  margin: 0;
  font-size: 11px;
  color: #909399;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-actions {
  padding: 8px 12px;
  border-top: 1px solid #e8e8e8;
  display: flex;
  justify-content: center;
  gap: 8px;
}

.card-actions .el-button {
  padding: 4px 12px;
  font-size: 12px;
}

/* 列表视图样式 */
.list-view {
  padding: 10px 0;
  line-height: normal;
}

.compare-tip-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background-color: #fff7e6;
  border-radius: 4px;
  margin-bottom: 15px;
  color: #e6a23c;
  font-weight: bold;
}

.list-image {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 4px;
  cursor: pointer;
  transition: transform 0.3s ease;
}

.list-image:hover {
  transform: scale(1.1);
}

.table-link {
  color: #409eff;
  text-decoration: none;
  font-weight: 500;
}

.table-link:hover {
  text-decoration: underline;
}

/* 响应式调整 */
@media (max-width: 768px) {
  .controls-bar {
    flex-direction: column;
    gap: 15px;
    align-items: flex-start;
  }
  
  .sort-controls {
    flex-wrap: wrap;
  }
  
  .image-container {
    height: 200px;
  }
}

/* 空状态样式 */
.el-empty {
  margin-top: 50px;
}
</style>
