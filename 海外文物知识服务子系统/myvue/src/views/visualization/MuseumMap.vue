<template>
  <div class="map-page">
    <h2>文物地理分布图</h2>
    <p>展示博物馆馆藏文物的地理分布情况。</p>

    <div ref="chartRef" class="map-chart"></div>

    <div class="chart-section">
  <div class="chart-card">
    <h3>文物类型占比</h3>
    <div ref="typePieRef" class="pie-chart"></div>
  </div>
</div>

    <div class="stat-row">
  <div class="stat-card">
    <div class="stat-title">文物数量</div>
    <div class="stat-num">7132</div>
    <div class="stat-desc">海外馆藏中国文物总数</div>
  </div>

  <div class="stat-card">
    <div class="stat-title">海外机构</div>
    <div class="stat-num">3</div>
    <div class="stat-desc">当前数据库覆盖机构</div>
  </div>

  <div class="stat-card">
    <div class="stat-title">覆盖地区</div>
    <div class="stat-num">3</div>
    <div class="stat-desc">美国、英国等地区</div>
  </div>
</div>
    <el-dialog
  v-model="dialogVisible"
  title="博物馆详情"
  width="500px"
>
  <p><strong>名称：</strong>{{ selectedMuseum.name }}</p>
  <p><strong>国家：</strong>{{ selectedMuseum.country }}</p>
  <p><strong>文物总数：</strong>{{ selectedMuseum.value ? selectedMuseum.value[2] : 0 }} 件</p>

  <hr>

  <p>青铜器：{{ selectedMuseum.bronze }} 件</p>
  <p>瓷器：{{ selectedMuseum.porcelain }} 件</p>
  <p>书画：{{ selectedMuseum.painting }} 件</p>
</el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import axios from 'axios'
import worldJson from '@/assets/map/world.json'

export default {
  name: 'MuseumMap',

  data () {
    return {
      dialogVisible: false,
      selectedMuseum: {
        name: '',
        country: '',
        value: [0, 0, 0],
        bronze: 0,
        porcelain: 0,
        painting: 0
      },
      coordMap: {
        'Harvard Art Museums': [-71.114, 42.374],
        'Smithsonian Institution': [-77.026, 38.888],
        'Museum of Fine Arts, Boston': [-71.094, 42.339]
      }
    }
  },

  mounted () {
    this.fetchMuseumMapData()
    this.fetchTypeStat()
  },

  methods: {
    fetchMuseumMapData () {
      axios.get('http://localhost:8085/visualization/museum-map')
        .then(res => {
          const list = res.data.data

          const museumData = list.map(item => {
            const coord = this.coordMap[item.name]

            return {
              name: item.name,
              country: item.location,
              value: [coord[0], coord[1], item.count],
              bronze: 0,
              porcelain: 0,
              painting: 0
            }
          })

          this.drawMap(museumData)
        })
        .catch(err => {
          console.log(err)
        })
    },

    fetchTypeStat () {
      axios.get('http://localhost:8085/visualization/type-stat')
        .then(res => {
         const typeMap = {
  'Ceramics': '陶瓷器',
  'Paintings': '绘画',
  'Ritual Implements': '礼器',
  'Sculpture': '雕塑',
  'Textiles': '纺织品',
  'Prints': '版画',
  'Tools & Weapons': '工具与兵器',
  'Jewelry & Ornaments': '珠宝饰品'
}

const typeData = res.data.data.map(item => ({
  name: typeMap[item.name] || item.name,
  value: item.value
}))
          this.drawTypePie(typeData)
        })
        .catch(err => {
          console.log(err)
        })
    },

    drawMap (museumData) {
      echarts.registerMap('world', worldJson)

      const chart = echarts.init(this.$refs.chartRef)

      chart.setOption({
        title: {
          text: '文物地理分布图',
          left: 'center'
        },
        tooltip: {
          trigger: 'item',
          formatter (params) {
            return `
              博物馆：${params.name}<br/>
              文物数量：${params.value ? params.value[2] : '暂无数据'}
            `
          }
        },
        geo: {
          map: 'world',
          roam: true,
          zoom: 1.2,
          itemStyle: {
            areaColor: '#f3eee6',
            borderColor: '#d8c7b5'
          },
          emphasis: {
            itemStyle: {
              areaColor: '#ead8c4'
            }
          }
        },
        series: [
          {
            itemStyle: {
              color: '#8b2f1f'
            },
            label: {
              show: true,
              formatter: '{b}',
              position: 'right'
            },
            name: '博物馆',
            type: 'scatter',
            coordinateSystem: 'geo',
            data: museumData,
            symbolSize (val) {
              return Math.sqrt(val[2]) * 2
            }
          }
        ]
      })

      chart.on('click', (params) => {
        if (params.componentType === 'series') {
          this.selectedMuseum = params.data
          this.dialogVisible = true
        }
      })
    },

    drawTypePie (typeData) {
      const chart = echarts.init(this.$refs.typePieRef)

      chart.setOption({
        title: {
          text: '文物类型占比',
          left: 'center'
        },
        tooltip: {
          trigger: 'item'
        },
        legend: {
          orient: 'vertical',
          right: 20,
          top: 'center'
        },
        series: [
          {
            name: '文物类型',
            type: 'pie',
            radius: ['40%', '70%'],
            center: ['38%', '55%'],
            data: typeData,
            label: {
              formatter: '{b}: {d}%'
            }
          }
        ]
      })
    }
  }
}
</script>

<style scoped>
.chart-section {
  margin-top: 28px;
}

.chart-card {
  background: #fffdf9;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 6px 18px rgba(80, 50, 20, 0.08);
}

.chart-card h3 {
  margin: 0 0 16px 0;
  color: #3b2418;
}

.pie-chart {
  width: 100%;
  height: 420px;
}
.map-page {
  padding: 30px 50px;
  background: #f8f3ea;
  min-height: 100vh;
}

.map-page h2 {
  font-size: 30px;
  color: #3b2418;
}

.map-page p {
  color: #7a6a58;
}

.map-chart {
  width: 100%;
  height: 520px;
  background: #fdfaf5;
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(80, 50, 20, 0.08);
}

.stat-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  margin-top: 28px;
}

.stat-card {
  background: #fffdf9;
  border-top: 4px solid #8b2f1f;
  padding: 24px;
  box-shadow: 0 6px 18px rgba(80, 50, 20, 0.08);
}

.stat-title {
  color: #6f5b4a;
  font-size: 15px;
}

.stat-num {
  margin-top: 10px;
  font-size: 34px;
  font-weight: bold;
  color: #1f130c;
}

.stat-desc {
  margin-top: 10px;
  color: #8a7a6a;
  font-size: 13px;
}

.map-page {
  padding: 30px;
}

.map-page h2 {
  margin-bottom: 8px;
}

.map-page p {
  color: #666;
  margin-bottom: 20px;
}

.map-chart {
  width: 100%;
  height: 650px;
  background: #f8fafc;
  border-radius: 12px;
}
</style>