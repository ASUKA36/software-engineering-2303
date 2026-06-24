<template>
  <div class="kg-page">
    <MainHeader />

    <div class="kg-hero">
      <div class="hero-bg"></div>
      <div class="hero-inner">
        <h1 class="hero-title">文物知识图谱</h1>
        <p class="hero-sub">基于 Neo4j 图数据库 · 探索文物间的关联脉络</p>
      </div>
    </div>

    <div class="kg-body">
      <div class="kg-sidebar">
        <div class="sidebar-section">
          <div class="section-head">
            <i class="el-icon-search"></i>
            <span>搜索</span>
          </div>
          <div class="search-box">
            <el-input
              v-model="searchKeyword"
              placeholder="输入文物、朝代、博物馆..."
              clearable
              size="small"
              @clear="handleSearch"
              @keyup.enter.native="handleSearch"
            >
              <i slot="prefix" class="el-icon-search"></i>
            </el-input>
            <div class="search-actions">
              <el-button type="primary" size="mini" @click="handleSearch" :loading="loading">搜索</el-button>
              <el-button size="mini" @click="resetGraph">重置</el-button>
            </div>
          </div>
        </div>

        <div class="sidebar-section">
          <div class="section-head">
            <i class="el-icon-s-operation"></i>
            <span>节点筛选</span>
          </div>
          <div class="filter-list">
            <div
              v-for="cat in categories"
              :key="cat.key"
              class="filter-item"
              :class="{ active: activeCategories.includes(cat.key) }"
              @click="toggleCategory(cat.key)"
            >
              <span class="filter-dot" :style="{ background: cat.color }"></span>
              <span class="filter-label">{{ cat.label }}</span>
              <span class="filter-count">{{ getCategoryCount(cat.key) }}</span>
            </div>
          </div>
          <div class="filter-actions">
            <el-button size="mini" @click="toggleAllCategories(true)">全选</el-button>
            <el-button size="mini" @click="toggleAllCategories(false)">清除</el-button>
          </div>
        </div>

        <div class="sidebar-section">
          <div class="section-head">
            <i class="el-icon-data-analysis"></i>
            <span>图谱统计</span>
          </div>
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-val">{{ nodeCount }}</div>
              <div class="stat-lbl">节点数</div>
            </div>
            <div class="stat-card">
              <div class="stat-val">{{ edgeCount }}</div>
              <div class="stat-lbl">关系数</div>
            </div>
          </div>
        </div>

        <div class="sidebar-section">
          <div class="section-head">
            <i class="el-icon-s-tools"></i>
            <span>布局控制</span>
          </div>
          <div class="layout-controls">
            <div class="control-row">
              <span class="ctrl-label">排斥力</span>
              <el-slider v-model="layoutConfig.repulsion" :min="100" :max="2000" :step="50" size="mini" @change="updateLayout"></el-slider>
            </div>
            <div class="control-row">
              <span class="ctrl-label">引力</span>
              <el-slider v-model="layoutConfig.gravity" :min="1" :max="20" :step="1" size="mini" @change="updateLayout"></el-slider>
            </div>
            <div class="control-row">
              <span class="ctrl-label">边长度</span>
              <el-slider v-model="layoutConfig.edgeLength" :min="30" :max="300" :step="10" size="mini" @change="updateLayout"></el-slider>
            </div>
          </div>
        </div>
      </div>

      <div class="kg-main">
        <div class="graph-wrapper" v-loading="loading" element-loading-text="加载图谱数据...">
          <div ref="graphContainer" class="graph-canvas"></div>
          <div v-if="!loading && activeCategories.length === 0" class="empty-hint">
            <i class="el-icon-guide"></i>
            <p class="empty-title">请选择节点类别开始探索</p>
            <p class="empty-sub">在左侧「节点筛选」中勾选感兴趣的类别</p>
          </div>
        </div>

        <transition name="panel-slide">
          <div v-if="selectedNode" class="detail-panel">
            <div class="dp-header">
              <div class="dp-type">
                <span class="dp-dot" :style="{ background: getCategoryColor(selectedNode.category) }"></span>
                <span class="dp-type-text">{{ getCategoryLabel(selectedNode.category) }}</span>
              </div>
              <i class="el-icon-close dp-close" @click="closeDetail"></i>
            </div>
            <div class="dp-name">{{ selectedNode.name }}</div>
            <div class="dp-count" v-if="selectedNode.count">
              <i class="el-icon-connection"></i>
              关联数: {{ selectedNode.count }}
            </div>
            <el-divider></el-divider>
            <div class="dp-relations" v-if="relatedNodes.length > 0">
              <div class="dp-rel-title">关联节点 ({{ relatedNodes.length }})</div>
              <div class="dp-rel-list">
                <div
                  v-for="rel in relatedNodes"
                  :key="rel.node.id"
                  class="dp-rel-item"
                  @click="focusNode(rel.node)"
                >
                  <span class="dp-rel-dot" :style="{ background: getCategoryColor(rel.node.category) }"></span>
                  <span class="dp-rel-name">{{ rel.node.name }}</span>
                  <span class="dp-rel-type">{{ rel.relation }}</span>
                </div>
              </div>
            </div>
            <div class="dp-actions">
              <el-button type="primary" size="small" @click="expandNode" :disabled="!canExpand">
                <i class="el-icon-zoom-in"></i> 展开关联
              </el-button>
              <el-button size="small" @click="collapseNode">
                <i class="el-icon-zoom-out"></i> 收起
              </el-button>
            </div>
          </div>
        </transition>
      </div>
    </div>

    <div
      v-if="hoverNode"
      class="hover-tip"
      :style="{ left: tooltipPos.x + 'px', top: tooltipPos.y + 'px' }"
    >
      <div class="tip-row">
        <span class="tip-dot" :style="{ background: getCategoryColor(hoverNode.category) }"></span>
        <span class="tip-name">{{ hoverNode.name }}</span>
      </div>
      <div class="tip-cat">{{ getCategoryLabel(hoverNode.category) }}</div>
      <div class="tip-count" v-if="hoverNode.count">关联数: {{ hoverNode.count }}</div>
      <div class="tip-hint">点击查看详情</div>
    </div>

    <div
      v-if="hoverEdge"
      class="hover-tip"
      :style="{ left: tooltipPos.x + 'px', top: tooltipPos.y + 'px' }"
    >
      <div class="tip-edge-relation">{{ hoverEdge.relation }}</div>
      <div class="tip-edge-nodes">{{ hoverEdge.sourceName }} → {{ hoverEdge.targetName }}</div>
      <div class="tip-edge-weight" v-if="hoverEdge.weight">共现次数: {{ hoverEdge.weight }}</div>
    </div>

    <MainFooter />
  </div>
