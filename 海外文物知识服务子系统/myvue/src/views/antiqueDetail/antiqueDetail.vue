<template>
  <div class="antique-detail">
    <MainHeader></MainHeader>
    
    <el-container class="detail-container">
      <el-main>
        <!-- 图片展示区域 -->
        <div class="image-section">
          <el-card :body-style="{ padding: '0px' }" class="image-card">
            <!-- 图片容器，支持缩放 -->
            <div 
              class="image-container"
              @wheel.prevent="handleZoom"
              @click="openFullscreen"
            >
              <img 
                :src="getValidImageUrl(artifact)" 
                class="main-image"
                :style="{ transform: `scale(${scale})` }"
                alt="文物图片"
                draggable="false"
              />
            </div>
            <!-- 图片操作工具栏 -->
            <div class="image-toolbar">
              <div class="zoom-controls">
                <el-button 
                  type="default" 
                  size="small" 
                  @click="goBack"
                  icon="el-icon-arrow-left"
                >
                  返回
                </el-button>
                <el-button 
                  type="default" 
                  size="small" 
                  @click="zoomOut"
                  icon="el-icon-minus"
                >
                  缩小
                </el-button>
                <span class="zoom-value">{{ Math.round(scale * 100) }}%</span>
                <el-button 
                  type="default" 
                  size="small" 
                  @click="zoomIn"
                  icon="el-icon-plus"
                >
                  放大
                </el-button>
                <el-button 
                  type="default" 
                  size="small" 
                  @click="resetZoom"
                  icon="el-icon-refresh"
                >
                  重置
                </el-button>
              </div>
              <div class="view-controls">
                <el-button 
                  type="primary" 
                  size="small" 
                  @click="openFullscreen"
                  icon="el-icon-full-screen"
                >
                  全屏查看
                </el-button>
              </div>
            </div>
          </el-card>
        </div>

        <!-- 文物基本信息 -->
        <div class="info-section">
          <el-card class="info-card">
            <h2 class="artifact-title">{{ decodeTitle(artifact.title) }}</h2>
            
            <div class="basic-info">
              <div class="info-row">
                <span class="info-label">朝代</span>
                <span class="info-value">{{ artifact.dynasty || '未知' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">年代</span>
                <span class="info-value">{{ formatYear(artifact.periodStartYear || artifact.period_start_year) }} - {{ formatYear(artifact.periodEndYear || artifact.period_end_year) }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">类型</span>
                <span class="info-value">{{ artifact.type || '未知' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">材质</span>
                <span class="info-value">{{ getMaterial(artifact.material) }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">博物馆</span>
                <span class="info-value">{{ artifact.museum || '未知' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">作者</span>
                <span class="info-value">{{ artifact.artist || '未知' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">尺寸</span>
                <span class="info-value">{{ artifact.dimensions || '未知' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">藏品编号</span>
                <span class="info-value">{{ artifact.accession_number || artifact.accessionNumber || '未知' }}</span>
              </div>
            </div>

            <!-- 文物描述 -->
            <div class="description-section">
              <h3 class="section-title">文物简介</h3>
              <p class="description-text">{{ artifact.description || '暂无简介' }}</p>
            </div>

            <!-- 操作按钮 -->
            <div class="action-buttons">
              <el-button 
                type="primary" 
                @click="toggleCollect"
                :icon="isCollected ? 'el-icon-star-on' : 'el-icon-star-off'"
              >
                {{ isCollected ? '已收藏' : '收藏' }}
              </el-button>
              <el-button 
                type="default" 
                @click="shareArtifact"
                icon="el-icon-share"
              >
                分享
              </el-button>
              <a 
                v-if="artifact.detail_url || artifact.detailUrl"
                :href="artifact.detail_url || artifact.detailUrl" 
                target="_blank" 
                class="el-button el-button--default"
                rel="noopener noreferrer"
              >
                <i class="el-icon-link"></i>
                查看原地址
              </a>
              <el-button 
                v-else
                type="default"
                disabled
              >
                <i class="el-icon-link"></i>
                暂无原地址
              </el-button>
            </div>
          </el-card>
        </div>

        <!-- 知识图谱关联实体 -->
        <div class="knowledge-section">
          <el-card class="knowledge-card">
            <h3 class="section-title">
              <i class="el-icon-network"></i>
              知识图谱关联实体
            </h3>
            <div class="triple-container">
              <div 
                v-for="(item, index) in knowledgeTriples" 
                :key="index"
                class="triple-item"
              >
                <span class="triple-subject">{{ item.subject }}</span>
                <span class="triple-predicate">{{ item.predicate }}</span>
                <span class="triple-object">{{ item.object }}</span>
              </div>
              <div v-if="knowledgeTriples.length === 0" class="empty-state">
                <el-empty description="暂无知识图谱关联数据"></el-empty>
              </div>
            </div>
            
            <!-- 关联实体展示 -->
            <div class="related-entities">
              <h4 class="subsection-title">关联实体</h4>
              <div class="entity-list">
                <el-tag 
                  v-for="(entity, index) in relatedEntities" 
                  :key="index"
                  type="info"
                  closable

                >
                  {{ entity }}
                </el-tag>
              </div>
            </div>
          </el-card>
        </div>

        <!-- 流传经历和参考文献 -->
        <div class="extra-info-section">
          <el-card class="extra-info-card">
            <h3 class="section-title">流传经历</h3>
            <p class="extra-text">{{ artifact.provenance || '暂无信息' }}</p>
          </el-card>
          <el-card class="extra-info-card">
            <h3 class="section-title">参考文献</h3>
            <p class="extra-text">{{ artifact.bibliography || '暂无信息' }}</p>
          </el-card>
        </div>

        <!-- 相关文物推荐 -->
        <div class="recommend-section">
          <el-card class="recommend-card">
            <h3 class="section-title">
              <i class="el-icon-recommend"></i>
              相关文物推荐
            </h3>
            <div class="recommend-list">
              <el-row :gutter="20">
                <el-col 
                  v-for="(item, index) in relatedArtifacts" 
                  :key="index"
                  :xs="24" 
                  :sm="12" 
                  :md="8" 
                  :lg="6"
                >
                  <div class="recommend-item">
                    <router-link 
                      :to="{path: '/antiqueDetail', query: {id: item.id, museum_id: item.museum_id, object_id: item.object_id}}"
                    >
                      <img :src="getValidImageUrl(item)" class="recommend-image" alt="">
                      <div class="recommend-info">
                        <span class="recommend-title">{{ item.title }}</span>
                        <span class="recommend-dynasty">{{ item.dynasty }}</span>
                      </div>
                    </router-link>
                  </div>
                </el-col>
              </el-row>
              <div v-if="relatedArtifacts.length === 0" class="empty-state">
                <el-empty description="暂无相关推荐"></el-empty>
              </div>
            </div>
          </el-card>
        </div>

        <!-- 评论区域 -->
        <div class="comment-section">
          <el-card class="comment-card">
            <h3 class="section-title">
              <i class="el-icon-chat-dot-round"></i>
              评论 ({{ comments.length }})
            </h3>
            <div class="comment-list">
              <div 
                v-for="comment in comments" 
                :key="comment.commentId"
                class="comment-item"
              >
                <div class="comment-header">
                  <div class="comment-user-info">
                    <span class="comment-author">{{ comment.username || '匿名用户' }}</span>
                  </div>
                  <span class="comment-time">{{ formatCommentTime(comment.createdAt) }}</span>
                </div>
                <p class="comment-content">{{ comment.content }}</p>
              </div>
              <div v-if="comments.length === 0" class="empty-state">
                <el-empty description="暂无评论，快来发表第一条评论吧~"></el-empty>
              </div>
            </div>
            
            <!-- 评论输入 -->
            <div class="comment-input-section">
              <textarea 
                v-model="newComment"
                class="comment-textarea"
                placeholder="发表您的看法..."
                rows="3"
                maxlength="500"
              ></textarea>
              <div class="comment-input-footer">
                <span class="char-count">{{ newComment.length }}/500</span>
                <el-button 
                  type="primary" 
                  @click="submitComment"
                  :disabled="!newComment.trim()"
                  size="small"
                >
                  发表评论
                </el-button>
              </div>
            </div>
          </el-card>
        </div>
      </el-main>
    </el-container>

    <!-- 全屏查看遮罩 -->
    <div v-if="showFullscreen" class="fullscreen-overlay" @click="closeFullscreen">
      <div class="fullscreen-content" @click.stop>
        <button class="fullscreen-close" @click="closeFullscreen">
          <i class="el-icon-close"></i>
        </button>
        <img 
          :src="getValidImageUrl(artifact)" 
          class="fullscreen-image"
          :style="{ transform: `scale(${fullscreenScale})` }"
          @wheel="handleFullscreenZoom"
          alt="全屏文物图片"
        />
        <div class="fullscreen-toolbar">
          <el-button 
            type="default" 
            @click="fullscreenZoomOut"
            icon="el-icon-minus"
          >
            缩小
          </el-button>
          <span>{{ Math.round(fullscreenScale * 100) }}%</span>
          <el-button 
            type="default" 
            @click="fullscreenZoomIn"
            icon="el-icon-plus"
          >
            放大
          </el-button>
          <el-button 
            type="default" 
            @click="resetFullscreenZoom"
            icon="el-icon-refresh"
          >
            重置
          </el-button>
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
  name: 'antiqueDetail',
  components: { MainFooter, MainHeader },
  data () {
    return {
      // 文物数据
      artifact: {},
      // 评论列表
      comments: [],
      // 知识图谱三元组
      knowledgeTriples: [],
      // 关联实体
      relatedEntities: [],
      // 相关文物推荐
      relatedArtifacts: [],
      // 缩放相关
      scale: 1,
      minScale: 0.5,
      maxScale: 3,
      // 全屏相关
      showFullscreen: false,
      fullscreenScale: 1,
      // 收藏状态
      isCollected: false,
      // 新评论内容
      newComment: '',
      // 默认图片（使用base64 SVG，避免外部依赖）
      defaultImage: 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="400"%3E%3Crect fill="%23f5f5f5" width="400" height="400"/%3E%3Ctext fill="%23999" font-family="sans-serif" font-size="16" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3E暂无图片%3C/text%3E%3C/svg%3E',
      // 服务器图片API地址（仅用于博物馆2、3）
      serverApiBase: 'http://47.96.152.190:8000',
      // 表单数据
      form: {
        rid: '',
        uid: ''
      }
    }
  },
  created () {
    this.pageInit()
  },
  watch: {
    // 监听路由参数变化，当参数变化时重新加载数据
    '$route.query': {
      handler () {
        // 重置状态
        this.artifact = {}
        this.comments = []
        this.knowledgeTriples = []
        this.relatedEntities = []
        this.relatedArtifacts = []
        this.scale = 1
        this.isCollected = false
        
        // 重新初始化页面
        this.pageInit()
      },
      deep: true
    }
  },
  methods: {
    // 返回上一页
    goBack () {
      // 尝试使用浏览器历史返回
      if (window.history.length > 1) {
        window.history.back()
      } else {
        // 如果没有历史记录，跳转到浏览页面
        this.$router.push('/fore')
      }
    },
    // 页面初始化
    pageInit () {
      this.form.uid = window.localStorage.getItem('user_id') || window.localStorage.getItem('username')
      
      // 获取URL参数
      this.museum_id = this.$route.query.museum_id
      this.object_id = this.$route.query.object_id
      this.form.rid = this.$route.query.id || this.object_id
      
      // 加载文物详情（需要先加载，其他接口依赖文物数据）
      this.loadArtifactDetail().then(() => {
        // 文物详情加载完成后再加载其他数据
        this.loadComments()
        this.loadKnowledgeGraph()
        this.loadRelatedArtifacts()
        // 添加浏览记录
        this.addBrowseHistory()
      })
    },
    
    // 加载文物详情
    loadArtifactDetail () {
      return new Promise((resolve) => {
        // 使用 museum_id 和 object_id 查询详情
        if (this.museum_id && this.object_id) {
          axios.post('http://localhost:8085/search/detail', { 
            museumId: parseInt(this.museum_id), 
            objectId: String(this.object_id),
            uid: this.form.uid
          })
            .then((response) => {
              if (response.data.state === 200) {
                this.artifact = response.data.data
                this.isCollected = this.artifact.if_collect === 1
              }
              resolve()
            })
            .catch((error) => {
              console.log(error)
              // 使用模拟数据
              this.loadMockData()
              resolve()
            })
        } else {
          axios.post('http://localhost:8085/search/searchById', this.form)
            .then((response) => {
              if (response.data.state === 200) {
                this.artifact = response.data.data
                this.isCollected = this.artifact.if_collect === 1
              }
              resolve()
            })
            .catch((error) => {
              console.log(error)
              // 使用模拟数据
              this.loadMockData()
              resolve()
            })
        }
      })
    },
    
    /**
     * 加载评论
     */
    loadComments () {
      if (!this.museum_id || !this.object_id) {
        return
      }
      
      axios.post('http://localhost:8085/search/getComments', {
        museumId: parseInt(this.museum_id),
        objectId: String(this.object_id)
      })
        .then((response) => {
          if (response.data.state === 200) {
            this.comments = response.data.data || []
          }
        })
        .catch((error) => {
          console.log('加载评论失败:', error)
        })
    },
    
    // 加载知识图谱数据
    loadKnowledgeGraph () {
      axios.post('http://localhost:8085/search/knowledge', { 
        museumId: parseInt(this.museum_id), 
        objectId: String(this.object_id)
      })
        .then((response) => {
          if (response.data.state === 200) {
            this.knowledgeTriples = response.data.data || []
            this.relatedEntities = [...new Set(this.knowledgeTriples.map(item => item.object).filter(Boolean))]
          }
        })
        .catch((error) => {
          console.log(error)
          this.loadMockKnowledgeData()
        })
    },
    
    // 加载相关文物推荐
    loadRelatedArtifacts () {
      // 优先根据类型获取相关文物（类型比朝代更稳定）
      if (this.artifact.type && this.artifact.type !== '未知') {
        axios.post('http://localhost:8085/search/classification', { 
          c: 'type',
          v_1: this.artifact.type
        })
          .then((response) => {
            if (response.data.state === 200 && response.data.data.length > 0) {
              // 过滤掉当前文物本身
              this.relatedArtifacts = response.data.data.filter(item => 
                item.object_id !== this.object_id && item.museum_id !== this.museum_id
              ).slice(0, 8) // 只取前8个推荐
            } else {
              // 如果类型查询没有结果，尝试其他方式
              this.loadRelatedByOtherConditions()
            }
          })
          .catch((error) => {
            console.log(error)
            this.loadRelatedByOtherConditions()
          })
      } else {
        this.loadRelatedByOtherConditions()
      }
    },
    
    // 使用其他条件获取相关文物
    loadRelatedByOtherConditions () {
      // 如果朝代不为空且不是"未知"，尝试按朝代查询
      if (this.artifact.dynasty && this.artifact.dynasty !== '未知') {
        // 使用完整的朝代值进行精确匹配（如 "Tang（唐）"）
        axios.post('http://localhost:8085/search/classification', { 
          c: 'dynasty',
          v_1: this.artifact.dynasty
        })
          .then((response) => {
            if (response.data.state === 200 && response.data.data.length > 0) {
              this.relatedArtifacts = response.data.data.filter(item => 
                item.object_id !== this.object_id && item.museum_id !== this.museum_id
              ).slice(0, 8)
            } else {
              // 如果还是没有结果，获取随机文物
              this.loadRandomArtifacts()
            }
          })
          .catch((error) => {
            console.log(error)
            this.loadRandomArtifacts()
          })
      } else {
        // 获取随机文物
        this.loadRandomArtifacts()
      }
    },
    
    // 获取随机文物作为推荐
    loadRandomArtifacts () {
      axios.post('http://localhost:8085/search/classification', { 
        c: 'dynasty',
        v_1: 'Shang（商）' // 使用完整格式进行精确匹配
      })
        .then((response) => {
            if (response.data.state === 200 && response.data.data.length > 0) {
              console.log('Related artifacts raw data:', response.data.data)
              this.relatedArtifacts = response.data.data.filter(item => 
                item.object_id !== this.object_id && item.museum_id !== this.museum_id
              ).slice(0, 8)
              console.log('Filtered related artifacts:', this.relatedArtifacts)
              // 检查图片URL
              this.relatedArtifacts.forEach((item, index) => {
                console.log(`Artifact ${index}: img_url=${item.img_url}, image_url=${item.image_url}`)
              })
            } else {
              // 如果还是失败，才使用模拟数据
              this.loadMockRelatedData()
            }
          })
        .catch((error) => {
          console.log(error)
          this.loadMockRelatedData()
        })
    },
    
    // 校验图片URL是否有效
    getValidImageUrl (item) {
      const { imageUrl, image_url, img_url, museum_id, object_id } = item
      const url = imageUrl || image_url || img_url
      const museumIdNum = parseInt(museum_id) || parseInt(this.museum_id)
      const objId = object_id || this.object_id
      
      // 仅博物馆2、3调用服务器API
      if (museumIdNum === 2 || museumIdNum === 3) {
        if (objId && objId !== 'null' && objId !== 'undefined') {
          return `${this.serverApiBase}/api/img/${museumIdNum}/${objId}`
        }
        return this.defaultImage
      }
      
      // 其他博物馆（如博物馆1）使用原有逻辑
      if (!url || url === 'null' || url === 'undefined' || url === '' || url === 'NULL') {
        return this.defaultImage
      }
      
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        if (url.startsWith('//')) {
          return 'https:' + url
        }
        return this.defaultImage
      }
      
      try {
        new URL(url)
        return url
      } catch (e) {
        console.log('Invalid image URL:', url)
        return this.defaultImage
      }
    },
    
    // 处理材质字段，移除尺寸信息
    getMaterial (material) {
      if (!material || material === 'null' || material === 'undefined') {
        return '未知'
      }
      
      let result = material
      
      // 1. 移除 (overall): 及其后面的内容
      const overallMatch = result.match(/^(.+?)\s*\(overall\):/i)
      if (overallMatch) {
        return overallMatch[1].trim() || '未知'
      }
      
      // 2. 处理材质和尺寸直接相连的情况（数据库数据不规范）
      // 匹配模式：材质结尾 + 数字开头（没有空格分隔）
      const connectedMatch = result.match(/^(.+?)(?=\d+\.?\d*\s*x\s*)/i)
      if (connectedMatch) {
        result = connectedMatch[1].trim()
        if (result.length >= 2 && !/^\d/.test(result)) {
          return result
        }
      }
      
      // 3. 移除尺寸标记（如 Diam x D:）及其后面的内容
      const dimensionLabelMatch = result.match(/^(.+?)\s*(Diam|H|W|L|D|Dia|Height|Width|Length|Depth)\s*x/i)
      if (dimensionLabelMatch) {
        return dimensionLabelMatch[1].trim() || '未知'
      }
      
      // 4. 移除尺寸信息
      const sizePatterns = [
        /\s*(Diam|H|W|L|D|Dia|Height|Width|Length|Depth|overall)\s*[x××:]\s*/gi,
        /\s*\d+\.?\d*\s*x\s*/gi,
        /\s*\d+\.?\d*\s*(cm|mm|in|英寸|厘米|毫米)/gi,
        /\s*\(\s*\d+\.?\d*\s*[x××]\s*\d+\.?\d*\s*(cm|mm|in)?\s*\)/gi,
        /\s*\(\s*\d+\s+\d+\/\d+\s*[x××]\s*\d+\s+\d+\/\d+/gi,
        /\s*\d+\s+\d+\/\d+\s*[x××]\s*/gi,
        /\s+\d+\s+\d+\/\d+/gi,
        /\s+\d+\/\d+/gi,
        /\(\s*\d+\//gi,
        /\s*x\s*\d+/gi
      ]
      
      sizePatterns.forEach(pattern => {
        result = result.replace(pattern, '').trim()
      })
      
      // 5. 移除末尾的不规则字符
      result = result.replace(/\s*[()\/:]$/, '').trim()
      
      // 6. 如果移除后为空或太短，返回原始值
      if (!result || result.length < 2) {
        return material
      }
      
      return result || '未知'
    },
    
    // 解码乱码标题
    decodeTitle (title) {
      if (!title) return '未知文物'
      // 修复UTF-8编码问题，处理乱码字符
      try {
        // 处理HTML实体
        const temp = document.createElement('textarea')
        temp.innerHTML = title
        let decoded = temp.value
        
        // 处理常见的编码错误
        // 替换UTF-8编码错误的字符
        decoded = decoded.replace(/Ã§/g, 'ç')
                        .replace(/Ã©/g, 'é')
                        .replace(/Ã¨/g, 'è')
                        .replace(/Ã¤/g, 'ä')
                        .replace(/Ã¶/g, 'ö')
                        .replace(/Ã¼/gi, 'ü')
                        .replace(/Ã±/g, 'ñ')
                        .replace(/Ã¡/g, 'á')
                        .replace(/Ã³/gi, 'ó')
                        .replace(/Ãº/gi, 'ú')
                        .replace(/Ã¿/g, '¿')
                        .replace(/Ã¢/g, 'â')
                        .replace(/Ãª/gi, 'ê')
                        .replace(/Ã«/g, 'ë')
                        .replace(/Ã«/g, 'ï')
                        .replace(/Ã§/g, 'ç')
                        .replace(/Ã`/g, 'à')
                        .replace(/Ã¹/gi, 'ù')
                        .replace(/Ã½/gi, 'ý')
                        .replace(/Ãµ/gi, 'õ')
                        .replace(/Ã¢/g, 'â')
                        .replace(/Ã£/g, 'ã')
                        .replace(/Ã¥/gi, 'å')
                        .replace(/Ã¦/gi, 'æ')
                        .replace(/Ã¶/gi, 'ö')
                        .replace(/Ã¤/gi, 'ä')
                        .replace(/Ã¼/gi, 'ü')
                        .replace(/ÃŸ/gi, 'ß')
                        .replace(/Ã·/gi, '÷')
                        .replace(/Ã—/gi, '×')
                        .replace(/Ã”/gi, 'Ô')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã¨/gi, 'È')
                        .replace(/Ã¹/gi, 'Ù')
                        .replace(/Ãº/gi, 'Ú')
                        .replace(/Ã®/gi, 'Î')
                        .replace(/Ã¬/gi, 'Ì')
                        .replace(/Ã¯/gi, 'Ï')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã¼/gi, 'Ü')
                        .replace(/Ãª/gi, 'Ê')
                        .replace(/Ã«/gi, 'Ë')
                        .replace(/Ã§/gi, 'Ç')
                        .replace(/Ã±/gi, 'Ñ')
                        .replace(/Ã‘/gi, 'Ñ')
                        .replace(/Ã½/gi, 'Ý')
                        .replace(/Ã²/gi, 'Ò')
                        .replace(/Ã³/gi, 'Ó')
                        .replace(/Ã´/gi, 'Ô')
                        .replace(/Ã¶/gi, 'Ö')
                        .replace(/Ã¤/gi, 'Ä')
                        .replace(/Ã¥/gi, 'Å')
                        .replace(/Ã¦/gi, 'Æ')
                        .replace(/Ã¸/gi, 'Ø')
                        .replace(/Ã¿/gi, '¿')
                        .replace(/Ã½/gi, 'Ý')
                        .replace(/Ã³/gi, 'Ó')
                        .replace(/Ãº/gi, 'Ú')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã§/gi, 'Ç')
                        .replace(/Ã¢/gi, 'Â')
                        .replace(/Ãª/gi, 'Ê')
                        .replace(/Ã®/gi, 'Î')
                        .replace(/Ã«/gi, 'Ë')
                        .replace(/Ã¯/gi, 'Ï')
                        .replace(/Ã¬/gi, 'Ì')
                        .replace(/Ã /gi, 'À')
                        .replace(/Ã¤/gi, 'Ä')
                        .replace(/Ã¶/gi, 'Ö')
                        .replace(/Ã¼/gi, 'Ü')
                        .replace(/Ã°/gi, 'Ð')
                        .replace(/Ã¾/gi, 'Þ')
                        .replace(/Ã§/gi, 'Ç')
                        .replace(/Ã±/gi, 'Ñ')
                        .replace(/Ã‘/gi, 'Ñ')
                        .replace(/ÃŸ/gi, 'ß')
                        .replace(/Ã·/gi, '÷')
                        .replace(/Ã—/gi, '×')
                        .replace(/Ã”/gi, 'Ô')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã¨/gi, 'È')
                        .replace(/Ã¹/gi, 'Ù')
                        .replace(/Ãº/gi, 'Ú')
                        .replace(/Ã®/gi, 'Î')
                        .replace(/Ã¬/gi, 'Ì')
                        .replace(/Ã¯/gi, 'Ï')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã¼/gi, 'Ü')
                        .replace(/Ãª/gi, 'Ê')
                        .replace(/Ã«/gi, 'Ë')
                        .replace(/Ã§/gi, 'Ç')
                        .replace(/Ã±/gi, 'Ñ')
                        .replace(/Ã‘/gi, 'Ñ')
                        .replace(/Ã½/gi, 'Ý')
                        .replace(/Ã²/gi, 'Ò')
                        .replace(/Ã³/gi, 'Ó')
                        .replace(/Ã´/gi, 'Ô')
                        .replace(/Ã¶/gi, 'Ö')
                        .replace(/Ã¤/gi, 'Ä')
                        .replace(/Ã¥/gi, 'Å')
                        .replace(/Ã¦/gi, 'Æ')
                        .replace(/Ã¸/gi, 'Ø')
                        .replace(/Ã¿/gi, '¿')
                        .replace(/Ã½/gi, 'Ý')
                        .replace(/Ã³/gi, 'Ó')
                        .replace(/Ãº/gi, 'Ú')
                        .replace(/Ã©/gi, 'É')
                        .replace(/Ã§/gi, 'Ç')
                        .replace(/Ã¢/gi, 'Â')
                        .replace(/Ãª/gi, 'Ê')
                        .replace(/Ã®/gi, 'Î')
                        .replace(/Ã«/gi, 'Ë')
                        .replace(/Ã¯/gi, 'Ï')
                        .replace(/Ã¬/gi, 'Ì')
                        .replace(/Ã /gi, 'À')
                        .replace(/Ã¤/gi, 'Ä')
                        .replace(/Ã¶/gi, 'Ö')
                        .replace(/Ã¼/gi, 'Ü')
                        .replace(/Ã°/gi, 'Ð')
                        .replace(/Ã¾/gi, 'Þ')
                        .replace(/ç□§/gi, '璧')
                        .replace(/�/g, '') // 移除无法识别的字符
                        
        return decoded
      } catch (e) {
        console.error('Title decoding error:', e)
        return title
      }
    },
    
    // 加载模拟数据
    loadMockData () {
      this.artifact = {
        id: this.$route.query.id,
        museum_id: this.$route.query.museum_id,
        object_id: this.$route.query.object_id,
        title: '青铜方鼎',
        dynasty: '商朝',
        period_start_year: -1300,
        period_end_year: -1046,
        type: '青铜器',
        material: '青铜',
        museum: '史密森尼博物馆',
        artist: '未知',
        description: '商代青铜器的典型代表，造型庄重，纹饰精美。方鼎为四足方鼎，口沿外撇，方唇，长方形腹，四柱足较高。腹部饰兽面纹，以云雷纹为地。',
        dimensions: '高33厘米，口径25厘米',
        accession_number: 'S1987.01',
        image_url: 'https://picsum.photos/seed/bronze_1/400/400',
        detail_url: 'https://example.com/artifact/1',
        provenance: '1987年由收藏家捐赠',
        bibliography: '《中国青铜器全集》',
        if_collect: 0
      }
    },
    
    // 加载模拟知识图谱数据（使用当前文物的真实数据）
    loadMockKnowledgeData () {
      const relicName = this.artifact.title || this.artifact.object_name || '文物'
      const dynasty = this.artifact.dynasty || '未知朝代'
      const type = this.artifact.type || '文物'
      const material = this.getMaterial(this.artifact.material) || '未知材质'
      const museum = this.artifact.museum || '未知博物馆'
      const culture = this.artifact.culture || '中国文化'
      const artist = this.artifact.artist || '未知作者'
      
      this.knowledgeTriples = [
        { subject: relicName, predicate: '创作于', object: dynasty },
        { subject: relicName, predicate: '材质为', object: material },
        { subject: relicName, predicate: '收藏于', object: museum },
        { subject: relicName, predicate: '属于', object: type },
        { subject: relicName, predicate: '代表', object: culture },
        { subject: relicName, predicate: '作者', object: artist }
      ]
      this.relatedEntities = [dynasty, material, museum, type, culture, artist]
    },
    
    // 加载模拟相关文物数据
    loadMockRelatedData () {
      this.relatedArtifacts = [
        {
          id: 2,
          museum_id: 1,
          object_id: 'obj002',
          title: '青铜爵',
          dynasty: '商朝',
          image_url: 'https://picsum.photos/seed/bronze_2/200/200'
        },
        {
          id: 3,
          museum_id: 1,
          object_id: 'obj003',
          title: '青铜觚',
          dynasty: '商朝',
          image_url: 'https://picsum.photos/seed/bronze_3/200/200'
        },
        {
          id: 4,
          museum_id: 2,
          object_id: 'obj004',
          title: '青铜簋',
          dynasty: '周朝',
          image_url: 'https://picsum.photos/seed/bronze_4/200/200'
        },
        {
          id: 5,
          museum_id: 3,
          object_id: 'obj005',
          title: '青铜钟',
          dynasty: '周朝',
          image_url: 'https://picsum.photos/seed/bronze_5/200/200'
        },
        {
          id: 6,
          museum_id: 1,
          object_id: 'obj006',
          title: '青铜戈',
          dynasty: '商朝',
          image_url: 'https://picsum.photos/seed/bronze_6/200/200'
        },
        {
          id: 7,
          museum_id: 2,
          object_id: 'obj007',
          title: '青铜矛',
          dynasty: '战国',
          image_url: 'https://picsum.photos/seed/bronze_7/200/200'
        }
      ]
    },
    
    // 图片缩放控制
    zoomIn () {
      if (this.scale < this.maxScale) {
        this.scale += 0.2
      }
    },
    
    zoomOut () {
      if (this.scale > this.minScale) {
        this.scale -= 0.2
      }
    },
    
    resetZoom () {
      this.scale = 1
    },
    
    handleZoom (e) {
      // 只有当图片被放大时才进行缩放，否则允许页面滚动
      if (this.scale !== 1) {
        e.preventDefault()
        const delta = e.deltaY > 0 ? -0.1 : 0.1
        this.scale = Math.max(this.minScale, Math.min(this.maxScale, this.scale + delta))
      }
    },
    
    // 全屏查看
    openFullscreen () {
      this.showFullscreen = true
      this.fullscreenScale = 1
      document.body.style.overflow = 'hidden'
    },
    
    closeFullscreen () {
      this.showFullscreen = false
      document.body.style.overflow = ''
    },
    
    fullscreenZoomIn () {
      if (this.fullscreenScale < this.maxScale) {
        this.fullscreenScale += 0.2
      }
    },
    
    fullscreenZoomOut () {
      if (this.fullscreenScale > this.minScale) {
        this.fullscreenScale -= 0.2
      }
    },
    
    resetFullscreenZoom () {
      this.fullscreenScale = 1
    },
    
    handleFullscreenZoom (e) {
      e.preventDefault()
      const delta = e.deltaY > 0 ? -0.1 : 0.1
      this.fullscreenScale = Math.max(this.minScale, Math.min(this.maxScale, this.fullscreenScale + delta))
    },
    
    // 收藏/取消收藏
    toggleCollect () {
      if (!this.form.uid) {
        this.$message.warning('请先登录')
        return
      }

      const isCancel = this.isCollected
      const url = isCancel
        ? 'http://localhost:8085/user_admin/deleteCollect'
        : 'http://localhost:8085/search/searchById/collect'

      const params = isCancel
        ? { userId: this.form.uid, museumId: String(this.museum_id), objectId: String(this.object_id) }
        : { uid: this.form.uid, museumId: String(this.museum_id), objectId: String(this.object_id) }

      axios.post(url, params)
        .then((response) => {
          if (response.data.state === 200) {
            this.isCollected = !this.isCollected
            this.$message.success(this.isCollected ? '收藏成功' : '已取消收藏')
          }
        })
        .catch((error) => {
          console.log(error)
          this.$message.error('操作失败')
        })
        .finally(() => {
          window.dispatchEvent(new Event('collectChange'))
        })
    },
    
    // 添加浏览记录
    addBrowseHistory () {
      if (!this.artifact || (!this.artifact.object_id && !this.artifact.objectId)) return
      
      const historyItem = {
        object_id: this.artifact.object_id || this.artifact.objectId,
        museum_id: this.museum_id,
        object_name: this.artifact.object_name || this.artifact.title,
        time_period: this.artifact.time_period || this.artifact.period,
        img_url: this.artifact.image_url || this.artifact.imageUrl || this.artifact.img_url,
        browse_time: new Date().toLocaleString('zh-CN')
      }
      
      const history = localStorage.getItem('browse_history')
      let historyList = []
      if (history) {
        try {
          historyList = JSON.parse(history)
        } catch (e) {
          historyList = []
        }
      }
      
      // 移除重复记录
      historyList = historyList.filter(item => !(item.object_id === historyItem.object_id && item.museum_id === historyItem.museum_id))
      
      // 添加到开头
      historyList.unshift(historyItem)
      
      // 最多保留50条记录
      if (historyList.length > 50) {
        historyList = historyList.slice(0, 50)
      }
      
      localStorage.setItem('browse_history', JSON.stringify(historyList))
    },
    
    // 分享功能
    shareArtifact () {
      const shareUrl = window.location.href
      navigator.clipboard.writeText(shareUrl)
        .then(() => {
          this.$message.success('链接已复制到剪贴板')
        })
        .catch(() => {
          this.$message.error('复制失败')
        })
    },
    
    /**
     * 格式化评论时间
     */
    formatCommentTime (time) {
      if (!time) return ''
      const date = new Date(time)
      const now = new Date()
      const diff = now - date
      
      // 1分钟内
      if (diff < 60 * 1000) {
        return '刚刚'
      }
      // 1小时内
      if (diff < 60 * 60 * 1000) {
        return Math.floor(diff / (60 * 1000)) + '分钟前'
      }
      // 1天内
      if (diff < 24 * 60 * 60 * 1000) {
        return Math.floor(diff / (60 * 60 * 1000)) + '小时前'
      }
      // 1周内
      if (diff < 7 * 24 * 60 * 60 * 1000) {
        return Math.floor(diff / (24 * 60 * 60 * 1000)) + '天前'
      }
      // 更早的显示完整日期
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    
    /**
     * 发表评论
     */
    submitComment () {
      if (!this.form.uid) {
        this.$message.warning('请先登录')
        return
      }
      
      if (!this.newComment.trim()) {
        this.$message.warning('请输入评论内容')
        return
      }
      
      axios.post('http://localhost:8085/search/addComment', {
        userId: this.form.uid,
        museumId: parseInt(this.museum_id),
        objectId: String(this.object_id),
        content: this.newComment.trim()
      })
        .then((response) => {
          if (response.data.state === 200) {
            this.$message.success(response.data.message || '评论成功，等待审核')
            this.newComment = ''
            this.loadComments()
          } else {
            this.$message.error(response.data.message || '评论失败')
          }
        })
        .catch((error) => {
          console.log('评论失败:', error)
          this.$message.error('评论失败')
        })
    },
    
    // 搜索关联实体
    searchEntity (entity) {
      this.$router.push({
        path: '/dataQuery',
        query: { keyword: entity }
      })
    },
    
    // 格式化年代显示
    formatYear (year) {
      if (!year) return '未知'
      if (year < 0) {
        return `公元前${Math.abs(year)}年`
      }
      return `${year}年`
    }
  }
}
</script>

<style lang="scss" scoped>
.antique-detail {
  min-height: 100vh;
  background-color: #f5f7fa;
}

.detail-container {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

/* 图片区域 */
.image-section {
  margin-bottom: 20px;
}

.image-card {
  overflow: hidden;
}

.image-container {
  position: relative;
  width: 100%;
  height: 500px;
  background-color: #f5f5f5;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  cursor: zoom-in;
}

.main-image {
  max-width: 100%;
  max-height: 100%;
  transition: transform 0.2s ease;
}

.image-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background-color: #fafafa;
  border-top: 1px solid #e8e8e8;
}

.zoom-controls {
  display: flex;
  align-items: center;
  gap: 10px;
}

.zoom-value {
  min-width: 60px;
  text-align: center;
  color: #606266;
}

.view-controls {
  display: flex;
  gap: 10px;
}

/* 信息区域 */
.info-section {
  margin-bottom: 20px;
}

.info-card {
  padding: 20px;
}

.artifact-title {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 20px;
  border-bottom: 2px solid #409eff;
  padding-bottom: 10px;
}

.basic-info {
  margin-bottom: 20px;
}

.info-row {
  display: flex;
  padding: 10px 0;
  border-bottom: 1px dashed #e8e8e8;
}

.info-label {
  width: 100px;
  font-weight: bold;
  color: #606266;
}

.info-value {
  flex: 1;
  color: #303133;
}

.description-section {
  margin-bottom: 20px;
}

.section-title {
  font-size: 18px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 15px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.description-text {
  font-size: 14px;
  line-height: 1.8;
  color: #606266;
  text-indent: 2em;
}

.action-buttons {
  display: flex;
  gap: 10px;
}

/* 知识图谱区域 */
.knowledge-section {
  margin-bottom: 20px;
}

.knowledge-card {
  padding: 20px;
}

.triple-container {
  margin-bottom: 20px;
}

.triple-item {
  display: flex;
  align-items: center;
  padding: 12px 15px;
  background-color: #f5f7fa;
  border-radius: 4px;
  margin-bottom: 10px;
}

.triple-subject {
  font-weight: bold;
  color: #409eff;
}

.triple-predicate {
  margin: 0 15px;
  color: #909399;
  background-color: #e8f4fc;
  padding: 4px 10px;
  border-radius: 4px;
}

.triple-object {
  color: #67c23a;
}

.related-entities {
  margin-top: 20px;
}

.subsection-title {
  font-size: 14px;
  font-weight: bold;
  color: #606266;
  margin-bottom: 10px;
}

.entity-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

/* 扩展信息区域 */
.extra-info-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
  
  @media (max-width: 768px) {
    grid-template-columns: 1fr;
  }
}

.extra-info-card {
  padding: 20px;
}

.extra-text {
  font-size: 14px;
  line-height: 1.8;
  color: #606266;
}

/* 相关推荐区域 */
.recommend-section {
  margin-bottom: 20px;
}

.recommend-card {
  padding: 20px;
}

.recommend-list {
  margin-top: 15px;
}

.recommend-item {
  margin-bottom: 20px;
  overflow: hidden;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  height: 260px; /* 统一卡片高度 */
  
  &:hover {
    transform: translateY(-5px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  }
}

.recommend-item a {
  text-decoration: none;
  color: inherit;
}

.recommend-image {
  width: 100%;
  height: 180px;
  object-fit: cover;
}

.recommend-info {
  padding: 12px;
}

.recommend-title {
  display: block;
  font-weight: bold;
  color: #303133;
  margin-bottom: 5px;
}

.recommend-dynasty {
  font-size: 12px;
  color: #909399;
}

/* 评论区域 */
.comment-section {
  margin-bottom: 20px;
}

.comment-card {
  padding: 20px;
}

.comment-list {
  margin-bottom: 20px;
  max-height: 500px;
  overflow-y: auto;
}

.comment-item {
  padding: 15px;
  background-color: #f9fafc;
  border-radius: 8px;
  margin-bottom: 15px;
  transition: all 0.3s ease;
  
  &:last-child {
    margin-bottom: 0;
  }
  
  &:hover {
    background-color: #f0f2f5;
  }
}

.comment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.comment-user-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.comment-author {
  font-weight: bold;
  color: #303133;
  font-size: 14px;
}

.comment-time {
  font-size: 12px;
  color: #909399;
}

.comment-content {
  color: #606266;
  line-height: 1.8;
  font-size: 14px;
  word-wrap: break-word;
}

.comment-input-section {
  padding-top: 15px;
  border-top: 1px solid #e8e8e8;
}

.comment-textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #dcdfe6;
  border-radius: 8px;
  resize: none;
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: 10px;
  box-sizing: border-box;
  
  &:focus {
    outline: none;
    border-color: #409eff;
    box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
  }
  
  &::placeholder {
    color: #c0c4cc;
  }
}

.comment-input-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.char-count {
  font-size: 12px;
  color: #909399;
}

/* 全屏遮罩 */
.fullscreen-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.9);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
}

.fullscreen-content {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.fullscreen-close {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 40px;
  height: 40px;
  background-color: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 50%;
  color: white;
  font-size: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  
  &:hover {
    background-color: rgba(255, 255, 255, 0.3);
  }
}

.fullscreen-image {
  max-width: 90%;
  max-height: 80%;
  transition: transform 0.2s ease;
}

.fullscreen-toolbar {
  position: absolute;
  bottom: 30px;
  display: flex;
  align-items: center;
  gap: 15px;
  background-color: rgba(255, 255, 255, 0.2);
  padding: 10px 20px;
  border-radius: 30px;
  color: white;
}

/* 空状态 */
.empty-state {
  padding: 40px;
}

/* 响应式调整 */
@media (max-width: 768px) {
  .image-container {
    height: 300px;
  }
  
  .artifact-title {
    font-size: 22px;
  }
  
  .action-buttons {
    flex-wrap: wrap;
  }
  
  .comment-input-section {
    flex-direction: column;
  }
}
</style>
