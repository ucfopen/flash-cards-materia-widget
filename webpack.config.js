const path = require('path')
const ExtractTextPlugin = require('extract-text-webpack-plugin')

let srcPath = path.join(process.cwd(), 'src')
let outputPath = path.join(process.cwd(), 'build')

// load default copyList to which we'll append new items to copy
let defaultCopy = require('materia-widget-development-kit/webpack-widget').getDefaultCopyList()

// load the reusable legacy webpack config from materia-widget-dev
let webpackConfig = require('materia-widget-development-kit/webpack-widget').getLegacyWidgetBuildConfig({
	//pass in extra files for webpack to copy
	copyList: [
		...defaultCopy,
		{
			from: `${srcPath}/hammer.min.js`,
			to: outputPath,
		},
		{
			from: `${srcPath}/yepnope.min.js`,
			to: outputPath,
		},
		{
			from: `${srcPath}/konami.js`,
			to: outputPath,
		}
	]
})

webpackConfig.entry['assets/js/atari.js'] = [path.join(__dirname, 'src', 'assets/js/atari.coffee')]
webpackConfig.entry['assets/css/atari.css'] = [path.join(__dirname, 'src', 'assets/css/atari.less')]
webpackConfig.entry['assets/css/IE.css'] = [path.join(__dirname, 'src', 'assets/css/IE.less')]

webpackConfig.entry['player.css'] = [
	path.join(__dirname, 'src', 'player.html'),
	path.join(__dirname, 'src', 'player.less')
]

webpackConfig.module.rules.push({
	test: /\.less$/i,
	exclude: /node_modules/,
	loader: ExtractTextPlugin.extract({
		use: [
			'raw-loader',
			{
				// postcss-loader is needed to run autoprefixer
				loader: 'postcss-loader',
				options: {
					// add autoprefixer, tell it what to prefix
					plugins: [require('autoprefixer')({browsers: [
						'Explorer >= 11',
						'last 3 Chrome versions',
						'last 3 ChromeAndroid versions',
						'last 3 Android versions',
						'last 3 Firefox versions',
						'last 3 FirefoxAndroid versions',
						'last 3 iOS versions',
						'last 3 Safari versions',
						'last 3 Edge versions'
					]})]
				}
			},
			'less-loader'
		]
	})
})

module.exports = webpackConfig
