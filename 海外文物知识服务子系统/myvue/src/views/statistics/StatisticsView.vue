<template>
  <div class="statistics-container">
    <MainHeader></MainHeader>
    
    <div class="page-hero">
      <div class="hero-content">
        <h1 class="hero-title">数据统计分析</h1>
        <p class="hero-desc">全方位洞察海外文物收藏分布与历史脉络</p>
      </div>
    </div>

    <div class="page-body">
      <div class="stats-overview">
        <div class="stat-card stat-card-1">
          <div class="stat-bg-icon"><i class="el-icon-trophy"></i></div>
          <div class="stat-content">
            <div class="stat-number">{{ totalAntiques }}</div>
            <div class="stat-desc">文物总数</div>
          </div>
          <div class="stat-decoration"></div>
        </div>
        <div class="stat-card stat-card-2">
          <div class="stat-bg-icon"><i class="el-icon-collection"></i></div>
          <div class="stat-content">
            <div class="stat-number">{{ categoryCount }}</div>
            <div class="stat-desc">文物类型</div>
          </div>
          <div class="stat-decoration"></div>
        </div>
        <div class="stat-card stat-card-3">
          <div class="stat-bg-icon"><i class="el-icon-office-building"></i></div>
          <div class="stat-content">
            <div class="stat-number">{{ museumCount }}</div>
            <div class="stat-desc">馆藏机构</div>
          </div>
          <div class="stat-decoration"></div>
        </div>
        <div class="stat-card stat-card-4">
          <div class="stat-bg-icon"><i class="el-icon-date"></i></div>
          <div class="stat-content">
            <div class="stat-number">{{ dynastyCount }}</div>
            <div class="stat-desc">历史朝代</div>
          </div>
          <div class="stat-decoration"></div>
        </div>
      </div>

      <div class="charts-grid">
        <div class="chart-card chart-card-full">
          <div class="card-header">
            <div class="card-title-group">
              <span class="card-icon icon-dynasty"></span>
              <span class="card-title">朝代分布统计</span>
            </div>
            <el-select v-model="dynastyChartType" size="small" class="chart-type-select">
              <el-option label="柱状图" value="bar"></el-option>
              <el-option label="横向柱状" value="horizontalBar"></el-option>
              <el-option label="饼图" value="pie"></el-option>
              <el-option label="环形图" value="doughnut"></el-option>
              <el-option label="玫瑰图" value="rose"></el-option>
            </el-select>
          </div>
          <div ref="dynastyChart" class="chart-container chart-container-wide"></div>
        </div>

        <div class="chart-card chart-card-full">
          <div class="card-header">
            <div class="card-title-group">
              <span class="card-icon icon-type"></span>
              <span class="card-title">文物类型占比</span>
            </div>
            <el-select v-model="categoryChartType" size="small" class="chart-type-select">
              <el-option label="饼图" value="pie"></el-option>
              <el-option label="环形图" value="doughnut"></el-option>
              <el-option label="玫瑰图" value="rose"></el-option>
              <el-option label="柱状图" value="bar"></el-option>
              <el-option label="横向柱状" value="horizontalBar"></el-option>
            </el-select>
          </div>
          <div ref="categoryChart" class="chart-container chart-container-wide"></div>
        </div>

        <div class="chart-card chart-card-full">
          <div class="card-header">
            <div class="card-title-group">
              <span class="card-icon icon-material"></span>
              <span class="card-title">文物材质分布</span>
            </div>
            <el-select v-model="materialChartType" size="small" class="chart-type-select">
              <el-option label="饼图" value="pie"></el-option>
              <el-option label="环形图" value="doughnut"></el-option>
              <el-option label="玫瑰图" value="rose"></el-option>
              <el-option label="柱状图" value="bar"></el-option>
              <el-option label="横向柱状" value="horizontalBar"></el-option>
            </el-select>
          </div>
          <div ref="materialChart" class="chart-container chart-container-wide"></div>
        </div>

        <div class="chart-card">
          <div class="card-header">
            <div class="card-title-group">
              <span class="card-icon icon-region"></span>
              <span class="card-title">海外藏地区域分布</span>
            </div>
            <el-select v-model="regionChartType" size="small" class="chart-type-select">
              <el-option label="饼图" value="pie"></el-option>
              <el-option label="环形图" value="doughnut"></el-option>
              <el-option label="玫瑰图" value="rose"></el-option>
              <el-option label="柱状图" value="bar"></el-option>
              <el-option label="横向柱状" value="horizontalBar"></el-option>
            </el-select>
          </div>
          <div ref="regionChart" class="chart-container chart-container-lg"></div>
        </div>

        <div class="chart-card">
          <div class="card-header">
            <div class="card-title-group">
              <span class="card-icon icon-museum"></span>
              <span class="card-title">博物馆藏量排行</span>
            </div>
            <el-select v-model="museumChartType" size="small" class="chart-type-select">
              <el-option label="横向柱状" value="horizontalBar"></el-option>
              <el-option label="柱状图" value="bar"></el-option>
              <el-option label="饼图" value="pie"></el-option>
              <el-option label="环形图" value="doughnut"></el-option>
              <el-option label="玫瑰图" value="rose"></el-option>
            </el-select>
          </div>
          <div ref="museumChart" class="chart-container chart-container-lg"></div>
        </div>
      </div>
    </div>

    <MainFooter></MainFooter>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import axios from 'axios'
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'

