<template>
  <div>
    <MainHeader></MainHeader>
    <div class="main-explore">
      <div class="page-header">
        <h1 class="page-title">分类浏览</h1>
      </div>

      <div class="classify-grid">
        <div 
          v-for="(item, index) in classifyList" 
          :key="index" 
          class="classify-card"
          @click="handleClick(item.key)"
        >
          <div class="card-bg" :style="{ backgroundImage: 'url(' + item.bgUrl + ')' }"></div>
          <div class="card-content">
            <h3 class="card-title">{{ item.title }}</h3>
            <p class="card-desc">{{ item.desc }}</p>
          </div>
          <div class="card-overlay"></div>
        </div>
      </div>
    </div>
    <MainFooter></MainFooter>
  </div>
</template>

<script>
import MainHeader from '../../components/MainHeader/MainHeader'
import MainFooter from '../../components/MainFooter/MainFooter'

export default {
  components: {
    MainHeader,
    MainFooter
  },
  data () {
    return {
      classifyList: [
        {
          key: 'dynasty',
          title: '朝代',
          desc: '按历史朝代探索文物',
          bgUrl: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.8cF-Es_gVFYtmMwzaHoKIwHaFt?pid=ImgDet&rs=1'
        },
        {
          key: 'material',
          title: '材质',
          desc: '按文物材质分类浏览',
          bgUrl: 'https://tse1-mm.cn.bing.net/th/id/R-C.03057cce39380cf934605e8d4bfb65ef?rik=BP3kzTvHjqD6ZA&riu=http%3a%2f%2fimg01.baimao.com%2fM00%2f54%2f88%2fwKgAFFuHOgGAD6ofAAC8a81zVbQ551.jpg&ehk=%2bCiN%2brqmeEMrr2CGAsO9thQUEsDB3Y0izk7piXsNLTw%3d&risl=&pid=ImgRaw&r=0'
        },
        {
          key: 'museum',
          title: '博物馆',
          desc: '按收藏博物馆查找文物',
          bgUrl: 'https://tse1-mm.cn.bing.net/th/id/R-C.eeefca935019f71260e6a9fcb1df0f63?rik=MoqnjhKYBCvfgg&riu=http%3a%2f%2fimg.pconline.com.cn%2fimages%2fupload%2fupc%2ftx%2fphotoblog%2f1309%2f20%2fc87%2f25937376_25937376_1136074994421_mthumb.jpg&ehk=8vdy1RIbqowuPXHaMdMI283TboT8kZ1A3vQRlVMH14E%3d&risl=&pid=ImgRaw&r=0'
        },
        {
          key: 'usage',
          title: '类型',
          desc: '按文物用途类型浏览',
          bgUrl: 'https://tse4-mm.cn.bing.net/th/id/OIP-C.5YOZG6psKqpAA89M7o3oaAHaGY?pid=ImgDet&rs=1'
        }
      ]
    }
  },
  methods: {
    handleClick (key) {
      if (key === 'dynasty') {
        this.$router.push('/classify_dynasty')
      } else if (key === 'material') {
        this.$router.push('/classify_mart')
      } else if (key === 'museum') {
        this.$router.push('/classify_muse')
      } else if (key === 'usage') {
        this.$router.push('/classify_usea')
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.main-explore {
  min-height: 80vh;
  padding: 60px 5%;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.page-header {
  text-align: center;
  margin-bottom: 60px;
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

.classify-grid {
  display: flex;
  gap: 25px;
  max-width: 1400px;
  margin: 0 auto;
}

.classify-card {
  position: relative;
  flex: 1;
  height: 320px;
  min-width: 250px;
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  
  &:hover {
    transform: translateY(-10px) scale(1.02);
    box-shadow: 0 15px 40px rgba(0, 0, 0, 0.2);
  }
}

.card-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-size: cover;
  background-position: center;
  transition: transform 0.6s ease;
}

.classify-card:hover .card-bg {
  transform: scale(1.1);
}

.card-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, rgba(26, 26, 46, 0.7) 0%, rgba(22, 33, 62, 0.8) 100%);
}

.card-content {
  position: relative;
  z-index: 2;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 30px;
  text-align: center;
}

.card-icon {
  font-size: 56px;
  margin-bottom: 20px;
  filter: drop-shadow(0 4px 10px rgba(0, 0, 0, 0.3));
}

.card-title {
  font-family: 'Ma Shan Zheng', 'STKaiti', 'KaiTi', 'ZCOOL XiaoWei', 'Noto Serif SC', serif;
  font-size: 32px;
  font-weight: 400;
  color: #fff;
  margin: 0 0 10px 0;
  letter-spacing: 6px;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

.card-desc {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  letter-spacing: 2px;
}
</style>
