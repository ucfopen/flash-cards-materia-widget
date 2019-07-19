const fs = require('fs')
const marked = require('meta-marked')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const path = require('path')
const outputPath = path.join(process.cwd(), 'build')

const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const ModernizrWebpackPlugin = require('modernizr-webpack-plugin');
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
	'creator.js': [
		path.join(__dirname, 'src', 'creator.coffee')
	],
	'player.js': [
		path.join(__dirname, 'src', 'player.coffee')
	],
	'creator.css': [
		path.join(__dirname, 'src', 'creator.html'),
		path.join(__dirname, 'src', 'creator.scss')
	],
	'player.css': [
		path.join(__dirname, 'src', 'player.html'),
		path.join(__dirname, 'src', 'player.scss')
	],
	'assets/js/atari.js': [
		path.join(__dirname, 'src', 'atari.coffee')
	],
	'assets/css/atari.css': [
		path.join(__dirname, 'src', 'atari.scss')
	],
	'assets/css/IE.css': [
		path.join(__dirname, 'src', 'IE.scss')
	],
	'guides/guideStyles.css': [
		path.join(__dirname, 'src', '_guides', 'guideStyles.scss')
	],
	'guides/player.temp.html': [
		path.join(__dirname, 'src', '_guides', 'player.md')
	],
	'guides/creator.temp.html': [
		path.join(__dirname, 'src', '_guides', 'creator.md')
	]
}

// options for the build
let options = {
	entries: entries,
	copyList: customCopy,
}

const generateHelperPlugin = name => {
	const file = fs.readFileSync(path.join(__dirname, 'src', '_guides', name+'.md'), 'utf8')
	const content = marked(file)

	return new HtmlWebpackPlugin({
		template: path.join(__dirname, 'src', '_guides', 'helperTemplate'),
		filename: path.join(outputPath, 'guides', name+'.html'),
		title: name.charAt(0).toUpperCase() + name.slice(1),
		chunks: ['guides'],
		content: content.html
	})
}

let webpackConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

const modernizrConfig = {
	noChunk: true,
	filename: 'assets/js/modernizr.js',
	'options':[
		'domPrefixes',
		'prefixes',
		"testAllProps",
		"testProp",
		"testStyles",
		"html5shiv",
		"load"
	],
	'feature-detects': [
		"touchevents",
		"svg/inline",
		"svg",
		"svg/clippaths",
		'css/animations',
		'css/transforms',
		'css/transforms3d',
		'css/transitions',
		'css/generatedcontent',
		'css/opacity',
		'css/rgba'
	],
	minify: {
		output: {
			comments: true,
			beautify: false
		}
	}
}
webpackConfig.plugins.unshift(generateHelperPlugin('creator'))
webpackConfig.plugins.unshift(generateHelperPlugin('player'))
webpackConfig.plugins.push(new ModernizrWebpackPlugin(modernizrConfig))

module.exports = webpackConfig
