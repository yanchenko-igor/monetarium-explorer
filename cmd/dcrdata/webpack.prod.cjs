const { merge } = require('webpack-merge')
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin')
const ESLintPlugin = require('eslint-webpack-plugin')
const common = require('./webpack.common.cjs')

module.exports = merge(common, {
  mode: 'production',
  devtool: 'source-map',
  plugins: [
    new ESLintPlugin({
      formatter: 'stylish',
      threads: true
    })
  ],
  optimization: {
    usedExports: true,
    minimize: true,
    minimizer: [
      '...', // extend webpack 5's default TerserPlugin
      new CssMinimizerPlugin()
    ]
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [
          /node_modules/,
          /\.test\.js$/ // test files are not part of the production bundle
        ],
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              // Tuple form is required: [preset, options]
              [
                '@babel/preset-env',
                {
                  exclude: ['@babel/plugin-transform-regenerator']
                }
              ]
            ]
          }
        }
      }
    ]
  }
})
