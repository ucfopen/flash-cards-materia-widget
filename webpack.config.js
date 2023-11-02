const fs = require('fs')
const path = require('path')
const outputPath = path.join(process.cwd(), 'build')
const srcPath = path.join(__dirname, 'src') + path.sep

const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const copy = widgetWebpack.getDefaultCopyList()

//pass in extra files for webpack to copy
const customCopy = copy.concat([
	{
		from: path.join(__dirname, 'node_modules', 'hammerjs', 'hammer.min.js'),
		to: outputPath,
	},
	{
		from: path.join(__dirname, 'node_modules', 'konami', 'konami.js'),
		to: path.join(outputPath, 'assets', 'js', 'konami.js'),
	},
	{
		from: path.join(__dirname, 'src', '_guides', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	},
])

const entries = {
	'creator': [
		path.join(srcPath, 'creator.html'),
		path.join(srcPath, 'creator.coffee'),
		path.join(srcPath, 'creator.scss'),
	],
	'player': [
		path.join(srcPath, 'player.html'),
		path.join(srcPath, 'player.coffee'),
		path.join(srcPath, 'atari.coffee'),
		path.join(srcPath, 'player.scss'),
		path.join(srcPath, 'atari.scss')
	]
}

// options for the build
let options = {
	entries: entries,
	copyList: customCopy,
}

let buildConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

module.exports = buildConfig
