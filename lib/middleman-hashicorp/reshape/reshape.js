const reshape = require('reshape')
const preactPreset = require('babel-preset-preact')

require('babel-register')({ presets: [preactPreset] })

const components = require(`${process.cwd()}/assets/reshape`)

const data = []
process.stdin.on('data', d => data.push(String(d)))
process.stdin.on('end', () => {
  reshape({
    plugins: [components]
  })
    .process(data.join(''))
    .then(res => {
      console.log('-------- OUTPUT --------')
      console.log(Buffer.from(res.output()).toString('base64'))
      console.log('------------------------')
    })
})
