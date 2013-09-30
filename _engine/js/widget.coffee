###

Materia
It's a thing

Widget  : Flashcards
Authors : Micheal Parks

###

Namespace('Flashcards').Card        = [] # Array of objects that holds active cards.
Namespace('Flashcards').DiscardPile = [] # Array of objects that holds discards.

Namespace('Flashcards').Engine = do ->
	Nodes = {} # DOM Elements.

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

	isFF     = navigator.userAgent.toLowerCase().indexOf('firefox') > -1
	isIE     = /MSIE (\d+\.\d+);/.test(navigator.userAgent)
	pointer  = window.navigator.msPointerEnabled

	# As of 9/13 Firefox won't contain CSS3 transforms within an iframe.
	# Setting the opacity to 0.9999 is the best solution we've found that (enigmatically)
	# solves this issue. However, it causes other issues in webkit browsers (surprise!),
	# so we must inject it conditionally.
	if isFF then document.getElementByID('board').style.opacity = 0.9999

	# If a user has touch and mouse capabilities, make sure we don't
	# restrict them to a mobile environment.
	if pointer then isMobile = false
	upEventType = if pointer then "MSPointerUp" else "mouseup"

	# Called by Materia.Engine when widget Engine should start the UI.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_cacheNodes()
		_drawBoard(instance.name, qset.items[0].items.length)
		_storeCards(qset.items[0].items)
		_setCardPositions()
		_addEventListeners()

		if isIE
			yepnope({
				load : [
					'js/IE.js',
					'css/IE.css'
				]
				complete : () ->
					Flashcards.IE.start Nodes.$container
			})
		else
			# TODO

		# If a user unlocks the easter egg, load the atari files and fire her up!
		easterEgg = new Konami _easterEggStart

		# If the user has stumbled upon the meaning of life, give them atari mode.
		if Math.floor(Math.random()*100) is 42 then _easterEggStart()
			
	_easterEggStart = () ->
		yepnope(
			load : [
				'css!//fonts.googleapis.com/css?family=Press+Start+2P',
				'js/atari.js',
				'js/timbre.js',
				'css/atari.css',
			]
			complete : () ->
				atari = true
				Flashcards.Atari.start()
		)

	# Reference commonly accessed nodes.
	_cacheNodes = () ->
		Nodes.container    = document.getElementById 'container'
		Nodes.gameboard    = document.getElementById 'board'
		Nodes.leftArrow    = document.getElementById 'arrow-left'
		Nodes.rightArrow   = document.getElementById 'arrow-right'
		Nodes.helpOverlay  = document.getElementById 'overlay'
		Nodes.icons        = document.getElementsByClassName 'icon'
		Nodes.finishMssg   = document.getElementById 'finished'

		Nodes.$container   = $(Nodes.container)

	# Draws the gameboard.
	# @title  : The game instance title.
	# @length : The total number of cards.
	_drawBoard = (title, length) ->
		document.getElementById('instance-title').innerHTML = title

		_tFlashcard = $($('#t-flashcard').html())
		Nodes.$container.append _tFlashcard.clone() for i in [0..length-1]

	# Stores card data.
	# @data : Card information pulled from the qset.
	_storeCards = (data) ->
		numCards   = data.length
		_cardNodes = document.getElementsByClassName 'flashcard'

		for i in [0..numCards-1]
			Flashcards.Card.push {}

			# Decide if the text will be presented as a term or description based upon length.
			_ansClass = if data[i].answers[0].text.split(' ').length < 8   then "title" else "description"
			_queClass = if data[i].questions[0].text.split(' ').length < 8 then "title" else "description"

			# Single flashcard specific data.
			Flashcards.Card[i].node      = _cardNodes[i]
			Flashcards.Card[i].FrontText = data[i].answers[0].text
			Flashcards.Card[i].BackText  = data[i].questions[0].text
			
			# Handle image assets if they are used. Otherwise, populate HTML with text.
			_cardFront = Flashcards.Card[i].node.children[0].children[0]
			_cardBack  = Flashcards.Card[i].node.children[1].children[0]
			if data[i].answers[0].text is 'None'
				_ansUrl = Materia.Engine.getMediaUrl(data[i].assets[0])
				_cardFront.innerHTML = '<img class="'+_ansClass+'" src="'+_ansUrl+'">'
			else
				_cardFront.innerHTML = '<p class="'+_ansClass+'">'+data[i].answers[0].text+'</p>'

			if data[i].answers[0].text is 'None'
				_queUrl = Materia.Engine.getMediaUrl(data[i].assets[1])
				_cardBack.innerHTML = '<img class="'+_queClass+'" src="'+_queUrl+'">'
			else
				_cardBack.innerHTML = '<p class="'+_queClass+'">'+data[i].questions[0].text+'</p>'

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	# @face : Specifies whether or not to rotate the card when placing them in their positions.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0..numCards-1]
				if i is currentCardId     then Flashcards.Card[i].node.className = 'flashcard rotated'
				else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left-rotated'
				else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0..numCards-1]
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
			Hammer(document).on 'swiperight', -> if _canMove 'left'  then _shiftCards 'right'
			Hammer(document).on 'swipeleft', ->  if _canMove 'right' then _shiftCards 'left'
			Hammer(document).on 'release', _handleUpEvent
		else
			document.addEventListener upEventType, _handleUpEvent

		# Key events for keyboardz.
		window.addEventListener 'keydown', (e) ->
			switch e.keyCode
				when 37 then if  _canMove 'left'  then _shiftCards 'right'   # Left arrow key.
				when 38 then     _unDiscard()                                # Up arrow key.
				when 39 then if  _canMove 'right' then _shiftCards 'left'    # Right arrow key.
				when 40 then     _discard()                                  # Down arrow key.
				when 32, 70 then if not isIE then _flipCard()                # F key and space bar.
				when 72 then     _toggleOverlay()                            # H key.
				when 82 then     _rotateCards(if rotation is '' then 'back') # R key.
				when 83 then     _shuffleCards()                             # S key.
				when 85 then     _unDiscardAll()                             # U key.
			e.preventDefault()

	_handleUpEvent = (event) ->
		# If the overlay is 
		if overlay then _toggleOverlay(); return

		element = event.target

		# Button event handler.
		switch element.id
			# Nav buttons.
			when "left-button"  then if _canMove 'left'  then _shiftCards 'right'
			when "right-button" then if _canMove 'right' then _shiftCards 'left'

			# Options buttons.
			when "help-button"  then _toggleOverlay()
			when "restart"      then _unDiscardAll()
			when "shuffle-icon" then _shuffleCards()
			when "restore-icon" then _unDiscardAll()
			when "rotate-icon"
				if rotation is '' then _rotateCards 'back' else _rotateCards()

		# Events triggered by an element on a flashcard.
		switch element.className
			# A face of the current card has been clicked/touched
			when "front", "back", "title", "description", "container", "content"
				if      _isDiscarded(element.parentNode) then _unDiscard()
				else if _isDiscarded(element.parentNode.parentNode.parentNode) then _unDiscard()
				else if not isIE then _flipCard()
			when 'flashcard rotated' then if not isIE then _flipCard()
			when "remove-button"     then _discard()

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
		if _canMove 'right' then Nodes.rightArrow.className = 'arrow shown' else Nodes.rightArrow.className = 'arrow'
		if _canMove 'left'  then Nodes.leftArrow.className  = 'arrow shown' else Nodes.leftArrow.className  = 'arrow'

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if atari then Flashcards.Atari.playFlip()
		# The back is currently showing.
		if Flashcards.Card[currentCardId].node.className is 'flashcard rotated'
			Flashcards.Card[currentCardId].node.className = 'flashcard'
		# The front is currently showing.
		else
			Flashcards.Card[currentCardId].node.className = 'flashcard rotated'

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
				
				Nodes.icons[2].className = 'icon focused' # Focus the shuffle icon.

				# Shuffle and reset the card data, then conclude the animation.
				setTimeout ->
					Flashcards.Card = _shuffle(Flashcards.Card)
					_setCardPositions(if rotation is '' then null else 'reverse')
					Nodes.icons[2].className = 'icon'
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
	_shuffle = (arr) ->
		for i in [arr.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[arr[i], arr[j]] = [arr[j], arr[i]]
		arr

	# Triggers the illustration for rotating the cards en masse.
	# @face : The default rotation of all cards.
	_rotateCards = (face = null) ->
		if numCards > 0
			if not animating
				animating = true

				if atari then Flashcards.Atari.playIcon 'rotate'

				Nodes.icons[1].className = 'icon focused' # Focus the rotate icon.

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

					if face is 'back' then _setCardPositions 'reverse'
					else                   _setCardPositions()

					Nodes.icons[1].className = 'icon'
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

				if atari then Flashcards.Atari.playDiscard()

				# Store a record of the latest discard.
				_moveCardObject(Flashcards.Card, Flashcards.DiscardPile, currentCardId)

				# Animate the card into the discard pile.
				_len = Flashcards.DiscardPile.length
				if _len > 3 then Flashcards.DiscardPile[_len-1].node.className = 'flashcard discarded-pos-3'
				else Flashcards.DiscardPile[_len-1].node.className = 'flashcard discarded-pos-'+(_len-1)

				# If the user has discarded the entire deck, prompt them to restore it.
				if numCards is 0
					_hideIcons()
					_showElement Nodes.finishMssg, true
					Nodes.container.className = 'hidden'
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

				# Move last discarded from discard to active pile.
				_moveCardObject(Flashcards.DiscardPile, Flashcards.Card, Flashcards.DiscardPile.length-1)

				# Animate the card from one pile to another, then shift to its position.
				Flashcards.Card[Flashcards.Card.length-1].node.className = 'flashcard ' + rotation

				_dif = Flashcards.Card.length-2-currentCardId
				_shiftCards 'left' for i in [0.._dif]
				_setArrowState()

	_restoreTriggered = () ->
		if atari then Flashcards.Atari.playIcon 'restore'

		_showIcons()
		Nodes.icons[0].className = 'icon focused'

		setTimeout ->
			Nodes.icons[0].className = 'icon'
		, 1000

	# Moves all discarded cards into the active deck.
	_unDiscardAll = () ->
		if not animating
			if numDiscard > 0

				_restoreTriggered()

				# Move all cards from the discard pile into the active pile.
				for i in [0..Flashcards.DiscardPile.length-1]
					_moveCardObject(Flashcards.DiscardPile, Flashcards.Card, Flashcards.DiscardPile.length-1)

				# Reset discard data.
				if numCards is 0 then currentCardId = 0
				numDiscard = 0
				numCards = Flashcards.Card.length
				for i in [0..numCards-1]
					Flashcards.Card[i].node.className = "flashcard right"+rotation

				# Stage the cards.
				for i in [-2..2]
					if Flashcards.Card[currentCardId+i]?
						Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-'+(i+2)+rotation

				_hideElement(Nodes.finishMssg, true) # Hide the finish message.
				Nodes.container.className = ''       # Make sure the card container is shown.

				# Return cards to default positions.
				setTimeout ->
					_setCardPositions(if rotation is '' then null else 'reverse')
					_setArrowState()
				, 800

	# Opens or closes the help overlay.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if overlay is true then overlay = false else overlay = true

			if Nodes.helpOverlay.className is 'overlay shown'
				_setArrowState()
				Nodes.icons[3].className    = 'icon'
				Nodes.gameboard.className   = ''
				Nodes.helpOverlay.className = 'overlay'
			else 
				Nodes.rightArrow.className  = 'arrow shown'
				Nodes.leftArrow.className   = 'arrow shown'
				Nodes.icons[3].className    = 'icon focused'
				Nodes.gameboard.className   = 'blurred'
				Nodes.helpOverlay.className = 'overlay shown'

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
		for i in [0..Nodes.icons.length-1]
			Nodes.icons[i].className = 'icon faded-out'

	_showIcons = () ->
		for i in [0..Nodes.icons.length-1]
			Nodes.icons[i].className = 'icon'

	# Public.
	return {
		start            : start
		getCurrentCardId : () -> currentCardId
		getRotation      : () -> rotation
		getNumCards      : () -> numCards
	}
