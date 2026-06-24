<template>
  <div>
    <MainHeader></MainHeader>
    
    <!-- 排序选择区域 -->
    <div style="margin: 20px 200px;">
      <div style="display: flex; align-items: center; gap: 20px;">
        <span style="color: #666;">排序方式：</span>
        <el-select 
          v-model="sortBy" 
          placeholder="请选择排序方式"
          style="width: 180px;"
          @change="handleSort"
        >
          <el-option label="按名称排序" value="name" />
          <el-option label="按年代排序" value="period" />
          <el-option label="按更新时间排序" value="updateTime" />
        </el-select>
        <el-button 
          type="text" 
          @click="toggleSortOrder"
          :icon="sortOrder === 'asc' ? ArrowUp : ArrowDown"
        >
          {{ sortOrder === 'asc' ? '升序' : '降序' }}
        </el-button>
      </div>
    </div>

    <!-- 文物列表 -->
    <div style="font-size: 14px;">
      <div style="background-color: #eeeeee;color: gray;">
        <div style="margin: 0 200px;">
          <div style="display: flex;flex-wrap: wrap;gap: 20px;">
            <router-link to="/antiqueDetail" v-for="(item, index) in sortedProducts" :key="index">
              <div class="product" :style="'flex: 0 0 calc(20% - 16px);border: 1px solid #dfdfdf;'" :key="index">
                <div style="background-color: #FFFFFF;text-align: center;">
                  <div style="margin: 0 20px;">
                    <div>
                      <img :src="item.imageUrl" :alt="item.title">
                    </div>
                    <div style="font-size: 16px;font-weight: 500;height: 30px;overflow: hidden;text-overflow: ellipsis;">
                      {{ item.title }}
                    </div>
                    <div style="font-size: 12px;height: 24px;overflow: hidden;text-overflow: ellipsis;color: #999;">
                      {{ item.period || item.dynasty }}
                    </div>
                    <div style="font-size: 12px;height: 24px;overflow: hidden;text-overflow: ellipsis;color: #666;">
                      {{ item.museum }}
                    </div>
                  </div>
                </div>
              </div>
            </router-link>
          </div>
        </div>
      </div>
    </div>

    <MainFooter></MainFooter>
  </div>
</template>

<script>
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'
import { ArrowUp, ArrowDown } from '@element-plus/icons-vue'

export default {
  components: {
    MainHeader, 
    MainFooter,
    ArrowUp,
    ArrowDown
  },
  data () {
    return {
      sortBy: 'name',           // 排序字段: name, period, updateTime
      sortOrder: 'asc',         // 排序顺序: asc, desc
      products: [
        {
          objectId: 'obj001',
          title: '青花瓷瓶',
          period: '清朝',
          dynasty: '清',
          periodStartYear: 1644,
          periodEndYear: 1912,
          museum: '史密森尼博物馆',
          imageUrl: 'https://picsum.photos/seed/antique1/200/200'
        },
        {
          objectId: 'obj002',
          title: '青铜鼎',
          period: '周朝',
          dynasty: '周',
          periodStartYear: -1046,
          periodEndYear: 256,
          museum: '哈佛大学艺术博物馆',
          imageUrl: 'https://picsum.photos/seed/antique2/200/200'
        },
        {
          objectId: 'obj003',
          title: '陶瓷骏马',
          period: '唐朝',
          dynasty: '唐',
          periodStartYear: 618,
          periodEndYear: 907,
          museum: '波士顿美术馆',
          imageUrl: 'https://picsum.photos/seed/antique3/200/200'
        },
        {
          objectId: 'obj004',
          title: '玉如意',
          period: '明朝',
          dynasty: '明',
          periodStartYear: 1368,
          periodEndYear: 1644,
          museum: '史密森尼博物馆',
          imageUrl: 'https://picsum.photos/seed/antique4/200/200'
        },
        {
          objectId: 'obj005',
          title: '书法卷轴',
          period: '宋朝',
          dynasty: '宋',
          periodStartYear: 960,
          periodEndYear: 1279,
          museum: '哈佛大学艺术博物馆',
          imageUrl: 'https://picsum.photos/seed/antique5/200/200'
        },
        {
          objectId: 'obj006',
          title: '唐三彩',
          period: '唐朝',
          dynasty: '唐',
          periodStartYear: 618,
          periodEndYear: 907,
          museum: '波士顿美术馆',
          imageUrl: 'https://picsum.photos/seed/antique6/200/200'
        },
        {
          objectId: 'obj007',
          title: '紫砂壶',
          period: '明朝',
          dynasty: '明',
          periodStartYear: 1368,
          periodEndYear: 1644,
          museum: '史密森尼博物馆',
          imageUrl: 'https://picsum.photos/seed/antique7/200/200'
        },
        {
          objectId: 'obj008',
          title: '古钱币',
          period: '汉朝',
          dynasty: '汉',
          periodStartYear: -202,
          periodEndYear: 220,
          museum: '哈佛大学艺术博物馆',
          imageUrl: 'https://picsum.photos/seed/antique8/200/200'
        }
      ],
      res: ''
    }
  },
  created () {
    this.res = this.$route.query.id
  },
  computed: {
    sortedProducts () {
      const sorted = [...this.products]
      const order = this.sortOrder === 'asc' ? 1 : -1
      
      sorted.sort((a, b) => {
        let result = 0
        
        switch (this.sortBy) {
          case 'name':
            // 按名称排序（中文拼音排序）
            result = a.title.localeCompare(b.title, 'zh-CN')
            break
          case 'period':
            // 按年代排序（按起始年份）
            const yearA = a.periodStartYear || 0
            const yearB = b.periodStartYear || 0
            result = yearA - yearB
            break
          case 'updateTime':
            // 按更新时间排序（模拟数据）
            // 在实际项目中，这里会使用 crawlDate 字段
            result = a.objectId.localeCompare(b.objectId)
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
    handleSort () {
      // 排序方式改变时触发
      console.log('排序方式:', this.sortBy)
    },
    toggleSortOrder () {
      // 切换排序顺序
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc'
    },
    handleSizeChange (val) {
      console.log(`每页 ${val} 条`)
    },
    handleCurrentChange (val) {
      console.log(`当前页: ${val}`)
    },
    handleClick (tab, event) {
      console.log(tab, event)
    }
  }
}
</script>

<style scoped>
.product {
  cursor: pointer;
  margin-bottom: 20px;
  transition: all 0.3s ease;
}

.product:hover {
  transform: scale(1.05);
  border-top: 1px solid red!important;
}

.product img {
  width: 150px;
  height: 150px;
  object-fit: cover;
  margin: 10px 0;
}
</style>
