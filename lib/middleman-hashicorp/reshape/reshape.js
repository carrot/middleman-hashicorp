const reshape = require('reshape')
const registerComponents = require('reshape-preact-components')
const preactPreset = require('babel-preset-preact')

require('babel-register')({ presets: [preactPreset] })
const footer = require('@hashicorp-tmp/hashi-footer')
const nav = require('@hashicorp-tmp/hashi-nav')
const hero = require('@hashicorp-tmp/hashi-hero')
const callouts = require('@hashicorp-tmp/hashi-callouts')
const packages = require('@hashicorp-tmp/hashi-packages')
const logoGrid = require('@hashicorp-tmp/hashi-logo-grid')
const sectionHeader = require('@hashicorp-tmp/hashi-section-header')
const textAndImage = require('@hashicorp-tmp/hashi-text-and-image')
const basicList = require('@hashicorp-tmp/hashi-basic-list')
const personList = require('@hashicorp-tmp/hashi-person-list')
const twoColumnText = require('@hashicorp-tmp/hashi-two-column-text')
const emailSubscribe = require('@hashicorp-tmp/hashi-email-subscribe')
const secondaryNav = require('@hashicorp-tmp/hashi-secondary-nav')
const salesForm = require('@hashicorp-tmp/hashi-sales-form')
const socialShareLinks = require('@hashicorp-tmp/hashi-social-share-links')
const image = require('@hashicorp-tmp/hashi-image')

const data = []
process.stdin.on('data', d => data.push(String(d)))
process.stdin.on('end', () => {
  reshape({
    plugins: [
      // TODO: refactor to allow project to register these components
      registerComponents({
        'hashi-footer': footer,
        'hashi-nav': nav,
        'hashi-basic-list': basicList,
        'hashi-hero': hero,
        'hashi-callouts': callouts,
        'hashi-packages': packages,
        'hashi-logo-grid': logoGrid,
        'hashi-section-header': sectionHeader,
        'hashi-text-and-image': textAndImage,
        'hashi-person-list': personList,
        'hashi-two-column-text': twoColumnText,
        'hashi-email-subscribe': emailSubscribe,
        'hashi-secondary-nav': secondaryNav,
        'hashi-sales-form': salesForm,
        'hashi-social-share-links': socialShareLinks,
        'hashi-image': image
      })
    ]
  })
    .process(data.join(''))
    .then(res => {
      console.log('-------- OUTPUT --------')
      console.log(Buffer.from(res.output()).toString('base64'))
      console.log('------------------------')
    })
})
