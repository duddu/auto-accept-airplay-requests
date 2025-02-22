import { webpackBundler } from '@vuepress/bundler-webpack'
import { markdownHintPlugin } from '@vuepress/plugin-markdown-hint'
import { markdownIncludePlugin } from '@vuepress/plugin-markdown-include'
import { defaultTheme } from '@vuepress/theme-default'
import { defineUserConfig } from '@vuepress/cli'

import meta from './meta'

export default defineUserConfig({
  lang: 'en-US',
  title: meta.AAR_BUNDLE_DISPLAY_NAME,
  theme: defaultTheme({
    hostname: meta.AAR_DOCS_URL,
    repo: `https://${meta.AAR_REPO_URL}`,
    logo: '/images/logo.png',
    logoAlt: meta.AAR_BUNDLE_NAME,
    editLink: false,
    navbar: [
      {
        text: `Download`,
        link: `https://${meta.AAR_REPO_URL}/releases/tag/v${meta.AAR_VERSION}`
      },
    ],
    themePlugins: {
      mediumZoom: false,
    },
  }),
  head: [
    ['link', { rel: 'apple-touch-icon', sizes: '57x57', href: '/images/icons/apple-icon-57x57.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '60x60', href: '/images/icons/apple-icon-60x60.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '72x72', href: '/images/icons/apple-icon-72x72.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '76x76', href: '/images/icons/apple-icon-76x76.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '114x114', href: '/images/icons/apple-icon-114x114.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '120x120', href: '/images/icons/apple-icon-120x120.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '144x144', href: '/images/icons/apple-icon-144x144.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '152x152', href: '/images/icons/apple-icon-152x152.png' }],
    ['link', { rel: 'apple-touch-icon', sizes: '180x180', href: '/images/icons/apple-icon-180x180.png' }],
    ['link', { rel: 'canonical', href: `https://${meta.AAR_DOCS_URL}` }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/images/icons/favicon-16x16.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/images/icons/favicon-32x32.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '96x96', href: '/images/icons/favicon-96x96.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '144x144', href: '/images/icons/android-icon-144x144.png' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '192x192' , href: '/images/icons/android-icon-192x192.png' }],
    ['link', { rel: 'manifest', href: '/manifest.webmanifest' }],
    ['meta', { name: 'apple-mobile-web-app-title', content: meta.AAR_BUNDLE_NAME }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
    ['meta', { name: 'application-name', content: meta.AAR_BUNDLE_NAME }],
    ['meta', { name: 'msapplication-TileColor', content: '#8b65c2' }],
    ['meta', { name: 'msapplication-TileImage', content: '/images/icons/ms-icon-144x144.png' }],
    ['meta', { name: 'theme-color', content: '#8b65c2' }],
  ],
  plugins: [
    markdownHintPlugin({ alert: true }),
    markdownIncludePlugin({ useComment: false }),
  ],
  extendsMarkdown: (md) => {
    const _render = md.render
    md.render = (src, ...args) => {
      Object.entries(meta).forEach(([ key, value ]) => {
        src = src.replace(new RegExp(`__${key}__`, 'g'), value)
      })
      return _render.apply(md, [ src, ...args ])
    }
  },
  bundler: webpackBundler(),
})
