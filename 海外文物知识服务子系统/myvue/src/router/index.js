import { createRouter, createWebHashHistory } from 'vue-router'
import MuseumMap from '../views/visualization/MuseumMap.vue'
const routes = [
  {
    path: '/',
    redirect: '/index',
    name: 'Index',
    meta: {
      title: '首页'
    }
  },
  {
    path: '/antiqueDetail',
    name: 'antiqueDetail',
    component: () => import('../views/antiqueDetail/antiqueDetail.vue')
  },
  {
  path: '/museum-map',
  component: MuseumMap
},
  {
    path: '/index',
    name: 'IndexView',
    component: () => import('../views/common/IndexView.vue')
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/login/LoginView.vue')
  },
  {
    path: '/classify',
    name: 'classify',
    component: () => import('../views/fore/classify.vue')
  },

  {
    path: '/result',
    name: 'result',
    component: () => import('../views/fore/result.vue')
  },
  {
    path: '/classify_muse',
    name: 'classify_muse',
    component: () => import('../views/fore/classify_muse.vue')
  },
  {
    path: '/classify_dynasty',
    name: 'classify_dynasty',
    component: () => import('../views/fore/classify_dynasty.vue')
  },
  {
    path: '/classify_mart',
    name: 'classify_mart',
    component: () => import('../views/fore/classify_mart.vue')
  },
  {
    path: '/classify_usea',
    name: 'classify_usea',
    component: () => import('../views/fore/classify_usea.vue')
  },
  {
    path: '/antiqueList',
    name: 'antiqueList',
    component: () => import('../views/fore/AntiqueListDemo.vue')
  },
  {
    path: '/antiqueCompare',
    name: 'antiqueCompare',
    component: () => import('../views/fore/AntiqueCompare.vue')
  },
  {
    path: '/dataQuery',
    name: 'dataQuery',
    component: () => import('../views/fore/DataQueryView.vue')
  },

  {
    path: '/register',
    name: 'register',
    component: () => import('../views/login/register.vue')
  },
  {
    path: '/knowledge-graph',
    name: 'KnowledgeGraph',
    component: () => import('../views/knowledge/KnowledgeGraph.vue'),
    meta: {
      title: '知识图谱'
    }
  },
  {
    path: '/timeline',
    name: 'TimelineView',
    component: () => import('../views/timeline/TimelineView.vue'),
    meta: {
      title: '文物时间轴'
    }
  },
  {
    path: '/statistics',
    name: 'StatisticsView',
    component: () => import('../views/statistics/StatisticsView.vue'),
    meta: {
      title: '统计分析看板'
    }
  },
  {
    path: '/personpage',
    name: 'personpage',
    component: () => import('../views/personpage/personpage.vue'),
    children: [
      {
        path: '',
        name: 'personpageHello',
        component: () => import('../views/personpage/personpage_hello.vue')
      },
      {
        path: 'myComment',
        name: 'myComment',
        component: () => import('../views/personpage/myComment.vue')
      },
      {
        path: 'changeinfo',
        name: 'changeinfo',
        component: () => import('../views/personpage/changeinfo.vue')
      },
      {
        path: 'favourite',
        name: 'favourite',
        component: () => import('../views/personpage/favourite.vue')
      },
      {
        path: 'browse_history',
        name: 'browse_history',
        component: () => import('../views/personpage/browse_history.vue')
      },
      {
        path: 'info',
        name: 'info',
        component: () => import('../views/personpage/info.vue')
      },
      {
        path: 'comment',
        name: 'comment',
        component: () => import('../components/comment/comment.vue')
      }
    ]
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  scrollBehavior: () => ({ top: 0 }),
  routes
})

export default router
