import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import axios from 'axios'

const app = createApp(App)
app.use(router)
app.use(store)
app.use(ElementPlus)
app.config.globalProperties.$axios = axios
app.mount('#app')
