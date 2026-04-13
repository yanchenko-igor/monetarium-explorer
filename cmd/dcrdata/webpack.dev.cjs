const { merge } = require('webpack-merge')
const common = require('./webpack.common.cjs')
const ESLintPlugin = require('eslint-webpack-plugin')

module.exports = merge(common, {
  mode: 'development',
  devtool: 'inline-source-map',
  plugins: [
    new ESLintPlugin({
      formatter: 'stylish',
      // Lint errors are warnings in dev so the build keeps running.
      failOnError: false,
      emitWarning: true
    })
  ]
})