</template>

<script>
import * as echarts from 'echarts'
import axios from 'axios'
import MainHeader from '@/components/MainHeader/MainHeader'
import MainFooter from '@/components/MainFooter/MainFooter'

export default {
  name: 'KnowledgeGraph',
  components: { MainHeader, MainFooter },
  data () {
    return {
      searchKeyword: '',
      loading: false,
      chartInstance: null,
      allNodes: [],
      allEdges: [],
      displayedNodes: [],
      displayedEdges: [],
      expandedNodeIds: new Set(),
      categories: [
        { key: 'museum', label: '博物馆', color: '#FFA07A' },
        { key: 'dynasty', label: '朝代', color: '#45B7D1' },
        { key: 'artist', label: '作者', color: '#4ECDC4' },
        { key: 'material', label: '材质', color: '#98D8C8' },
        { key: 'type', label: '类型', color: '#C39BD3' },
        { key: 'location', label: '地点', color: '#85C1E9' },
        { key: 'culture', label: '文化', color: '#F7DC6F' },
        { key: 'relic', label: '文物', color: '#FF6B6B' }
      ],
      activeCategories: [],
      categoryCounts: {},
      selectedNode: null,
      relatedNodes: [],
      canExpand: false,
      hoverNode: null,
      hoverEdge: null,
      tooltipPos: { x: 0, y: 0 },
      nodeCount: 0,
      edgeCount: 0,
      layoutConfig: {
        repulsion: 600,
        gravity: 5,
        edgeLength: 120
      }
    }
  },
  mounted () {
    this.loadGraphData()
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.handleResize)
    if (this.chartInstance) {
      this.chartInstance.dispose()
    }
  },
  methods: {
    async loadGraphData () {
      this.loading = true
      try {
        const response = await axios.post('/knowledge/graph', {
          keyword: this.searchKeyword
        })
        if (response.data.state === 200) {
          const graphData = response.data.data
          this.processGraphData(graphData.nodes, graphData.edges, graphData.categoryCounts)
        } else {
          this.$message.error(response.data.message || '获取知识图谱数据失败')
          this.resetDisplay()
        }
      } catch (error) {
        console.error('获取知识图谱数据失败:', error)
        this.$message.error('无法连接后端服务')
        this.resetDisplay()
      } finally {
        this.loading = false
      }
    },
    resetDisplay () {
      this.allNodes = []
      this.allEdges = []
      this.displayedNodes = []
      this.displayedEdges = []
      this.updateStats()
      this.renderGraph()
    },
    processGraphData (nodes, edges, categoryCounts) {
      this.categoryCounts = categoryCounts || {}
      this.allNodes = nodes.map(n => ({
        id: n.id,
        name: n.name,
        category: n.category,
        attrs: this.buildAttrs(n),
        symbolSize: n.symbolSize || this.calcSymbolSize(n.category),
        color: n.color || this.getCategoryColor(n.category),
        count: n.value ? parseInt(n.value) : 0
      }))
      this.allEdges = edges.map(e => ({
        source: e.source,
        target: e.target,
        relation: e.relationType || e.label || '',
        weight: e.value || 1
      }))
      this.displayedNodes = [...this.allNodes]
      this.displayedEdges = [...this.allEdges]
      this.updateStats()
      this.renderGraph()
    },
    buildAttrs (node) {
      const attrs = {}
      if (node.value) {
        attrs['关联数'] = node.value
      }
      return attrs
    },
    calcSymbolSize (category) {
      const sizes = { relic: 50, museum: 36, dynasty: 38, artist: 40, material: 30, type: 30, location: 28, culture: 28 }
      return sizes[category] || 22
    },
    getCategoryColor (category) {
      const colors = {
        museum: '#FFA07A',
        dynasty: '#45B7D1',
        artist: '#4ECDC4',
        material: '#98D8C8',
        type: '#C39BD3',
        location: '#85C1E9',
        culture: '#F7DC6F',
        relic: '#FF6B6B'
      }
      return colors[category] || '#BBBBBB'
    },
    getCategoryLabel (category) {
      const labels = {
        museum: '博物馆',
        dynasty: '朝代',
        artist: '作者',
        material: '材质',
        type: '类型',
        location: '地点',
        culture: '文化',
        relic: '文物'
      }
      return labels[category] || category
    },
    getCategoryCount (key) {
      if (this.categoryCounts) {
        if (this.searchKeyword) {
          if (this.categoryCounts[key] !== undefined) {
            return this.categoryCounts[key]
          }
          const hasTotalKey = Object.keys(this.categoryCounts).some(k => k.endsWith('Total'))
          if (hasTotalKey) {
            return 0
          }
        }
        const totalKey = key + 'Total'
        if (this.categoryCounts[totalKey] !== undefined) {
          return this.categoryCounts[totalKey]
        }
        if (this.categoryCounts[key] !== undefined) {
          return this.categoryCounts[key]
        }
      }
      return this.allNodes.filter(n => n.category === key).length
    },
    updateStats () {
      if (this.categoryCounts) {
        let totalNodes = 0
        const keys = ['museum', 'dynasty', 'artist', 'material', 'type', 'location', 'culture', 'relic']
        for (const key of keys) {
          const totalKey = key + 'Total'
          if (this.categoryCounts[totalKey] !== undefined) {
            totalNodes += this.categoryCounts[totalKey]
          } else if (this.categoryCounts[key] !== undefined) {
            totalNodes += this.categoryCounts[key]
          }
        }
        this.nodeCount = totalNodes
      } else {
        this.nodeCount = this.displayedNodes.length
      }
      this.edgeCount = this.displayedEdges.length
    },
    renderGraph () {
      const dom = this.$refs.graphContainer
      if (!dom) return

      if (this.chartInstance) this.chartInstance.dispose()
      this.chartInstance = echarts.init(dom)

      const filteredNodes = this.displayedNodes.filter(n => this.activeCategories.includes(n.category))
      const filteredNodeIds = new Set(filteredNodes.map(n => n.id))
      const filteredEdges = this.displayedEdges.filter(
        e => filteredNodeIds.has(e.source) && filteredNodeIds.has(e.target)
      )

      const categoryData = this.categories.map(c => ({
        name: c.label,
        itemStyle: { color: c.color }
      }))

      const echartsNodes = filteredNodes.map(n => ({
        id: n.id,
        name: n.name,
        value: n.attrs,
        category: this.categories.findIndex(c => c.key === n.category),
        symbolSize: n.symbolSize,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 1, 1, [
            { offset: 0, color: n.color },
            { offset: 1, color: this.adjustColor(n.color, -40) }
          ]),
          borderColor: 'rgba(255,255,255,0.8)',
          borderWidth: 2,
          shadowBlur: 6,
          shadowColor: n.color + '30'
        },
        label: {
          show: false,
          fontSize: n.symbolSize > 35 ? 12 : 10,
          color: '#2c3e50',
          position: 'bottom',
          distance: 4,
          fontWeight: n.symbolSize > 35 ? 600 : 400
        }
      }))

      const echartsEdges = filteredEdges.map(e => {
        const weight = e.weight || 1
        const lineWidth = Math.max(0.8, Math.min(weight / 50, 6))
        return {
          source: e.source,
          target: e.target,
          value: weight,
          label: {
            show: false,
            formatter: e.relation,
            fontSize: 9,
            color: '#7f8c8d',
            backgroundColor: 'rgba(255,255,255,0.85)',
            padding: [2, 4],
            borderRadius: 3
          },
          lineStyle: {
            color: '#c8d6e5',
            width: lineWidth,
            curveness: 0.1,
            opacity: Math.max(0.2, Math.min(weight / 100, 0.8))
          }
        }
      })

      const option = {
        tooltip: { show: false },
        legend: {
          data: categoryData.map(c => c.name),
          orient: 'horizontal',
          bottom: 8,
          left: 'center',
          textStyle: { color: '#606266', fontSize: 12 },
          itemWidth: 10,
          itemHeight: 10,
          itemGap: 16
        },
        series: [{
          type: 'graph',
          layout: 'force',
          data: echartsNodes,
          links: echartsEdges,
          categories: categoryData,
          roam: true,
          draggable: true,
          force: {
            repulsion: this.layoutConfig.repulsion,
            gravity: this.layoutConfig.gravity / 100,
            edgeLength: [this.layoutConfig.edgeLength * 0.5, this.layoutConfig.edgeLength * 2],
            layoutAnimation: true,
            friction: 0.6
          },
          label: {
            position: 'bottom',
            formatter: '{b}'
          },
          lineStyle: {
            color: 'source',
            curveness: 0.1,
            opacity: 0.5
          },
          emphasis: {
            focus: 'adjacency',
            label: { fontSize: 14, fontWeight: 'bold' },
            lineStyle: { width: 3, opacity: 1 }
          },
          animation: true,
          animationDuration: 600,
          animationEasingUpdate: 'cubicOut'
        }]
      }

      this.chartInstance.setOption(option)

      this.chartInstance.on('click', (params) => {
        if (params.dataType === 'node') {
          this.onNodeClick(params)
        }
      })

      this.chartInstance.on('mouseover', (params) => {
        if (params.dataType === 'node') {
          this.onNodeHover(params)
        } else if (params.dataType === 'edge') {
          this.onEdgeHover(params)
        }
      })

      this.chartInstance.on('mouseout', () => {
        this.hoverNode = null
        this.hoverEdge = null
      })
    },
    adjustColor (hex, amount) {
      if (!hex || hex.length < 7) return hex
      const num = parseInt(hex.slice(1), 16)
      let r = Math.min(255, Math.max(0, (num >> 16) + amount))
      let g = Math.min(255, Math.max(0, ((num >> 8) & 0x00FF) + amount))
      let b = Math.min(255, Math.max(0, (num & 0x0000FF) + amount))
      return '#' + (0x1000000 + r * 0x10000 + g * 0x100 + b).toString(16).slice(1)
    },
    onNodeClick (params) {
      const node = this.allNodes.find(n => n.id === params.data.id)
      if (!node) return
      this.selectedNode = node
      this.canExpand = !this.expandedNodeIds.has(node.id)
      const related = []
      this.allEdges.forEach(e => {
        if (e.source === node.id) {
          const target = this.allNodes.find(n => n.id === e.target)
          if (target) related.push({ node: target, relation: e.relation, weight: e.weight })
        }
        if (e.target === node.id) {
          const source = this.allNodes.find(n => n.id === e.source)
          if (source) related.push({ node: source, relation: e.relation, weight: e.weight })
        }
      })
      this.relatedNodes = related
    },
    onNodeHover (params) {
      const node = this.allNodes.find(n => n.id === params.data.id)
      if (!node) return
      const event = params.event.event
      this.hoverNode = node
      this.hoverEdge = null
      this.tooltipPos = {
        x: event.offsetX + 15,
        y: event.offsetY + 15
      }
    },
    onEdgeHover (params) {
      const edgeData = params.data
      const sourceNode = this.allNodes.find(n => n.id === edgeData.source)
      const targetNode = this.allNodes.find(n => n.id === edgeData.target)
      if (!sourceNode || !targetNode) return
      const event = params.event.event
      this.hoverNode = null
      this.hoverEdge = {
        sourceName: sourceNode.name,
        targetName: targetNode.name,
        relation: edgeData.label || edgeData.relationType || '',
        weight: edgeData.value
      }
      this.tooltipPos = {
        x: event.offsetX + 15,
        y: event.offsetY + 15
      }
    },
    expandNode () {
      if (!this.selectedNode) return
      const nodeId = this.selectedNode.id
      this.expandedNodeIds.add(nodeId)
      this.canExpand = false
      const connectedNodeIds = new Set()
      this.allEdges.forEach(e => {
        if (e.source === nodeId) connectedNodeIds.add(e.target)
        if (e.target === nodeId) connectedNodeIds.add(e.source)
      })
      const existingIds = new Set(this.displayedNodes.map(n => n.id))
      const newNodes = this.allNodes.filter(n => connectedNodeIds.has(n.id) && !existingIds.has(n.id))
      if (newNodes.length > 0) {
        this.displayedNodes = [...this.displayedNodes, ...newNodes]
        const newNodeIds = new Set(this.displayedNodes.map(n => n.id))
        this.displayedEdges = this.allEdges.filter(e => newNodeIds.has(e.source) && newNodeIds.has(e.target))
        this.updateStats()
        this.renderGraph()
        this.$message.success(`展开了 ${newNodes.length} 个关联节点`)
      } else {
        this.$message.info('所有关联节点已展示')
      }
    },
    collapseNode () {
      if (!this.selectedNode) return
      this.expandedNodeIds.delete(this.selectedNode.id)
      this.displayedNodes = [...this.allNodes]
      this.displayedEdges = [...this.allEdges]
      this.updateStats()
      this.renderGraph()
    },
    focusNode (node) {
      if (!this.chartInstance) return
      this.chartInstance.dispatchAction({ type: 'highlight', name: node.name })
      this.onNodeClick({ data: node })
    },
    closeDetail () {
      this.selectedNode = null
      this.relatedNodes = []
    },
    toggleCategory (key) {
      const idx = this.activeCategories.indexOf(key)
      if (idx > -1) {
        this.activeCategories.splice(idx, 1)
      } else {
        this.activeCategories.push(key)
      }
      this.renderGraph()
    },
    toggleAllCategories (show) {
      this.activeCategories = show ? this.categories.map(c => c.key) : []
      this.renderGraph()
    },
    handleSearch () {
      this.loadGraphData()
    },
    resetGraph () {
      this.searchKeyword = ''
      this.selectedNode = null
      this.relatedNodes = []
      this.expandedNodeIds.clear()
      this.activeCategories = []
      this.loadGraphData()
    },
    updateLayout () {
      this.renderGraph()
    },
    handleResize () {
      this.chartInstance && this.chartInstance.resize()
    }
  }
}
</script>

