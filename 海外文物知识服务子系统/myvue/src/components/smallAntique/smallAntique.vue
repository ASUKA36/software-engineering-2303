<template>
  <div class="antique-item" @click="goToDetail">
    <div class="antique-image">
      <img :src="getImageUrl(pic)" :alt="title" />
      <div v-if="showRemove" class="remove-btn" @click.stop="handleRemove">
        <i class="el-icon-delete"></i>
      </div>
    </div>
    <div class="antique-info">
      <div style="font-size: 16px;font-weight: 500;height:30px;overflow: hidden;text-overflow: ellipsis;">
        {{ title }}
      </div>
      <div style="font-size: 12px;height: 50px;overflow: hidden;text-overflow: ellipsis;">
        {{ info }}
      </div>
      <div v-if="time" class="antique-time">{{ time }}</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'smallAntique',
  props: {
    title: {
      default: '',
      type: String
    },
    pic: {
      default: '',
      type: String
    },
    info: {
      default: '',
      type: String
    },
    time: {
      default: '',
      type: String
    },
    museumId: {
      default: '',
      type: [String, Number]
    },
    objectId: {
      default: '',
      type: [String, Number]
    },
    showRemove: {
      default: false,
      type: Boolean
    }
  },
  data () {
    return {
      serverApiBase: 'http://47.96.152.190:8000'
    }
  },
  methods: {
    getImageUrl (imageUrl) {
      const museumIdNum = parseInt(this.museumId)
      
      // 仅博物馆2、3调用服务器API
      if (museumIdNum === 2 || museumIdNum === 3) {
        const objId = this.objectId
        if (objId && objId !== 'null' && objId !== 'undefined') {
          return `${this.serverApiBase}/api/img/${museumIdNum}/${objId}`
        }
        return '/src/assets/timg.jpeg'
      }
      
      // 其他博物馆（如博物馆1）使用原有逻辑
      if (!imageUrl || imageUrl === 'null' || imageUrl === 'undefined') {
        return '/src/assets/timg.jpeg'
      }
      if (imageUrl.includes('harvard.edu')) {
        const encodedUrl = encodeURIComponent(imageUrl)
        return `http://localhost:8085/api/image/proxy?url=${encodedUrl}`
      }
      return imageUrl
    },
    goToDetail () {
      if (this.museumId && this.objectId) {
        this.$router.push({
          path: '/antiqueDetail',
          query: { museum_id: this.museumId, object_id: this.objectId }
        })
      }
    },
    handleRemove () {
      this.$emit('remove', {
        museumId: this.museumId,
        objectId: this.objectId
      })
    }
  }
}
</script>

<style scoped>
.antique-item {
  display: flex;
  align-items: center;
  padding: 16px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
}

.antique-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
}

.antique-image {
  width: 100px;
  height: 100px;
  flex-shrink: 0;
  position: relative;
}

.antique-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 6px;
}

.remove-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 24px;
  height: 24px;
  background: #f56c6c;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.remove-btn:hover {
  background: #f78989;
  transform: scale(1.1);
}

.antique-info {
  flex: 1;
  margin-left: 16px;
  overflow: hidden;
}

.antique-time {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

.product:hover{
  cursor: pointer;
  transform: scale(1.05);
  border-top: 1px solid red!important;
}
</style>