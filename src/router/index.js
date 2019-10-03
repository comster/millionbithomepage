import Vue from 'vue'
import Router from 'vue-router'
import Classic from '@/components/Classic'
import Homepage from '@/components/Homepage'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'homepage',
      component: Homepage
    },
    {
      path: '/classic',
      name: 'classic',
      component: Classic
    },
  ]
})
