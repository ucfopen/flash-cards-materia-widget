
Namespace('Flashcards').Card        = [] # Array of objects that holds active cards.
Namespace('Flashcards').DiscardPile = [] # Array of objects that holds discards.

Namespace('Flashcards').Engine = do ->
	nodes = {} # DOM Elements.

	currentCardId = 0       # Specifies the main card that the user is interacting with.
	numCards      = null    # Specifies the number of active cards.
	numDiscard    = null    # Specifies the number of inactive cards.
	animating     = false   # Gate to prevent events while transitioning.
	buffer        = false   # Gate for duplicate event prevention.
	overlay       = false   # Specifies whether the overlay is shown or not.
	rotation      = ''      # Specifies the current default rotation for all cards.
	timer         = null    # A setInterval timer for regular interval events.
	atari         = false   # Triggered by KONAMI CODE

	# Environmental conditions.
	isMobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/
	isFF     = typeof InstallTrigger isnt 'undefined'
	isIE     = /MSIE (\d+\.\d+);/.test(navigator.userAgent)
	pointer  = window.navigator.msPointerEnabled

	# If a user has touch and mouse capabilities, make sure we don't
	# restrict them to a mobile environment.
	if pointer then isMobile = false
	upEventType = if pointer then "MSPointerUp" else "mouseup"

	# Called by Materia.Engine when widget Engine should start the UI.
	start = (instance, qset, version = '1') ->
		if not _browserSupportsSvg()
			$('.error-notice-container').show()
			return

		Hammer(document.getElementById('gotit')).on 'tap', ->
			$('.instructions').hide()

		if instance.name is undefined or null
			instance.name = "Widget Title Goes Here"

		_qset = qset
		_cacheNodes()
		_drawBoard(instance.name, qset.items[0].items.length)
		_storeCards(qset.items[0].items)
		_setCardPositions()
		_addEventListeners()
		_setArrowState()

		if isIE then yepnope(load:['css/IE.css'], complete : () -> document.getElementById('main').className+="IE")

		# If a user unlocks the easter egg, load the atari files and fire her up!
		easterEgg = new Konami _easterEggStart

		# If the user has stumbled upon the meaning of life, give them atari mode.
		if Math.floor(Math.random()*100) is 42 then _easterEggStart()

	_browserSupportsSvg = ->
		typeof SVGRect != "undefined"

	_easterEggStart = () ->
		yepnope(
			load : [
				'css!//fonts.googleapis.com/css?family=Press+Start+2P',
				'assets/js/atari.js',
				'assets/js/timbre.js',
				'assets/css/atari.css'
			]
			complete : () ->
				atari = true
				Flashcards.Atari.start()
		)

	# Reference commonly accessed nodes.
	_cacheNodes = () ->
		nodes.container    = document.getElementById 'container'
		nodes.gameboard    = document.getElementById 'board'
		nodes.leftArrow    = document.getElementById 'icon-left'
		nodes.rightArrow   = document.getElementById 'icon-right'
		nodes.helpOverlay  = document.getElementById 'overlay'
		nodes.icons        = document.getElementsByClassName 'icon'
		nodes.finishMssg   = document.getElementById 'finished'

		nodes.$container   = $(nodes.container)

	# Draws the gameboard.
	# @title  : The game instance title.
	# @length : The total number of cards.
	_drawBoard = (title, length) ->
		document.getElementById('instance-title').innerHTML = title

		_tFlashcard = $($('#t-flashcard').html())
		nodes.$container.append _tFlashcard.clone() for i in [0...length]

	# Compute font scaling based on character length / scale factor. Max is 25px, min is 16px. ScaleFactor determines how quickly the font size is reduced.
	# Scaling is appended to the card's <p> tag as an inline style
	_computeFontSize = (text) ->
		scaleFactor = 35
		defaultSize = 25
		minSize = 16

		computedFontSize = defaultSize

		diff = text.length / scaleFactor
		if 25 - diff > minSize then computedFontSize = defaultSize - diff
		else computedFontSize = minSize

		return computedFontSize

	# Stores card data.
	# @data : Card information pulled from the qset.
	_storeCards = (data) ->
		numCards   = data.length
		_cardNodes = document.getElementsByClassName 'flashcard'

		for i in [0...numCards]
			Flashcards.Card.push {}
			_card = Flashcards.Card[i]

			# Single flashcard specific data.
			_card.node      = _cardNodes[i]
			_card.FrontText = data[i].answers[0].text.replace(/\&\#10\;/g, '<br>')
			_card.BackText  = data[i].questions[0].text.replace(/\&\#10\;/g, '<br>')

			# Strings that contain inline font scaling style (if applicable)
			frontStyleStr = ""
			backStyleStr = ""

			if data[i].assets?[1]
				# Handle former QSet asset format
				if typeof data[i].assets[1] isnt 'object' and data[i].assets[1] isnt '-1'
					_card.FrontURL = Materia.Engine.getImageAssetUrl data[i].assets[1]
				# Handle new QSet asset format
				else if typeof data[i].assets[1] is 'object'
					_card.FrontURL = data[i].assets[1].url
			else _card.FrontURL = '-1'

			if data[i].assets?[0]
				# Handle former QSet asset format
				if typeof data[i].assets[0] isnt 'object' and data[i].assets[0] isnt '-1'
					_card.BackURL = Materia.Engine.getImageAssetUrl data[i].assets[0]
				# Handle new QSet asset format
				else if typeof data[i].assets[0] is 'object'
					_card.BackURL = data[i].assets[0].url
			else _card.BackURL = '-1'

			if _card.FrontURL? && _card.FrontURL != '-1'
				if _card.FrontText is '' then _frontClass = "no-text" else _frontClass = "mixed"
			else
				if _card.FrontText.split(' ').length < 8 then _frontClass = "title" else _frontClass = "description"

				computedFrontFontSize = _computeFontSize _card.FrontText
				frontStyleStr = 'style="font-size:'+computedFrontFontSize+'px;'

			if _card.BackURL? && _card.BackURL != '-1'
				if _card.BackText is '' then _backClass = "no-text" else _backClass = "mixed"
			else
				if _card.BackText.split(' ').length < 8 then _backClass = "title" else _backClass = "description"

				computedBackFontSize = _computeFontSize _card.BackText
				backStyleStr = 'style="font-size:'+computedBackFontSize+'px;'

			_card.node.children[0].children[0].innerHTML = '<p class="'+_frontClass+'" '+frontStyleStr+' ">'+_card.FrontText+'</p>'
			if _card.FrontURL isnt '-1'
				if typeof data[i].assets[1] isnt 'object'
					_card.node.children[0].children[1].innerHTML = '<img class="'+_frontClass+'" src="'+_card.FrontURL+'">'
				else if data[i].assets[1].type == 'jpg' or data[i].assets[1].type == 'jpeg' or data[i].assets[1].type == 'png' or data[i].assets[1].type == 'gif'
					_card.node.children[0].children[1].innerHTML = '<img class="'+_frontClass+'" src="'+_card.FrontURL+'">'
				else if data[i].assets[1].type == 'mp3' || data[i].assets[1].type == 'wav' || data[i].assets[1].type == 'aif'
					_card.node.children[0].children[1].innerHTML = '<audio controls class="'+_frontClass+'" src="'+_card.FrontURL+'">'
				else if data[i].assets[1].type == 'link'
					_card.node.children[0].children[1].innerHTML = '<iframe class="'+_frontClass+'" src="' + _card.FrontURL + '" frameborder="0" allowfullscreen></iframe>'

			_card.node.children[1].children[0].innerHTML  = '<p class="'+_backClass+'" '+backStyleStr+' ">'+_card.BackText+'</p>'
			if _card.BackURL isnt '-1'
				if typeof data[i].assets[0] isnt 'object'
					_card.node.children[1].children[1].innerHTML = '<img class="'+_backClass+'" src="'+_card.BackURL+'">'
				else if data[i].assets[0].type == 'jpg' or data[i].assets[0].type == 'jpeg' or data[i].assets[0].type == 'png' or data[i].assets[0].type == 'gif'
					_card.node.children[1].children[1].innerHTML = '<img class="'+_backClass+'" src="'+_card.BackURL+'">'
				else if data[i].assets[0].type == 'mp3' || data[i].assets[0].type == 'wav' || data[i].assets[0].type == 'aif'
					_card.node.children[1].children[1].innerHTML = '<audio controls class="'+_backClass+'" src="'+_card.BackURL+'">'
				else if data[i].assets[0].type == 'link'
					_card.node.children[1].children[1].innerHTML = '<iframe class="'+_backClass+'" src="' + _card.BackURL + '" frameborder="0" allowfullscreen></iframe>'

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	# @face : Specifies whether or not to rotate the card when placing them in their positions.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0...numCards]
				if i is currentCardId     then Flashcards.Card[i].node.className = 'flashcard rotated'
				else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left-rotated'
				else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0...numCards]
				if i is currentCardId     then Flashcards.Card[i].node.className = 'flashcard'
				else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left'
				else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right'

	_addEventListeners = () ->
		# document.oncontextmenu = -> false                # Disables right click.
		# document.addEventListener 'mousedown', (e) ->
		# 	if e.button is 2 then false else true          # Disables right click.
		window.onscroll = -> window.scrollTo(0,0)
		if isMobile
			# Stop those has-been events from messing things up.
			document.addEventListener 'click', (e) ->      e.stopPropagation()
			document.addEventListener 'touchstart', (e) -> e.preventDefault()

			# Hammer.js events for mobile devices.
			Hammer(document).on 'swiperight', (e) ->
				if _canMove 'left'  then _shiftCards 'right'
				e.stopPropagation()
			Hammer(document).on 'swipeleft', (e) ->
				if _canMove 'right' then _shiftCards 'left'
				e.stopPropagation()
			Hammer(document).on 'swipedown', -> _discard()
			Hammer(document).on 'tap', -> if overlay then _toggleOverlay()

			Hammer(document.getElementById('icon-left')).on  'tap', -> if _canMove 'left'  then _shiftCards 'right'
			Hammer(document.getElementById('icon-right')).on 'tap', -> if _canMove 'right' then _shiftCards 'left'

			Hammer(document.getElementById('icon-help')).on    'tap', _toggleOverlay
			Hammer(document.getElementById('icon-restore')).on 'tap', _unDiscardAll
			Hammer(document.getElementById('icon-finish')).on  'tap', _unDiscardAll
			Hammer(document.getElementById('icon-rotate')).on  'tap', -> _rotateCards(if rotation is '' then 'back')
			Hammer(document.getElementById('icon-shuffle')).on 'tap', _shuffleCards

			_flashcardNodes = document.getElementsByClassName('flashcard')
			for i in [0..._flashcardNodes.length]
				Hammer(_flashcardNodes[i]).on 'tap', ->
					if _isDiscarded(this) then _unDiscard()
					else _flipCard()

			_removeNodes = document.getElementsByClassName('remove-button')
			for i in [0..._removeNodes.length]
				Hammer(_removeNodes[i]).on 'tap', (e) ->
					_discard()
					e.stopPropagation()
		else
			document.addEventListener upEventType, -> if overlay then _toggleOverlay()

			$('#icon-left').on    'mouseup', ->
				_leftSelected()
				_killAudioVideo()
			$('#icon-right').on   'mouseup', ->
				_rightSelected()
				_killAudioVideo()
			$('#icon-help').on    'mouseup', _toggleOverlay
			$('#icon-restore').on 'mouseup', ->
				_killAudioVideo()
				_unDiscardAll()
			$('#icon-finish').on  'mouseup', ->
				_killAudioVideo()
				_unDiscardAll()
			$('#icon-rotate').on  'mouseup', ->
				_killAudioVideo()
				_rotateCards(if rotation is '' then 'back')
			$('#icon-shuffle').on 'mouseup', ->
				_killAudioVideo()
				_shuffleCards()

			$('audio').on    'mouseup', (e)->
				if _isDiscarded(this) then _unDiscard()
				else e.stopPropagation()

			$('.flashcard').on    'mouseup', ->
				# Shuts off all audio players when card is flipped.
				_killAudioVideo()
				if _isDiscarded(this) then _unDiscard()
				else _flipCard()

			$('.remove-button').on 'mouseup', (e) ->
				# Shuts off all audio players when card is discarded.
				_killAudioVideo()
				_discard()
				e.stopPropagation()

		# Key events for keyboardz.
		window.addEventListener 'keydown', (e) ->
			switch e.keyCode
				when 37     then _leftSelected()                             # Left arrow key.
				when 38     then _unDiscard()                                # Up arrow key.
				when 39     then _rightSelected()                            # Right arrow key.
				when 40     then _discard()                                  # Down arrow key.
				when 32, 70 then _flipCard()                                 # F key and space bar.
				when 72     then _toggleOverlay()                            # H key.
				when 82     then _rotateCards(if rotation is '' then 'back') # R key.
				when 83     then _shuffleCards()                             # S key.
				when 85     then _unDiscardAll()                             # U key.

			_killAudioVideo()
			e.preventDefault()

	_leftSelected = ()  -> if _canMove 'left'  then _shiftCards 'right'
	_rightSelected = () -> if _canMove 'right' then _shiftCards 'left'

	# Asseses which direction has accessable cards.
	# @direction : The direction we wish to inquire about.
	_canMove = (direction) ->
		if direction is 'left'
			if currentCardId is 0 or numCards is 0 then return false
		if direction is 'right'
			if currentCardId is numCards-1 or numCards is 0 then return false
		return true

	# Shift cards left or right depending on the which directional arrow has been pressed.
	# @direction : The direction we wish to shift the cards.
	_shiftCards = (direction) ->
		if not animating
			if atari then Flashcards.Atari.playButton()

			# Move the current card in the specified direction.
			Flashcards.Card[currentCardId].node.className = 'flashcard '+direction+rotation

			# Increment or decrement the current card ID.
			currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1

			# Animate the new current card to the center.
			Flashcards.Card[currentCardId].node.className = "flashcard "+(if rotation is '' then '' else 'rotated')

			_setArrowState()

	# Shows or hides directional arrows depending on what cards are viewable.
	_setArrowState = () ->
			if _canMove 'right' then nodes.rightArrow.className = 'arrow shown' else nodes.rightArrow.className = 'arrow'
			if _canMove 'left'  then nodes.leftArrow.className  = 'arrow shown' else nodes.leftArrow.className  = 'arrow'

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if numCards > 0
			if atari then Flashcards.Atari.playFlip()
			# The back is currently showing.
			if Flashcards.Card[currentCardId].node.className is 'flashcard rotated'
				Flashcards.Card[currentCardId].node.className = 'flashcard'
			# The front is currently showing.
			else
				Flashcards.Card[currentCardId].node.className = 'flashcard rotated'

	_killAudioVideo = () ->
		$('audio').each ->
			if !@paused
				@pause()
			return

		$('iframe').each ->
			source = this.src
			this.src = ''
			this.src = source
			return

	# Shuffles the entire deck.
	_shuffleCards = () ->
		if numCards > 1
			if not animating
				animating = true
				setTimeout ->
					animating = false
				, 1200

				if atari then Flashcards.Atari.playIcon 'shuffle'

				_posArr = [0, 1, 2, 3, 4]

				# Access 5 flashcards: two from the left, the current card, and two from the right.
				# Then stage them.
				for i in [-2..2]
					if Flashcards.Card[currentCardId+i]?
						Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-sh-'+(_posArr[(i+2)])+rotation

				_shuffle(_posArr)

				setTimeout ->
					for i in [-2..2]
						if Flashcards.Card[currentCardId+i]?
							_stageShufflePt1(Flashcards.Card[currentCardId+i].node, i+2)
							_stageShufflePt2(Flashcards.Card[currentCardId+i].node, i+2, _posArr[i+2])
				, 600

				setTimeout ->

				nodes.icons[3].className = 'icon focused' # Focus the shuffle icon.

				# Shuffle and reset the card data, then conclude the animation.
				setTimeout ->
					Flashcards.Card = _shuffle(Flashcards.Card)
					_setCardPositions(if rotation is '' then null else 'reverse')
					nodes.icons[3].className = 'icon'
				, 1500

	_stageShufflePt1 = (card, i) ->
		setTimeout ->
			card.className = 'flashcard shuffle'+rotation
		, i*50

	_stageShufflePt2 = (card, i, pos) ->
		setTimeout ->
			card.className = 'flashcard stage-sh-'+pos+rotation
		, i*100

	# Shuffles an array.
	# @arr : An array.
	_shuffle = (a) ->
		for i in [1...a.length]
			j = Math.floor Math.random() * (a.length)
			[a[i], a[j]] = [a[j], a[i]]
		a


	# Triggers the illustration for rotating the cards en masse.
	# @face : The default rotation of all cards.
	_rotateCards = (face = null) ->
		if numCards > 0
			if not animating
				animating = true

				if atari then Flashcards.Atari.playIcon 'rotate'

				nodes.icons[2].className = 'icon focused' # Focus the rotate icon.

				_rotation        = if rotation is '' then '' else '-rotated'
				_reverseRotation = if rotation is '' then '-rotated' else ''

				# Access 5 flashcards: two from the left, the current card, and two from the right.
				# Then stage them.
				for i in [-2..2]
					if Flashcards.Card[currentCardId+i]?
						Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-'+(i+2)+_rotation

				# At this point, the flashcards are staged and must be given a rotation animation.
				setTimeout ->
					j = 0 # A counter to allot staging positions to cards.
					timer = setInterval ->
						if Flashcards.Card[currentCardId+(j-2)]?
							Flashcards.Card[currentCardId+(j-2)].node.className = 'flashcard stage-'+j+_reverseRotation
						if j < 4 then j++
					, 100
				, 600

				# Now it's time to bring the flashcards back to their default positions.
				setTimeout ->
					animating = false
					clearInterval(timer)

					_setCardPositions(if face is 'back' then 'reverse' else '')

					nodes.icons[2].className = 'icon'
				, 1400

	# Decides if a flashcard node has any of the discard position classes.
	# @flashcard : The flashcard of interest.
	_isDiscarded = (flashcard) ->
		if flashcard.className.split(' ')[1]? && flashcard.className.split(' ')[1].split('-')[0]?
			return flashcard.className.split(' ')[1].split('-')[0] is 'discarded'

	# Moves the current card into the discard pile.
	_discard = () ->
		if not animating
			if numCards > 0
				numDiscard++
				numCards--

				nodes.icons[1].className = "icon"

				if atari then Flashcards.Atari.playDiscard()

				# Store a record of the latest discard.
				_moveCardObject(Flashcards.Card, Flashcards.DiscardPile, currentCardId)

				# Animate the card into the discard pile.
				_len = Flashcards.DiscardPile.length
				if _len > 3 then Flashcards.DiscardPile[_len-1].node.className = 'flashcard discarded-pos-3'
				else Flashcards.DiscardPile[_len-1].node.className = 'flashcard discarded-pos-'+(_len-1)

				if _len > 4 then setTimeout ->
					Flashcards.DiscardPile[_len-1].node.className = 'flashcard hidden'
				, 710

				# If the user has discarded the entire deck, prompt them to restore it.
				if numCards is 0
					_hideIcons()
					_showElement nodes.finishMssg, true
					nodes.container.className = 'hidden'
				else
					if Flashcards.Card[currentCardId]?
						Flashcards.Card[currentCardId].node.className = "flashcard "+(if rotation is '' then '' else 'rotated')
					else
						currentCardId--
						Flashcards.Card[currentCardId].node.className = "flashcard "+(if rotation is '' then '' else 'rotated')

				_setArrowState()

	# Takes a card from the first array and places it in the second.
	# @arr1  : The array we remove a card from.
	# @arr2  : The array we insert a card into.
	# @index : The index of the card we are removing from the first array.
	_moveCardObject = (arr1, arr2, index) ->
		_tempArray = arr1
		arr2.push _tempArray.splice(index, 1)[0]
		arr1 = _tempArray

	# Moves the last discarded card back into the active deck.
	_unDiscard = () ->
		# Buffer prevents a user from accidently discarding
		# two cards in a row if two events are triggered.
		if not buffer
			buffer = true
			setTimeout ->
				buffer = false
			, 100

			# Don't let this event happen if no cards or all cards are discarded.
			if numDiscard > 0 && numCards != 0
				numDiscard--
				numCards++

				if numDiscard is 0 then nodes.icons[1].className = "icon unselectable"

				# Move last discarded from discard to active pile.
				_moveCardObject(Flashcards.DiscardPile, Flashcards.Card, Flashcards.DiscardPile.length-1)

				# Animate the card from one pile to another, then shift to its position.
				_len = Flashcards.DiscardPile.length
				if _len > 2 then Flashcards.Card[Flashcards.Card.length-1].node.className = 'flashcard discarded-pos-3'
				else Flashcards.Card[Flashcards.Card.length-1].node.className = 'flashcard discarded-pos-'+(_len-1)

				setTimeout ->
					Flashcards.Card[Flashcards.Card.length-1].node.className = 'flashcard ' + rotation
					_dif = Flashcards.Card.length-2-currentCardId
					_shiftCards 'left' for i in [0.._dif]
					_setArrowState()
				, 20

	_restoreTriggered = () ->
		if atari then Flashcards.Atari.playIcon 'restore'

		_showIcons()
		nodes.icons[0].className = 'icon focused'
		nodes.icons[1].className = 'icon focused'

		setTimeout ->
			nodes.icons[0].className = 'icon'
			nodes.icons[1].className = 'icon'
		, 1000

	# Moves all discarded cards into the active deck.
	_unDiscardAll = () ->
		if not animating
			if numDiscard > 0

				_restoreTriggered()

				# Move all cards from the discard pile into the active pile.
				for i in [0...Flashcards.DiscardPile.length]
					_moveCardObject(Flashcards.DiscardPile, Flashcards.Card, Flashcards.DiscardPile.length-1)

				# Reset discard data.
				if numCards is 0 then currentCardId = 0
				numDiscard = 0
				numCards = Flashcards.Card.length
				for i in [0...numCards]
					Flashcards.Card[i].node.className = 'flashcard discarded-pos-3'

				setTimeout ->
					for i in [0...numCards]
						Flashcards.Card[i].node.className = "flashcard right"+rotation

					# Stage the cards.
					for i in [-2..2]
						if Flashcards.Card[currentCardId+i]?
							Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-'+(i+2)+rotation

					_hideElement(nodes.finishMssg, true) # Hide the finish message.
					nodes.container.className = ''       # Make sure the card container is shown.

					# Return cards to default positions.
					setTimeout ->
						_setCardPositions(if rotation is '' then null else 'reverse')
						_setArrowState()
					, 800

					setTimeout ->
						nodes.icons[1].className = "icon unselectable"
					, 1200
				, 20

	# Opens or closes the help overlay.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if overlay is true then overlay = false else overlay = true

			if nodes.helpOverlay.className is 'overlay shown'
				_setArrowState()
				nodes.icons[4].className    = 'icon'
				nodes.gameboard.className   = ''
				nodes.helpOverlay.className = 'overlay'
			else
				nodes.rightArrow.className  = 'arrow shown'
				nodes.leftArrow.className   = 'arrow shown'
				nodes.icons[4].className    = 'icon focused'
				nodes.gameboard.className   = 'blurred'
				nodes.helpOverlay.className = 'overlay shown'

	# Adds a shown class to an element and optionally fades it in.
	_showElement = (elem, fadeIn = false) ->
		elem.className = 'shown'

		if fadeIn then setTimeout ->
			elem.className = 'shown faded-in'
		, 5

	# Removes all classes from an element and optionally fades it out..
	_hideElement = (elem, fadeIn = false) ->
		if fadeIn then elem.className = "shown"
		else elem.className = ""; return

		setTimeout ->
			elem.className = ""
		, 205

	_hideIcons = () ->
		for i in [1...nodes.icons.length]
			nodes.icons[i].className = 'icon faded-out'

	_showIcons = () ->
		for i in [1...nodes.icons.length]
			nodes.icons[i].className = 'icon'

	# Public.
	start : start
	nodes : nodes
