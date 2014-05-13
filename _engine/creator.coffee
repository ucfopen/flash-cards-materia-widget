###

Materia
It's a thing

Widget  : Flashcards, Creator
Authors : Jonathan Warner, Brandon Stull, Micheal Parks
Updated : 5/14

###

# Create an angular module to import the animation module and house our controller
Flashcards = angular.module 'FlashcardsCreator', ['ngAnimate', 'ngSanitize']

Flashcards.directive('ngEnter', ->
    return (scope, element, attrs) ->
        element.bind("keydown keypress", (event) ->
            if(event.which == 13)
                scope.$apply ->
                    scope.$eval(attrs.ngEnter)
                event.preventDefault()
        )
)
Flashcards.directive('focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
])


# The 'Resource' service contains all app logic that does pertain to DOM manipulation
Flashcards.factory 'Resource', ['$sanitize', ($sanitize) ->
	buildQset: (title, items) ->
		qsetItems = []
		qset = {}

		# Decide if it is ok to save
		if title is ''
			Materia.CreatorCore.cancelSave 'Please enter a title.'
			return false
		else
			for i in [0..items.length-1]
				if items[i].front.length > 50 && items[i].URLs[0] != ''
					Materia.CreatorCore.cancelSave 'Please reduce the text of the front of card #'+(i+1)+' to fit the card.'
					return false
				if items[i].back.length > 50 && items[i].URLs[1] != ''
					Materia.CreatorCore.cancelSave 'Please reduce the text of the back of card #'+(i+1)+' to fit the card.'
					return false

		qset.options = {}
		qset.assets = []
		qset.rand = false
		qset.name = ''

		qsetItems.push @processQsetItem items[i] for i in [0..items.length-1]
		qset.items = [{ items: qsetItems }]

		qset

	processQsetItem: (item) ->
		# Remove any dangerous content
		item.ques = $sanitize item.front
		item.ans = $sanitize item.back

		materiaType: "question"
		id: ""
		assets: item.assets
		type: 'QA'
		questions: [{text : item.ques}]
		answers: [{value : '100', text : item.ans}]
]

# Set the controller for the scope of the document body.
Flashcards.controller 'FlashcardsCreatorCtrl', ['$scope', '$sanitize', 'Resource',
($scope, $sanitize, Resource) ->
	$scope.title = "My Flash Cards widget"
	$scope.cards = []
	_imgRef = []

	# View actions
	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.showIntroDialog = true

	$scope.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		$scope.title = title
		$scope.onQuestionImportComplete qset.items[0].items

	$scope.onSaveClicked = (mode = 'save') ->
		# Create a qset to save
		qset = Resource.buildQset $sanitize($scope.title), $scope.cards
		if qset then Materia.CreatorCore.save $sanitize($scope.title), qset

	$scope.onSaveComplete = () -> true

	$scope.onQuestionImportComplete = (items) ->
		# Add each imported question to the DOM
		for i in [0..items.length-1]
			$scope.addCard items[i].questions[0].text.replace(/\&\#10\;/g, '\n'), items[i].answers[0].text.replace(/\&\#10\;/g, '\n'), items[i].assets
			if items[i].assets[0] and items[i].assets[0] != '-1' then $scope.cards[i].URLs[0] = Materia.CreatorCore.getMediaUrl items[i].assets[0]
			if items[i].assets[1] and items[i].assets[0] != '-1' then $scope.cards[i].URLs[1] = Materia.CreatorCore.getMediaUrl items[i].assets[1]
		$scope.$apply()

	$scope.onMediaImportComplete = (media) ->
		$scope.setURL Materia.CreatorCore.getMediaUrl(media[0].id), media[0].id
		$scope.$apply()

	$scope.addCard = (front = "", back = "", assets = ["",""]) ->
		$scope.cards.push { front:front, back:back, URLs:["",""], assets: assets }

	$scope.removeCard = (index) ->
		$scope.cards.splice index, 1

	$scope.requestImage = (index, face) ->
		Materia.CreatorCore.showMediaImporter()
		# Save the card/face that requested the image
		_imgRef[0] = index
		_imgRef[1] = face

	$scope.setURL = (URL,id) ->
		# Bind the image URL to the DOM
		$scope.cards[_imgRef[0]].URLs[_imgRef[1]] = URL
		$scope.cards[_imgRef[0]].assets[_imgRef[1]] = id

	$scope.deleteImage = (index, face) ->
		$scope.cards[index].URLs[face] = ""
	
	Materia.CreatorCore.start $scope
]