const COLORS = [
  '#667eea', '#764ba2', '#f093fb', '#4facfe', '#43e97b', '#fa709a',
  '#a18cd1', '#fbc2eb', '#fccb90', '#84fab0', '#8fd3f4', '#d4fc79',
  '#96fbc4', '#f9f586', '#ff9a9e', '#fad0c4'
]

export default {
  name: 'StatisticsView',
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    return {
      totalAntiques: 0,
      categoryCount: 0,
      museumCount: 0,
      dynastyCount: 0,
      dynastyChartType: 'bar',
      museumChartType: 'horizontalBar',
      categoryChartType: 'pie',
      materialChartType: 'pie',
      regionChartType: 'pie',
      charts: {},
      statData: null
    }
  },
  
  watch: {
    dynastyChartType () { this.renderDynastyChart() },
    museumChartType () { this.renderMuseumChart() },
    categoryChartType () { this.renderCategoryChart() },
    materialChartType () { this.renderMaterialChart() },
    regionChartType () { this.renderRegionChart() }
  },
  
  mounted () {
    this.loadStatistics()
    window.addEventListener('resize', this.handleResize)
  },
  
  beforeDestroy () {
    window.removeEventListener('resize', this.handleResize)
    Object.values(this.charts).forEach(chart => chart && chart.dispose())
  },
  
  methods: {
    async loadStatistics () {
      try {
        const response = await axios.get('/dataviz/statistics')
        if (response.data.state === 200) {
          this.statData = response.data.data
          this.totalAntiques = this.statData.totalAntiques || 0
          this.categoryCount = this.statData.categoryCount || 0
          this.museumCount = this.statData.museumCount || 0
          this.dynastyCount = this.statData.dynastyCount || 0
        } else {
          this.$message.error(response.data.message || '获取统计数据失败')
          this.statData = null
        }
      } catch (error) {
        console.error('获取统计数据失败:', error)
        this.$message.error('无法连接后端服务，请确保服务已启动')
        this.statData = null
      }
      await this.$nextTick()
      this.initAllCharts()
    },

    initAllCharts () {
      this.renderDynastyChart()
      this.renderMuseumChart()
      this.renderCategoryChart()
      this.renderMaterialChart()
      this.renderRegionChart()
    },
    
    handleResize () {
      Object.values(this.charts).forEach(chart => chart && chart.resize())
    },

    preparePieData (raw, topN) {
      let data = (raw || []).map(d => ({ value: d.value, name: d.name }))
      if (data.length === 0) data.push({ value: 1, name: '暂无数据' })
      let displayData = data.slice(0, topN)
      const otherValue = data.slice(topN).reduce((sum, d) => sum + d.value, 0)
      if (otherValue > 0) {
        displayData.push({ value: otherValue, name: '其他' })
      }
      return displayData
    },

    buildPieOption (data, chartType) {
      const base = {
        tooltip: {
          trigger: 'item',
          formatter: '{b}: {c}件 ({d}%)',
          backgroundColor: 'rgba(26,26,46,0.9)',
          borderColor: 'transparent',
          textStyle: { color: '#fff', fontSize: 13 }
        },
        legend: {
          type: 'scroll',
          orient: 'vertical',
          right: '5%',
          top: 'middle',
          height: '80%',
          textStyle: { color: '#606266', fontSize: 12 },
          pageTextStyle: { color: '#667eea' }
        },
        color: COLORS
      }
      if (chartType === 'pie') {
        return {
          ...base,
          series: [{
            type: 'pie', radius: ['30%', '60%'], center: ['35%', '50%'],
            avoidLabelOverlap: true,
            itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 3 },
            label: { show: false },
            emphasis: {
              label: { show: true, fontSize: 14, fontWeight: 'bold', color: '#303133' },
              itemStyle: { shadowBlur: 20, shadowColor: 'rgba(102,126,234,0.3)' }
            },
            data: data
          }]
        }
      } else if (chartType === 'doughnut') {
        return {
          ...base,
          series: [{
            type: 'pie', radius: ['45%', '65%'], center: ['35%', '50%'],
            itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 3 },
            label: { show: false },
            emphasis: {
              label: { show: true, fontSize: 14, fontWeight: 'bold', color: '#303133' },
              itemStyle: { shadowBlur: 20, shadowColor: 'rgba(102,126,234,0.3)' }
            },
            data: data
          }]
        }
      } else {
        return {
          ...base,
          series: [{
            type: 'pie', radius: [20, 100], center: ['35%', '50%'], roseType: 'area',
            itemStyle: { borderRadius: 10 },
            label: { show: false },
            emphasis: {
              label: { show: true, fontSize: 14, fontWeight: 'bold', color: '#303133' },
              itemStyle: { shadowBlur: 20, shadowColor: 'rgba(102,126,234,0.3)' }
            },
            data: [...data].sort((a, b) => a.value - b.value)
          }]
        }
      }
    },

    buildBarOption (data, chartType, nameField, fontSize) {
      const fs = fontSize || 12
      if (chartType === 'bar') {
        return {
          tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            backgroundColor: 'rgba(26,26,46,0.9)',
            borderColor: 'transparent',
            textStyle: { color: '#fff' }
          },
          grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
          xAxis: {
            type: 'category', data: data.map(d => d.name),
            axisLabel: { rotate: 30, color: '#606266', fontSize: fs },
            axisLine: { lineStyle: { color: '#e0e0e0' } },
            axisTick: { show: false }
          },
          yAxis: {
            type: 'value', name: '数量',
            nameTextStyle: { color: '#909399', fontSize: 11 },
            axisLine: { show: false },
            splitLine: { lineStyle: { color: '#f0f0f0', type: 'dashed' } }
          },
          series: [{
            type: 'bar', data: data.map(d => d.value), barWidth: '55%',
            itemStyle: {
              borderRadius: [6, 6, 0, 0],
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#667eea' }, { offset: 1, color: '#764ba2' }
              ])
            },
            label: { show: true, position: 'top', color: '#667eea', fontSize: fs, fontWeight: 500 }
          }]
        }
      } else {
        return {
          tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            backgroundColor: 'rgba(26,26,46,0.9)',
            borderColor: 'transparent',
            textStyle: { color: '#fff' }
          },
          grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
          xAxis: {
            type: 'value',
            axisLine: { show: false },
            splitLine: { lineStyle: { color: '#f0f0f0', type: 'dashed' } }
          },
          yAxis: {
            type: 'category', data: data.map(d => d.name).reverse(),
            axisLabel: { color: '#606266', fontSize: fs },
            axisLine: { lineStyle: { color: '#e0e0e0' } },
            axisTick: { show: false }
          },
          series: [{
            type: 'bar', data: data.map(d => d.value).reverse(), barWidth: '55%',
            itemStyle: {
              borderRadius: [0, 6, 6, 0],
              color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
                { offset: 0, color: '#667eea' }, { offset: 1, color: '#764ba2' }
              ])
            },
            label: { show: true, position: 'right', color: '#667eea', fontSize: fs, fontWeight: 500 }
          }]
        }
      }
    },

    isPieType (type) {
      return ['pie', 'doughnut', 'rose'].includes(type)
    },

    getChart (refName, key) {
      const dom = this.$refs[refName]
      if (!dom) return null
      if (this.charts[key]) this.charts[key].dispose()
      const chart = echarts.init(dom)
      this.charts[key] = chart
      return chart
    },
    
    renderCategoryChart () {
      const chart = this.getChart('categoryChart', 'category')
      if (!chart) return
      const raw = this.statData && this.statData.categoryDistribution ? this.statData.categoryDistribution : []
      const data = this.preparePieData(raw, 15)
      if (this.isPieType(this.categoryChartType)) {
        chart.setOption(this.buildPieOption(data, this.categoryChartType))
      } else {
        chart.setOption(this.buildBarOption(data, this.categoryChartType))
      }
    },
    
    renderDynastyChart () {
      const chart = this.getChart('dynastyChart', 'dynasty')
      if (!chart) return
      const data = (this.statData && this.statData.dynastyDistribution ? this.statData.dynastyDistribution : [])
      if (data.length === 0) data.push({ name: '暂无数据', value: 0 })
      if (this.isPieType(this.dynastyChartType)) {
        chart.setOption(this.buildPieOption(data, this.dynastyChartType))
      } else {
        chart.setOption(this.buildBarOption(data, this.dynastyChartType))
      }
    },
    
    renderMuseumChart () {
      const chart = this.getChart('museumChart', 'museum')
      if (!chart) return
      const data = (this.statData && this.statData.museumRanking ? this.statData.museumRanking : [])
      if (data.length === 0) data.push({ name: '暂无数据', value: 0 })
      if (this.isPieType(this.museumChartType)) {
        chart.setOption(this.buildPieOption(data, this.museumChartType))
      } else {
        chart.setOption(this.buildBarOption(data, this.museumChartType, 'name', 11))
      }
    },
    
    renderMaterialChart () {
      const chart = this.getChart('materialChart', 'material')
      if (!chart) return
      const raw = this.statData && this.statData.materialDistribution ? this.statData.materialDistribution : []
      const data = this.preparePieData(raw, 15)
      if (this.isPieType(this.materialChartType)) {
        chart.setOption(this.buildPieOption(data, this.materialChartType))
      } else {
        chart.setOption(this.buildBarOption(data, this.materialChartType))
      }
    },
    
    renderRegionChart () {
      const chart = this.getChart('regionChart', 'region')
      if (!chart) return
      const data = (this.statData && this.statData.regionDistribution ? this.statData.regionDistribution : [])
      if (data.length === 0) data.push({ name: '暂无数据', value: 0 })
      if (this.isPieType(this.regionChartType)) {
        chart.setOption(this.buildPieOption(data, this.regionChartType))
      } else {
        chart.setOption(this.buildBarOption(data, this.regionChartType))
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.statistics-container {
  min-height: 100vh;
  background: #f5f7fa;
}

.page-hero {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  padding: 28px 5% 22px;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -10%;
    width: 300px;
    height: 300px;
    background: radial-gradient(circle, rgba(102,126,234,0.15) 0%, transparent 70%);
    border-radius: 50%;
  }

  &::after {
    content: '';
    position: absolute;
    bottom: -30%;
    left: 10%;
    width: 200px;
    height: 200px;
    background: radial-gradient(circle, rgba(118,75,162,0.1) 0%, transparent 70%);
    border-radius: 50%;
  }
}

.hero-content {
  position: relative;
  z-index: 1;
  text-align: center;
}

.hero-title {
  font-size: 26px;
  font-weight: 700;
  color: #fff;
  margin-bottom: 6px;
  letter-spacing: 2px;
}

.hero-desc {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  letter-spacing: 1px;
}

.page-body {
  padding: 30px 5% 40px;
  margin-top: -20px;
  position: relative;
  z-index: 2;
}

.stats-overview {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: #fff;
  border-radius: 16px;
  padding: 28px 24px;
  position: relative;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
  transition: all 0.3s ease;
  display: flex;
  align-items: center;

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1);
  }
}

