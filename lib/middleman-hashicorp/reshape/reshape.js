const reshape = require('reshape')
const preactPreset = require('babel-preset-preact')
const registerComponents = require('reshape-preact-components')

require('babel-register')({ presets: [preactPreset] })

const components = registerComponents(require(`${process.argv[2]}`))

const data = []
process.stdin.on('data', d => data.push(String(d)))
process.stdin.on('end', () => {
  reshape({ plugins: [components] })
    .process(data.join(''))
    .then(res => {
      console.log('-------- OUTPUT --------')
      console.log(Buffer.from(res.output()).toString('base64'))
      console.log('------------------------')
    })
})
