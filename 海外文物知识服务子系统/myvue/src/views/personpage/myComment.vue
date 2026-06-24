<template>
  <div class="my-comment-container">
    <h2>我的评论</h2>
    <br>
    <div v-if="loading" class="loading">加载中...</div>
    <div v-else-if="comments.length === 0" class="empty">暂无评论</div>
    <div v-else class="comment-list">
      <div v-for="comment in comments" :key="comment.commentId" class="comment-item">
        <div class="comment-header">
          <span class="object-name">{{ comment.objectName || '未知文物' }}</span>
          <span class="comment-time">{{ formatTime(comment.createdAt) }}</span>
          <span class="audit-status" :class="'status-' + comment.auditStatus">
            {{ getAuditStatusText(comment.auditStatus) }}
          </span>
        </div>
        <div class="comment-content">{{ comment.content }}</div>
        <div class="comment-footer">
          <el-button
            size="small"
            type="danger"
            @click="handleDelete(comment)"
          >
            删除
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';
var storage = window.localStorage;

export default {
  data() {
    return {
      comments: [],
      loading: false
    };
  },
  methods: {
    /**
     * 初始化页面，获取评论列表
     */
    pageInit() {
      this.loading = true;
      let userId = storage.getItem('user_id');
      if (!userId) {
        userId = storage.getItem('username');
      }
      
      axios.post('http://localhost:8085/user_admin/comment', {
        userId: userId
      }).then((response) => {
        if (response.data.state === 200) {
          this.comments = response.data.data || [];
        }
        this.loading = false;
      }).catch((error) => {
        console.error('获取评论失败:', error);
        this.loading = false;
      });
    },

    /**
     * 删除评论
     */
    handleDelete(comment) {
      this.$confirm('确定要删除这条评论吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        axios.post('http://localhost:8085/user_admin/deleteComment', {
          commentId: comment.commentId
        }).then((response) => {
          if (response.data.state === 200) {
            this.$message.success('删除成功');
            this.pageInit(); // 重新加载列表
          } else {
            this.$message.error(response.data.message || '删除失败');
          }
        }).catch((error) => {
          console.error('删除评论失败:', error);
          this.$message.error('删除失败');
        });
      }).catch(() => {});
    },

    /**
     * 格式化时间
     */
    formatTime(time) {
      if (!time) return '';
      const date = new Date(time);
      return date.toLocaleString('zh-CN');
    },

    /**
     * 获取审核状态文本
     */
    getAuditStatusText(status) {
      const statusMap = {
        0: '待审核',
        1: '已通过',
        2: '已拒绝',
        3: '复审中'
      };
      return statusMap[status] || '未知';
    }
  },
  created() {
    this.pageInit();
  }
};
</script>

<style scoped>
.my-comment-container {
  padding: 20px;
}

.loading, .empty {
  text-align: center;
  padding: 40px;
  color: #999;
}

.comment-list {
  max-width: 800px;
}

.comment-item {
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  background: #fff;
}

.comment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.object-name {
  font-weight: bold;
  color: #333;
}

.comment-time {
  font-size: 12px;
  color: #999;
}

.audit-status {
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.status-0 {
  background: #fff3cd;
  color: #856404;
}

.status-1 {
  background: #d4edda;
  color: #155724;
}

.status-2 {
  background: #f8d7da;
  color: #721c24;
}

.status-3 {
  background: #cce5ff;
  color: #004085;
}

.comment-content {
  line-height: 1.6;
  color: #666;
  margin-bottom: 12px;
}

.comment-footer {
  text-align: right;
}
</style>
