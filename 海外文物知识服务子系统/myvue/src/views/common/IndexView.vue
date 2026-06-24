<template>
  <div class="main-index">
    <MainHeader></MainHeader>
    
    <!-- 轮播图区域 -->
    <div class="hero-section">
      <el-carousel :interval="5000" type="card" height="450px" indicator-position="bottom">
        <el-carousel-item v-for="(item, index) in carouselImages" :key="index">
          <div class="carousel-item-wrapper">
            <img :src="item.image" class="carousel-img" :alt="item.title">
            <div class="carousel-overlay">
              <h2 class="carousel-title">{{ item.title }}</h2>
              <p class="carousel-desc">{{ item.description }}</p>
              <el-button type="primary" @click="goToDetail(item.objectId, item.museumId)">探索详情</el-button>
            </div>
          </div>
        </el-carousel-item>
      </el-carousel>
    </div>



    <!-- 精选文物展示 -->
    <div class="featured-section">
      <div class="section-header">
        <div class="section-title-wrapper">
          <i class="el-icon-star"></i>
          <h2>精选文物</h2>
        </div>
        <router-link to="/classify" class="view-all">查看全部 →</router-link>
      </div>
      <div class="featured-grid">
        <div 
          v-for="(item, index) in featuredAntiques" 
          :key="index" 
          class="antique-card"
          @click="goToDetail(item.object_id, item.museum_id)"
        >
          <div class="card-image">
            <img :src="getValidImageUrl(item.image_url || item.img_url)" :alt="item.title || item.object_name">
            <div class="card-overlay">
              <span class="dynasty-tag">{{ formatDynasty(item.dynasty) }}</span>
            </div>
          </div>
          <div class="card-content">
            <h3 class="card-title">{{ item.title || item.object_name }}</h3>
            <p class="card-museum">{{ item.museum }}</p>
            <div class="card-meta">
              <span class="material">{{ item.material || item.cat1 }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 热门朝代 -->
    <div class="featured-section dynasty-section">
      <div class="section-header">
        <div class="section-title-wrapper">
          <i class="el-icon-calendar"></i>
          <h2>热门朝代</h2>
        </div>
        <router-link to="/classify_dynasty" class="view-all">查看全部 →</router-link>
      </div>
      <div class="dynasty-grid">
        <router-link 
          v-for="(dynasty, index) in popularDynasties" 
          :key="index"
          :to="{ path: '/classify_dynasty', query: { dynasty: dynasty.name } }"
          class="dynasty-card"
        >
          <div class="dynasty-icon">{{ dynasty.icon }}</div>
          <div class="dynasty-info">
            <p>{{ dynasty.desc }}</p>
            <span class="item-count">{{ dynasty.count }}件文物</span>
          </div>
        </router-link>
      </div>
    </div>

    <!-- 海外博物馆 -->
    <div class="featured-section">
      <div class="section-header">
        <div class="section-title-wrapper">
          <i class="el-icon-globe"></i>
          <h2>海外博物馆</h2>
        </div>
        <router-link to="/classify_muse" class="view-all">查看全部 →</router-link>
      </div>
      <div class="museum-grid">
        <router-link 
          v-for="(museum, index) in museums" 
          :key="index"
          :to="{ path: '/classify_muse', query: { museum: museum.name } }"
          class="museum-card"
        >
          <div class="museum-image">
            <img :src="museum.image" :alt="museum.name">
          </div>
          <div class="museum-info">
            <h3>{{ museum.name }}</h3>
            <p class="museum-location">{{ museum.location }}</p>
            <span class="museum-count">{{ museum.count }}件馆藏</span>
          </div>
        </router-link>
      </div>
    </div>

    <!-- 近期更新 -->
    <div class="featured-section">
      <div class="section-header">
        <div class="section-title-wrapper">
          <i class="el-icon-refresh"></i>
          <h2>近期更新</h2>
        </div>
      </div>
      <div class="update-list">
        <div 
          v-for="(item, index) in recentUpdates" 
          :key="index" 
          class="update-item"
          @click="goToDetail(item.object_id, item.museum_id)"
        >
          <img :src="getValidImageUrl(item.image_url || item.img_url)" class="update-image" :alt="item.title">
          <div class="update-content">
            <h4>{{ item.title || item.object_name }}</h4>
            <p class="update-meta">{{ item.museum }} · {{ formatDynasty(item.dynasty) }}</p>
            <span class="update-time">{{ item.updateTime }}</span>
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
import axios from 'axios'

export default {
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    return {
      carouselImages: [],
      featuredAntiques: [],
      museums: [],
      recentUpdates: [],
      popularDynasties: [
        { name: '唐朝', icon: '唐', desc: '盛世华章，文化繁荣', count: 273 },
        { name: '宋朝', icon: '宋', desc: '风雅美学，科技发达', count: 625 },
        { name: '明朝', icon: '明', desc: '工艺精湛，商业繁荣', count: 816 },
        { name: '清朝', icon: '清', desc: '文化融合，藏品丰富', count: 2209 },
        { name: '汉朝', icon: '汉', desc: '丝绸之路，中西交流', count: 590 },
        { name: '商朝', icon: '商', desc: '青铜文明，甲骨文', count: 216 }
      ],
      stats: {
        antiques: 0,
        museums: 0,
        dynasties: 0,
        visitors: '125.8万'
      },
      defaultImage: 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="200" height="200"%3E%3Crect fill="%23f5f5f5" width="200" height="200"/%3E%3Ctext fill="%23999" font-family="sans-serif" font-size="14" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E暂无图片%3C/text%3E%3C/svg%3E'
    }
  },
  mounted () {
    this.loadCarousel()
    this.loadFeaturedAntiques()
    this.loadMuseums()
    this.loadRecentUpdates()
    this.loadStats()
  },
  methods: {
    // 加载轮播图数据
    loadCarousel () {
      axios.post('http://localhost:8085/search/classification', { c: 'dynasty', v_1: 'Tang（唐）' })
        .then(response => {
          if (response.data.state === 200 && response.data.data.length > 0) {
            const items = response.data.data.slice(0, 5)
            this.carouselImages = items.map(item => ({
              image: item.image_url || item.img_url || this.defaultImage,
              title: item.title || item.object_name || '大唐风华',
              description: item.description || '感受丝绸之路的文化内涵',
              objectId: item.object_id,
              museumId: item.museum_id
            }))
          }
        })
        .catch(() => {
          // 备用轮播图
          this.carouselImages = [
            { image: 'https://picsum.photos/seed/tang1/1200/450', title: '大唐风华', description: '感受丝绸之路的文化内涵', objectId: '', museumId: '' },
            { image: 'https://picsum.photos/seed/song1/1200/450', title: '宋韵雅致', description: '品味宋代文人的风雅生活', objectId: '', museumId: '' },
            { image: 'https://picsum.photos/seed/ming1/1200/450', title: '大明匠心', description: '领略明代工艺的精湛之美', objectId: '', museumId: '' },
            { image: 'https://picsum.photos/seed/qing1/1200/450', title: '清宫遗珍', description: '探索清代宫廷的奢华收藏', objectId: '', museumId: '' },
            { image: 'https://picsum.photos/seed/han1/1200/450', title: '汉风古韵', description: '追溯两汉时期的雄浑气象', objectId: '', museumId: '' }
          ]
        })
    },

    // 加载精选文物
    loadFeaturedAntiques () {
      axios.post('http://localhost:8085/search/classification', { c: 'mart', v_1: 'bronze' })
        .then(response => {
          if (response.data.state === 200) {
            this.featuredAntiques = response.data.data.slice(0, 8)
          }
        })
        .catch(() => {
          this.featuredAntiques = this.getMockAntiques()
        })
    },

    // 加载博物馆数据
    loadMuseums () {
      axios.get('http://localhost:8085/search/filters')
        .then(response => {
          if (response.data.state === 200 && response.data.data.museums) {
            const museumNames = response.data.data.museums.slice(0, 3)
            this.museums = museumNames.map((name, index) => ({
              name: name,
              location: this.getMuseumLocation(name),
              image: `https://picsum.photos/seed/museum${index + 1}/400/300`,
              count: Math.floor(Math.random() * 100) + 100
            }))
          }
        })
        .catch(() => {
          // 默认博物馆数据
          this.museums = [
            { name: 'British Museum', location: '英国伦敦', image: 'https://picsum.photos/seed/british/400/300', count: 234 },
            { name: 'Metropolitan Museum of Art', location: '美国纽约', image: 'https://picsum.photos/seed/met/400/300', count: 189 },
            { name: 'Musée du Louvre', location: '法国巴黎', image: 'https://picsum.photos/seed/louvre/400/300', count: 156 }
          ]
        })
    },
    
    // 获取博物馆位置
    getMuseumLocation (museumName) {
      const locations = {
        'Harvard Art Museums': '美国马萨诸塞州剑桥',
        'Museum of Fine Arts, Boston': '美国马萨诸塞州波士顿',
        'Smithsonian Institution': '美国华盛顿特区',
       
      }
      return locations[museumName] || '未知'
    },

    // 加载近期更新
    loadRecentUpdates () {
      axios.post('http://localhost:8085/search/classification', { c: 'dynasty', v_1: 'Ming（明）' })
        .then(response => {
          if (response.data.state === 200) {
            this.recentUpdates = response.data.data.slice(0, 5).map(item => ({
              ...item,
              updateTime: '刚刚更新'
            }))
          }
        })
        .catch(() => {
          this.recentUpdates = []
        })
    },

    // 加载统计数据
    loadStats () {
      axios.get('http://localhost:8085/search/filters')
        .then(response => {
          if (response.data.state === 200 && response.data.data) {
            const filters = response.data.data
            this.stats.museums = filters.museums ? filters.museums.length : 0
            this.stats.dynasties = filters.dynasties ? filters.dynasties.length : 0
          }
        })
        .catch(() => {
          this.stats.museums = 3
          this.stats.dynasties = 24
        })
      
      // 获取文物总数
      axios.post('http://localhost:8085/search/classification', { c: 'dynasty', v_1: 'Tang' })
        .then(response => {
          if (response.data.state === 200) {
            this.stats.antiques = response.data.data.length
          }
        })
        .catch(() => {
          this.stats.antiques = 100
        })
    },

    // 获取模拟文物数据（死数据）
    getMockAntiques () {
      return [
        { object_id: '1', museum_id: '1', title: '青铜方鼎', dynasty: '商', material: '青铜', museum: '大英博物馆', image_url: 'https://picsum.photos/seed/bronze1/300/300' },
        { object_id: '2', museum_id: '2', title: '唐三彩骆驼', dynasty: '唐', material: '陶瓷', museum: '大都会艺术博物馆', image_url: 'https://picsum.photos/seed/tang1/300/300' },
        { object_id: '3', museum_id: '3', title: '青花瓷瓶', dynasty: '明', material: '瓷器', museum: '卢浮宫', image_url: 'https://picsum.photos/seed/ming1/300/300' },
        { object_id: '4', museum_id: '4', title: '珐琅彩碗', dynasty: '清', material: '珐琅', museum: '东京国立博物馆', image_url: 'https://picsum.photos/seed/qing1/300/300' },
        { object_id: '5', museum_id: '1', title: '玉璧', dynasty: '汉', material: '玉器', museum: '大英博物馆', image_url: 'https://picsum.photos/seed/han1/300/300' },
        { object_id: '6', museum_id: '2', title: '汝窑青瓷', dynasty: '宋', material: '瓷器', museum: '大都会艺术博物馆', image_url: 'https://picsum.photos/seed/song1/300/300' },
        { object_id: '7', museum_id: '3', title: '鎏金佛像', dynasty: '北魏', material: '金铜', museum: '卢浮宫', image_url: 'https://picsum.photos/seed/buddha1/300/300' },
        { object_id: '8', museum_id: '4', title: '丝绸刺绣', dynasty: '清', material: '丝织', museum: '东京国立博物馆', image_url: 'https://picsum.photos/seed/silk1/300/300' }
      ]
    },

    // 校验图片URL
    getValidImageUrl (imageUrl) {
      if (!imageUrl || imageUrl === 'null' || imageUrl === 'undefined') {
        return this.defaultImage
      }
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        return this.defaultImage
      }
      return imageUrl
    },

    // 格式化朝代显示
    formatDynasty (dynasty) {
      if (!dynasty) return '未知'
      // 提取中文部分
      const match = dynasty.match(/（(.+?)）/)
      return match ? match[1] : dynasty
    },

    // 跳转到详情页
    goToDetail (objectId, museumId) {
      if (objectId && museumId) {
        this.$router.push({
          path: '/antiqueDetail',
          query: { museum_id: museumId, object_id: objectId }
        })
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.hero-section {
  padding: 20px 5%;
  margin-top: 10px;
}

.carousel-item-wrapper {
  position: relative;
  height: 100%;
}

.carousel-img {
  width: 100%;
  height: 450px;
  object-fit: cover;
  border-radius: 8px;
}

.carousel-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 40px;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
  border-radius: 0 0 8px 8px;
  color: #fff;
}

.carousel-title {
  font-size: 36px;
  font-weight: 700;
  margin-bottom: 10px;
}

.carousel-desc {
  font-size: 16px;
  opacity: 0.9;
  margin-bottom: 20px;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  max-height: 72px;
}

.featured-section {
  padding: 40px 5%;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.section-title-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 24px;
  font-weight: 600;
  color: #333;
}

.view-all {
  color: #667eea;
  text-decoration: none;
  font-size: 14px;
  
  &:hover {
    color: #764ba2;
  }
}

.featured-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 25px;
}

.antique-card {
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  cursor: pointer;
  
  &:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
  }
}

