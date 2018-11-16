const path = require('path')
const srcPath = path.join(process.cwd(), 'src') + path.sep
const outputPath = path.join(process.cwd(), 'build')
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')
const ModernizrWebpackPlugin = require('modernizr-webpack-plugin');
const entries = widgetWebpack.getDefaultEntries()
const copy = widgetWebpack.getDefaultCopyList()

//pass in extra files for webpack to copy
const newCopy = [
	...copy,
	{
		from: path.join(__dirname, 'node_modules', 'hammerjs', 'hammer.min.js'),
		to: path.join(outputPath, 'assets', 'js', 'hammer.js'),
	},
	{
		from: path.join(__dirname, 'node_modules', 'konami', 'konami.js'),
		to: path.join(outputPath, 'assets', 'js', 'konami.js'),
	},
	{
		from: path.join(__dirname, 'node_modules', 'timbre', 'timbre.dev.js'),
		to: path.join(outputPath, 'assets', 'js', 'timbre.js'),
	}
]

entries['assets/js/atari.js'] = [srcPath+'atari.coffee']
entries['assets/css/atari.css'] = [srcPath+'atari.scss']
entries['assets/css/IE.css'] = [srcPath+'IE.scss']
// options for the build
let options = {
	entries: entries,
	copyList: newCopy,
}

const webpackConfig = widgetWebpack.getLegacyWidgetBuildConfig(options)

const modernizrConfig = {
	noChunk: true,
	filename: 'assets/js/modernizr.js',
	'options':[
		'domprefixes',
		'prefixes',
		"testAllProps",
		"testProp",
		"testStyles",
		"teststyles",
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

webpackConfig.plugins.push(new ModernizrWebpackPlugin(modernizrConfig))

module.exports = webpackConfig