<style lang="scss" scoped>
.kg-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: #ffffffff;
}

.kg-hero {
  position: relative;
  padding: 24px 5% 18px;
  background: linear-gradient(135deg, #0a1628 0%, #162a4a 50%, #1a3a5c 100%);
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -40%;
    right: -5%;
    width: 280px;
    height: 280px;
    background: radial-gradient(circle, rgba(69,183,209,0.12) 0%, transparent 70%);
    border-radius: 50%;
  }
}

.hero-inner {
  position: relative;
  z-index: 1;
  text-align: center;
}

.hero-title {
  font-size: 24px;
  font-weight: 700;
  color: #e8f0fe;
  margin-bottom: 4px;
  letter-spacing: 3px;
}

.hero-sub {
  font-size: 13px;
  color: rgba(232,240,254,0.55);
  letter-spacing: 1px;
}

.kg-body {
  flex: 1;
  display: flex;
  padding: 16px 3% 24px;
  gap: 16px;
  min-height: calc(100vh - 180px);
}

.kg-sidebar {
  width: 260px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.sidebar-section {
  background: rgba(22,42,74,0.85);
  border: 1px solid rgba(69,183,209,0.15);
  border-radius: 12px;
  padding: 14px 16px;
  backdrop-filter: blur(6px);
}

.section-head {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: #a8c8e8;
  margin-bottom: 10px;

  i {
    font-size: 14px;
    color: #45B7D1;
  }
}

.search-box {
  .el-input {
    margin-bottom: 8px;
  }
}

.search-actions {
  display: flex;
  gap: 6px;

  .el-button--primary {
    background: linear-gradient(135deg, #45B7D1, #2d8fa8) !important;
    border: none !important;
  }

  .el-button--default {
    background: rgba(255,255,255,0.06) !important;
    border-color: rgba(69,183,209,0.3) !important;
    color: #a8c8e8 !important;
  }
}

.filter-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 10px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;

  &:hover {
    background: rgba(69,183,209,0.08);
  }

  &.active {
    background: rgba(69,183,209,0.15);
  }
}

.filter-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.filter-label {
  flex: 1;
  font-size: 13px;
  color: #c8d8e8;
}

.filter-count {
  font-size: 11px;
  color: #5a7a9a;
  background: rgba(255,255,255,0.05);
  padding: 1px 6px;
  border-radius: 8px;
}

.filter-actions {
  display: flex;
  gap: 6px;
  margin-top: 8px;

  .el-button--mini {
    background: rgba(255,255,255,0.06) !important;
    border-color: rgba(69,183,209,0.25) !important;
    color: #7aa8c8 !important;
    font-size: 11px;
    padding: 4px 10px;
  }
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.stat-card {
  background: rgba(69,183,209,0.08);
  border: 1px solid rgba(69,183,209,0.12);
  border-radius: 8px;
  padding: 10px;
  text-align: center;
}

.stat-val {
  font-size: 22px;
  font-weight: 700;
  color: #45B7D1;
}

.stat-lbl {
  font-size: 11px;
  color: #5a7a9a;
  margin-top: 2px;
}

.layout-controls {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.control-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ctrl-label {
  font-size: 12px;
  color: #7aa8c8;
  width: 48px;
  flex-shrink: 0;
}

.kg-main {
  flex: 1;
  display: flex;
  gap: 12px;
  position: relative;
  min-width: 0;
}

.graph-wrapper {
  flex: 1;
  position: relative;
  background: rgba(22,42,74,0.6);
  border: 1px solid rgba(69,183,209,0.12);
  border-radius: 12px;
  overflow: hidden;
}

.graph-canvas {
  width: 100%;
  height: 100%;
  min-height: calc(100vh - 220px);
}

.empty-hint {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
  pointer-events: none;

  i {
    font-size: 48px;
    color: #c0c4cc;
    margin-bottom: 16px;
    display: block;
  }

  .empty-title {
    font-size: 16px;
    font-weight: 600;
    color: #909399;
    margin-bottom: 6px;
  }

  .empty-sub {
    font-size: 13px;
    color: #b0b6bf;
  }
}

.detail-panel {
  width: 280px;
  flex-shrink: 0;
  background: rgba(22,42,74,0.92);
  border: 1px solid rgba(69,183,209,0.18);
  border-radius: 12px;
  padding: 16px 18px;
  display: flex;
  flex-direction: column;
  backdrop-filter: blur(8px);
  max-height: calc(100vh - 220px);
  overflow-y: auto;
}

.dp-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.dp-type {
  display: flex;
  align-items: center;
  gap: 6px;
}

.dp-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.dp-type-text {
  font-size: 12px;
  color: #7aa8c8;
}

.dp-close {
  color: #5a7a9a;
  cursor: pointer;
  font-size: 16px;
  transition: color 0.2s;

  &:hover {
    color: #45B7D1;
  }
}

.dp-name {
  font-size: 16px;
  font-weight: 600;
  color: #e8f0fe;
  margin-bottom: 4px;
}

.dp-count {
  font-size: 12px;
  color: #45B7D1;

  i {
    margin-right: 4px;
  }
}

.el-divider {
  margin: 12px 0;
  border-color: rgba(69,183,209,0.15);
}

.dp-rel-title {
  font-size: 12px;
  font-weight: 600;
  color: #a8c8e8;
  margin-bottom: 8px;
}

.dp-rel-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
  max-height: 300px;
  overflow-y: auto;
}

.dp-rel-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;

  &:hover {
    background: rgba(69,183,209,0.1);
  }
}

.dp-rel-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.dp-rel-name {
  flex: 1;
  font-size: 12px;
  color: #c8d8e8;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dp-rel-type {
  font-size: 10px;
  color: #5a7a9a;
  background: rgba(255,255,255,0.05);
  padding: 1px 6px;
  border-radius: 4px;
  flex-shrink: 0;
}

.dp-actions {
  margin-top: 14px;
  display: flex;
  gap: 8px;

  .el-button--primary {
    background: linear-gradient(135deg, #45B7D1, #2d8fa8) !important;
    border: none !important;
  }

  .el-button--default {
    background: rgba(255,255,255,0.06) !important;
    border-color: rgba(69,183,209,0.3) !important;
    color: #a8c8e8 !important;
  }
}

.hover-tip {
  position: fixed;
  z-index: 9999;
  background: rgba(10,22,40,0.94);
  border: 1px solid rgba(69,183,209,0.25);
  border-radius: 10px;
  padding: 10px 14px;
  pointer-events: none;
  backdrop-filter: blur(8px);
  min-width: 140px;
}

.tip-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
}

.tip-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.tip-name {
  font-size: 13px;
  font-weight: 600;
  color: #e8f0fe;
}

.tip-cat {
  font-size: 11px;
  color: rgba(168,200,232,0.6);
  margin-bottom: 2px;
}

.tip-count {
  font-size: 11px;
  color: #45B7D1;
  font-weight: 500;
}

.tip-hint {
  margin-top: 6px;
  font-size: 10px;
  color: rgba(69,183,209,0.5);
  border-top: 1px solid rgba(69,183,209,0.1);
  padding-top: 4px;
}

.tip-edge-relation {
  font-size: 13px;
  font-weight: 600;
  color: #e8f0fe;
  margin-bottom: 4px;
}

.tip-edge-nodes {
  font-size: 11px;
  color: rgba(168,200,232,0.7);
  margin-bottom: 2px;
}

.tip-edge-weight {
  font-size: 11px;
  color: #45B7D1;
  font-weight: 500;
}

.panel-slide-enter-active, .panel-slide-leave-active {
  transition: all 0.3s ease;
}

.panel-slide-enter, .panel-slide-leave-to {
  transform: translateX(20px);
  opacity: 0;
}
</style>