.stat-bg-icon {
  position: absolute;
  right: 15px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 60px;
  opacity: 0.06;
}

.stat-card-1 {
  background: linear-gradient(135deg, #1e2a4a 0%, #2c3e6b 100%);
  box-shadow: 0 4px 20px rgba(30, 42, 74, 0.3);

  .stat-number, .stat-desc, .stat-bg-icon i { color: #fff; }
  .stat-desc { opacity: 0.75; }
  .stat-decoration { background: rgba(255,255,255,0.06); }
}

.stat-card-2 {
  background: linear-gradient(135deg, #1a3a4a 0%, #2c5060 100%);
  box-shadow: 0 4px 20px rgba(26, 58, 74, 0.3);

  .stat-number, .stat-desc, .stat-bg-icon i { color: #fff; }
  .stat-desc { opacity: 0.75; }
  .stat-decoration { background: rgba(255,255,255,0.06); }
}

.stat-card-3 {
  background: linear-gradient(135deg, #3a1a2e 0%, #5a2a42 100%);
  box-shadow: 0 4px 20px rgba(58, 26, 46, 0.3);

  .stat-number, .stat-desc, .stat-bg-icon i { color: #fff; }
  .stat-desc { opacity: 0.75; }
  .stat-decoration { background: rgba(255,255,255,0.06); }
}

.stat-card-4 {
  background: linear-gradient(135deg, #2a1a4a 0%, #3e2a6a 100%);
  box-shadow: 0 4px 20px rgba(42, 26, 74, 0.3);

  .stat-number, .stat-desc, .stat-bg-icon i { color: #fff; }
  .stat-desc { opacity: 0.75; }
  .stat-decoration { background: rgba(255,255,255,0.06); }
}

.stat-content {
  position: relative;
  z-index: 1;
}

.stat-number {
  font-size: 36px;
  font-weight: 700;
  line-height: 1.2;
}

.stat-desc {
  font-size: 14px;
  margin-top: 4px;
}

.stat-decoration {
  position: absolute;
  right: -20px;
  bottom: -20px;
  width: 80px;
  height: 80px;
  border-radius: 50%;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

.chart-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
  overflow: hidden;
  transition: all 0.3s ease;

  &:hover {
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1);
  }
}

.chart-card-full {
  grid-column: 1 / -1;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px 0;
}

.card-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.card-icon {
  width: 8px;
  height: 24px;
  border-radius: 4px;
}

.icon-dynasty { background: linear-gradient(180deg, #667eea, #764ba2); }
.icon-museum { background: linear-gradient(180deg, #fa709a, #fee140); }
.icon-type { background: linear-gradient(180deg, #43e97b, #38f9d7); }
.icon-material { background: linear-gradient(180deg, #a18cd1, #fbc2eb); }
.icon-region { background: linear-gradient(180deg, #4facfe, #00f2fe); }

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.chart-type-select {
  width: 110px;
}

.chart-container { height: 340px; padding: 10px; }
.chart-container-lg { height: 380px; }
.chart-container-wide { height: 450px; }
</style>