.card-image {
  position: relative;
  height: 220px;
  overflow: hidden;
}

.card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-overlay {
  position: absolute;
  top: 15px;
  left: 15px;
}

.dynasty-tag {
  background: rgba(0, 0, 0, 0.6);
  color: #fff;
  padding: 5px 12px;
  border-radius: 15px;
  font-size: 12px;
}

.card-content {
  padding: 20px;
}

.card-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
  margin-bottom: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-museum {
  font-size: 14px;
  color: #666;
  margin-bottom: 10px;
}

.card-meta {
  display: flex;
  gap: 8px;
}

.material {
  background: #f0f0f0;
  color: #666;
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 12px;
}

.dynasty-section {
  background: #f8f9fa;
  margin: 20px 0;
}

.dynasty-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
}

.dynasty-card {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  border-radius: 12px;
  padding: 25px;
  text-decoration: none;
  color: #fff;
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2);
  }
}

.dynasty-icon {
  width: 50px;
  height: 50px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 15px;
}

.dynasty-info {
  text-align: center;
}

.dynasty-info h3 {
  font-size: 18px;
  margin-bottom: 5px;
}

.dynasty-info p {
  font-size: 13px;
  opacity: 0.8;
  margin-bottom: 10px;
}

.item-count {
  background: rgba(255, 255, 255, 0.15);
  padding: 3px 10px;
  border-radius: 10px;
  font-size: 12px;
}

.museum-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 25px;
}

.museum-card {
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  text-decoration: none;
  color: #333;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
  }
}

.museum-image {
  height: 200px;
  overflow: hidden;
}

.museum-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.museum-info {
  padding: 20px;
}

.museum-info h3 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 8px;
}

.museum-location {
  font-size: 14px;
  color: #666;
  margin-bottom: 10px;
}

.museum-count {
  background: #667eea;
  color: #fff;
  padding: 4px 12px;
  border-radius: 15px;
  font-size: 12px;
}

.update-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.update-item {
  display: flex;
  gap: 20px;
  background: #fff;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover {
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
    background: #fafafa;
  }
}

.update-image {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 8px;
}

.update-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.update-content h4 {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 8px;
}

.update-meta {
  font-size: 14px;
  color: #666;
  margin-bottom: 5px;
}

.update-time {
  font-size: 12px;
  color: #999;
}
</style>
