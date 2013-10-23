###

Materia
It's a thing

Widget  : Flashcards, Creator
Authors : Brandon Stull, Micheal Parks
Updated : 10/13

###

# Create an angular module to import the animation module and house our controller.
FlashcardsCreator = angular.module 'FlashcardsCreator', ['ngAnimate']

# Set the controller for the scope of the document body.
FlashcardsCreator.controller 'FlashcardsCreatorCtrl', ['$scope', ($scope) ->
	$scope.title = ""
	$scope.cards = []

	_imgRef = []

	$scope.addCard = (front="", back="", URLs=["", ""]) -> 
		$scope.cards.push { front:front, back:back, URLs:URLs }
	$scope.removeCard = (index) -> 
		$scope.cards.splice(index, 1)
	$scope.requestImage = (index, face) -> 
		Materia.CreatorCore.showMediaImporter()
		_imgRef[0] = index
		_imgRef[1] = face
	$scope.setURL = (URL) ->
		$scope.cards[_imgRef[0]].URLs[_imgRef[1]] = URL
	$scope.deleteImage = (index, face) ->
		$scope.cards[index].URLs[face] = ""
]

Namespace('Flashcards').Creator = do ->
	_title = _qset = _scope = null

	initNewWidget = (widget, baseUrl) ->
		_scope = angular.element($('body')).scope()
		_scope.$apply -> _scope.addCard()

		if not Modernizr.input.placeholder then _polyfill()

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_items = qset.items[0].items
		_scope = angular.element($('body')).scope()
		_scope.$apply -> _scope.title = title
		onQuestionImportComplete _items

		if not Modernizr.input.placeholder then _polyfill()

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData() then Materia.CreatorCore.save _title, _qset

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (items) ->
		_scope.$apply ->
			for i in [0..items.length-1]
				_scope.addCard(items[i].questions[0].text, items[i].answers[0].text)
				if items[i].assets[0] != '-1' then _scope.cards[i].URLs[0] = items[i].assets[0]
				if items[i].assets[1] != '-1' then _scope.cards[i].URLs[1] = items[i].assets[1]

	onMediaImportComplete = (media) ->
		URL = Materia.CreatorCore.getMediaUrl(media[0].id)
		_scope.$apply -> _scope.setURL(URL)

	_buildSaveData = ->
		_title = _escapeHTML _scope.title
		_cards = _scope.cards

		# Decide if it is ok to save.
		if _title is ''
			Materia.CreatorCore.cancelSave 'Please enter a title.'
			return false
		else
			for i in [0.._cards.length-1]
				if _cards[i].front.length > 50 && _cards[i].URLs[0] != ''
					Materia.CreatorCore.cancelSave 'Please reduce the text of the front of card #'+(i+1)+' to fit the card.'
					return false
				if _cards[i].back.length > 50 && _cards[i].URLs[1] != ''
					Materia.CreatorCore.cancelSave 'Please reduce the text of the back of card #'+(i+1)+' to fit the card.'
					return false

		if !_qset? then _qset = {}
		_qset.options = {}
		_qset.assets  = []
		_qset.rand    = false
		_qset.name    = ''

		_items      = []
		_items.push( _process _cards[i] ) for i in [0.._cards.length-1]
		_qset.items = [{ items: _items }]

		true

	# Get each card's data from the controller and organize it into Qset form.
	_process = (card) ->
		card.front = _escapeHTML card.front
		card.back  = _escapeHTML card.back

		qsetItem        = {}
		qsetItem.assets = []

		qsetItem.assets[0] = if card.URLs[0] isnt "" then card.URLs[0] else '-1'
		qsetItem.assets[1] = if card.URLs[1] isnt "" then card.URLs[1] else '-1'

		qsetItem.questions = [{text : card.front}]
		qsetItem.answers   = [{text : card.back, value : '100', options : [], id : ''}]
		qsetItem.type      = 'QA'
		qsetItem.id        = ''

		qsetItem

	_escapeHTML = (string) -> 
		string.replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot').replace(/'/g,'&#x27').replace(/\//g,'&#x2F')

	# Adds input placeholder functionality in browsers that are more aged like fine wines.
	_polyfill = () ->
		$('[placeholder]')
		.focus ->
			input = $(this)
			if input.val() is input.attr 'placeholder'
				input.val ''
				input.removeClass 'placeholder'
		.blur ->
			input = $(this)
			if input.val() is '' or input.val() is input.attr 'placeholder'
				input.addClass 'placeholder'
				input.val input.attr 'placeholder'
		.blur()

		$('[placeholder]').parents('form').submit ->
			$(this).find('[placeholder]').each ->
				input = $(this)
				if input.val() is input.attr 'placeholder' then input.val ''

	_trace = -> if console? && console.log? then console.log.apply console, arguments

	# Public.
	manualResize             : true
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete

# Bootstrap the document and define it as the creator module.
# This will allow angular to add directives to every "ng" HTML attribute.
angular.bootstrap document, ["FlashcardsCreator"]
