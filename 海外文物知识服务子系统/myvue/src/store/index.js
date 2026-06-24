import { createStore } from 'vuex'

const store = createStore({
  state: {
    user: null,
    token: localStorage.getItem('token') || '',
    favorites: []
  },
  mutations: {
    SET_USER(state, user) {
      state.user = user
    },
    SET_TOKEN(state, token) {
      state.token = token
      localStorage.setItem('token', token)
    },
    ADD_FAVORITE(state, item) {
      if (!state.favorites.find(f => f.id === item.id)) {
        state.favorites.push(item)
      }
    },
    REMOVE_FAVORITE(state, id) {
      state.favorites = state.favorites.filter(f => f.id !== id)
    }
  },
  actions: {
    setUser({ commit }, user) {
      commit('SET_USER', user)
    },
    setToken({ commit }, token) {
      commit('SET_TOKEN', token)
    },
    addFavorite({ commit }, item) {
      commit('ADD_FAVORITE', item)
    },
    removeFavorite({ commit }, id) {
      commit('REMOVE_FAVORITE', id)
    }
  },
  getters: {
    getUser: state => state.user,
    getToken: state => state.token,
    getFavorites: state => state.favorites
  }
})

export default store
