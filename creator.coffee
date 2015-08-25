# Create an angular module to import the animation module and house our controller
Flashcards = angular.module 'FlashcardsCreator', ['ngAnimate', 'ngSanitize']

Flashcards.directive 'ngEnter', ->
	return (scope, element, attrs) ->
		element.bind "keydown keypress", (event) ->
			if event.which == 13
				scope.$apply -> scope.$eval(attrs.ngEnter)
				event.preventDefault()


Flashcards.directive 'focusMeWatch', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout -> element[0].focus()
			value


Flashcards.directive 'focusMe', ($timeout) ->
	scope:
		condition: "=focusMe"
	link: (scope, element, attrs) ->
		if scope.condition
			$timeout -> element[0].focus()

# Directive that handles all media imports & removals
Flashcards.directive 'importAsset', ($http, $timeout) ->
	template: '<div id="{{myId}}"></div><button class="del-asset" aria-label="Delete asset." ng-hide="!cardFace.asset" ng-click="deleteAsset(cardFace)"><span class="icon-close"></span><span class="descript del">remove image/audio</span></button><button aria-label="Add Asset." ng-hide="cardFace.asset" ng-click="requestMediaImport(cardFace)" ng-attr-tabindex="{{startingTabIndex + 1 + (face == "front" ? 0 : 2)}}"><span class="icon-image"></span><span class="descript add">add image/audio</span></button>'
	link: (scope, element, attrs) ->
		scope.myId = Math.floor(Math.random() * 100000) + '-import-asset'
		scope.deleteAsset = (cardFace) ->
			cardFace.asset = ''
			el = angular.element(document.getElementById(scope.myId))
			el.empty()
			null
		scope.requestMediaImport = (cardFace) ->
			# Save the card/face that requested the image
			scope.faceWaitingForMedia = cardFace
			Materia.CreatorCore.showMediaImporter()
		scope.onMediaImportComplete = (media) ->
			faceWaitingForMedia.asset = media[0].id
			# Variable used by importAsset directive
			asset= media[0].type
			url = $scope.getMediaUrl(faceWaitingForMedia.asset)
			switch asset
				when 'flv'
					$timeout ->
						el.empty()
						el.append('<video controls src="' + url + '"></video>')
				when 'mp3'
					$timeout ->
						el.empty()
						el.append('<audio controls src="' + url + '"></audio>')
				when 'jpg'
					$timeout ->
						el.empty()
						el.append('<img src="' + url + '">')
				when 'png'
					$timeout ->
						el.empty()
						el.append('<img src="' + url + '">')
				when 'gif'
					$timeout ->
						el = angular.element(document.getElementById(scope.myId))
						el.empty()
						el.append('<img src="' + url + '">')

# Set the controller for the scope of the document body.
Flashcards.controller 'FlashcardsCreatorCtrl', ($scope, $sanitize) ->
	SCROLL_DURATION_MS = 500
	WHEEL_DELTA_THRESHOLD = 5

	$scope.FACE_BACK = 0
	$scope.FACE_FRONT = 1
	$scope.ACTION_CREATE_NEW_CARD = 'create'
	$scope.ACTION_IMPORT = 'import'
	$scope.title = "My Flash Cards widget"
	$scope.cards = []
	$scope.introCompleted = false

	scrollDownIntervalId = null
	scrollDownTimeoutId = null


	importCards = (items) ->
		$scope.lastAction = $scope.ACTION_IMPORT

		for item in items
			$scope.addCard item

		$scope.$apply()


	# View actions
	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.introCompleted = true
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		$scope.title = title
		importCards qset.items[0].items

	$scope.onSaveClicked = (mode = 'save') ->
		sanitizedTitle = $sanitize $scope.title

		# Decide if it is ok to save
		if sanitizedTitle is ''
			Materia.CreatorCore.cancelSave 'Please enter a title.'
			return false

		for card, i in $scope.cards
			if card.front.text.length > 50 and card.front.asset
				Materia.CreatorCore.cancelSave 'Please reduce the text of the front of card #'+(i+1)+' to fit the card.'
				return false
			if card.back.text.length > 50 and card.back.asset
				Materia.CreatorCore.cancelSave 'Please reduce the text of the back of card #'+(i+1)+' to fit the card.'
				return false

		Materia.CreatorCore.save sanitizedTitle, buildQsetFromCards($scope.cards)

	$scope.onSaveComplete = -> true

	$scope.onQuestionImportComplete = importCards.bind(@)

	$scope.createNewCard = ->
		$scope.lastAction = $scope.ACTION_CREATE_NEW_CARD;
		$scope.addCard()
		scrollToBottom()

	$scope.getMediaUrl = (asset) ->
		if not asset or asset is '-1' then return ''
		Materia.CreatorCore.getMediaUrl(asset)

	$scope.addCard = (item) ->
		$scope.cards.push
			id: item?.id || ''
			front:
				text: item?.questions?[0]?.text?.replace(/\&\#10\;/g, '\n') || ''
				id: item?.questions?[0]?.id || ''
				asset: item?.assets?[0] || ''
			back:
				text: item?.answers?[0]?.text?.replace(/\&\#10\;/g, '\n') || ''
				id: item?.answers?[0]?.id || ''
				asset: item?.assets?[1] || ''

	$scope.removeCard = (index) ->
		$scope.cards.splice index, 1

	buildQsetFromCards = (cards) ->
		items = []

		for card in cards
			items.push getQsetItemFromCard(card)

		options: {}
		assets: []
		rand: false
		name: ''
		items: [{items:items}]

	getQsetItemFromCard = (card) ->
		sanitizedQuestion = $sanitize card.front.text
		sanitizedAnswer   = $sanitize card.back.text

		materiaType: 'question'
		type: 'QA'
		id: card.id
		questions: [{id:card.front.id, text:sanitizedQuestion}]
		answers: [{id:card.back.id, text:sanitizedAnswer, value:'100'}]
		assets: [card.front.asset, card.back.asset]

	scrollToBottom = ->
		clearInterval scrollDownTimeoutId
		if scrollDownIntervalId is null
			scrollDownIntervalId = setInterval ->
				window.scrollTo 0, document.body.scrollHeight
			, 10
		scrollDownTimeoutId = setTimeout clearScroll, SCROLL_DURATION_MS

	clearScroll = ->
		clearInterval scrollDownIntervalId
		scrollDownIntervalId = null

	window.addEventListener 'mousewheel', clearScroll.bind(@)

	Materia.CreatorCore.start $scope
