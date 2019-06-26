const fs = require('fs')
const marked = require('meta-marked')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const path = require('path')
const srcPath = path.join(process.cwd(), 'src') + path.sep
const outputPath = path.join(process.cwd(), 'build')

const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const ModernizrWebpackPlugin = require('modernizr-webpack-plugin');
const entries = widgetWebpack.getDefaultEntries()
const copy = widgetWebpack.getDefaultCopyList()

//pass in extra files for webpack to copy
const newCopy = copy.concat([
	{
		from: path.join(__dirname, 'node_modules', 'hammerjs', 'hammer.min.js'),
		to: path.join(outputPath, 'assets', 'js', 'hammer.js'),
	},
	{
		from: path.join(__dirname, 'node_modules', 'konami', 'konami.js'),
		to: path.join(outputPath, 'assets', 'js', 'konami.js'),
	},
	{
		from: path.join(__dirname, 'src', '_helper-docs', 'assets'),
		to: path.join(outputPath, 'guides', 'assets'),
		toType: 'dir'
	}
])

entries['assets/js/atari.js'] = [srcPath+'atari.coffee']
entries['assets/css/atari.css'] = [srcPath+'atari.scss']
entries['assets/css/IE.css'] = [srcPath+'IE.scss']
entries['guides/guideStyles.css'] = [srcPath+'_helper-docs/guideStyles.scss']
// options for the build
let options = {
	entries: entries,
	copyList: newCopy,
}

const generateHelperPlugin = name => {
	const file = fs.readFileSync(path.join(__dirname, 'src', '_helper-docs', name+'.md'), 'utf8')
	const content = marked(file)

	return new HtmlWebpackPlugin({
		template: path.join(__dirname, 'src', '_helper-docs', 'helperTemplate'),
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
