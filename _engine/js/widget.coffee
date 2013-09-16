Namespace('Flashcards').Engine = do ->
	# DOM Elements
	$container    = null
	cardContainer = null
	gameboard     = null
	flashcards    = null
	leftArrow     = null
	rightArrow    = null
	helpOverlay   = null
	icons         = null
	discardOptns  = null
	finishMssg    = null
	restoreIcon   = null

	# Logical variables.
	cardData      = []
	discardedIds  = []
	currentCardId = 0
	numCards      = null
	numDiscard    = null
	animating     = false
	buffer        = false
	overlay       = false
	rotation      = ''
	timer         = null

	# Environmental conditions.
	isMobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/
	isIE     = /MSIE (\d+\.\d+);/.test(navigator.userAgent)
	pointer  = window.navigator.msPointerEnabled

	downEventType = switch
		when pointer  then "MSPointerDown"
		when isMobile then "touchstart"
		else               "mousedown"
	moveEventType = switch
		when pointer  then "MSPointerMove"
		when isMobile then "touchmove"
		else               "mousemove"
	upEventType = switch
		when pointer  then "MSPointerUp"
		when isMobile then "touchend"
		else               "mouseup"
	enterEventType = switch
		when pointer  then "MSPointerOver"
		else               "mouseover"
	leaveEventType = switch
		when pointer  then "MSPointerOut"
		when isMobile then "touchend"
		else               "mouseout"

	# Called by Materia.Engine when widget Engine should start the UI.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_cacheElements()
		_storeCards(qset.items[0].items)
		_drawBoard(instance.name)
		_cacheLateElements()
		_setCardData()
		_setCardPositions()
		_addEventListeners()

		if isIE then Flashcards.IE.start($container)

	# Reference commonly accessed nodes.
	_cacheElements = () ->
		cardContainer = document.getElementById('container')
		gameboard     = document.getElementById('board')
		leftArrow     = document.getElementById('arrow-left')
		rightArrow    = document.getElementById('arrow-right')
		helpOverlay   = document.getElementById('overlay')
		icons         = document.getElementsByClassName('icon')
		discardOptns  = document.getElementById('discard-options')
		finishMssg    = document.getElementById('finished')
		restoreIcon   = document.getElementById('restore-icon')

		$container    = $(cardContainer)

	# Copies the qset cards into an array.
	_storeCards = (data) ->
		numCards   = data.length
		numDiscard = 0
		for i in [0..numCards-1]
			cardData[i] = {}

			_ansClass = if data[i].answers[0].text.split(' ').length < 8 then "title" else "description"
			_queClass = if data[i].questions[0].text.split(' ').length < 8 then "title" else "description"
			if data[i].answers[0].text is 'None'
				_ansUrl = Materia.Engine.getMediaUrl(data[i].assets[0])
				cardData[i].term = '<img class="'+_ansClass+'" src="'+_ansUrl+'">'
			else 
				cardData[i].term = '<p class="'+_ansClass+'">'+data[i].answers[0].text+'</p>'

			if data[i].answers[0].text is 'None'
				_queUrl = Materia.Engine.getMediaUrl(data[i].assets[1])
				cardData[i].description = '<img class="'+_queClass+'" src="'+_queUrl+'">'
			else
				cardData[i].description = '<p class="'+_queClass+'">'+data[i].questions[0].text+'</p>'

			cardData[i].discarded = false

	# Draws the gameboard.
	_drawBoard = (title) ->
		document.getElementById('instance-title').innerHTML = title

		_tFlashcard = $($('#t-flashcard').html())
		_tRestore   = $($('#t-restore-icon').html())
		$container.append(_tFlashcard.clone()) for i in [0..numCards-1]

	# Some elements need to be referenced after the board is drawn.
	_cacheLateElements = () ->
		flashcards = document.getElementsByClassName('flashcard')

	# Populates the each card with terms and definitions.
	_setCardData = () ->
		j = 0
		for i in [0..numCards-1]
			# Disallow discarded card Divs to be populated with active data.
			if flashcards[i].className != 'flashcard discarded'
				# Disallow discarded terms to be included in an active card.
				j++ while cardData[j].discarded

				flashcards[i].children[0].children[0].innerHTML = cardData[j].description 
				flashcards[i].children[1].children[0].innerHTML = cardData[j].term

				# Natually increment.
				j++

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0..numCards-1]
				if flashcards[i].className != 'flashcard discarded'
					if i is currentCardId     then flashcards[i].className = 'flashcard shown rotated'
					else if i < currentCardId then flashcards[i].className = 'flashcard left-rotated'
					else if i > currentCardId then flashcards[i].className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0..numCards-1]
				if flashcards[i].className != 'flashcard discarded'
					if i is currentCardId     then flashcards[i].className = 'flashcard shown'
					else if i < currentCardId then flashcards[i].className = 'flashcard left'
					else if i > currentCardId then flashcards[i].className = 'flashcard right'

	_addEventListeners = () ->
		if isMobile
			document.addEventListener 'touchstart', (e) -> e.preventDefault()
			document.addEventListener 'touchend', (e) -> e.preventDefault()
			Hammer(document).on 'swiperight', -> if _canMove('left') then _shiftCards('right')
			Hammer(document).on 'swipeleft', -> if _canMove('right') then _shiftCards('left')
			Hammer(document).on 'swipedown', -> _discard()
			Hammer(document).on 'swipeup', -> _shuffleCards()
			Hammer(document).on 'tap', (e) -> _handleUpEvent(e)
			Hammer(document).on 'rotate', -> _rotateCards(if rotation is '' then 'back')
		else
			document.addEventListener upEventType, (e) -> _handleUpEvent(e)
			window.addEventListener 'keydown', (e) ->
				switch e.keyCode
					when 37 then if _canMove('left') then _shiftCards('right') # Left arrow key.
					when 38 then _unDiscard()                                  # Up arrow key.
					when 39 then if _canMove('right') then _shiftCards('left') # Right arrow key.
					when 40 then _discard()                                    # Down arrow key.
					when 32, 70 then _flipCard()                               # F key and space bar.
					when 72 then _toggleOverlay()                              # H key.
					when 82 then _rotateCards(if rotation is '' then 'back')   # R key.
					when 83 then _shuffleCards()                               # S key.
					when 85 then _unDiscardAll()                               # U key.
				e.preventDefault()

			document.addEventListener enterEventType, _handleEnterEvent
			document.addEventListener leaveEventType, _handleLeaveEvent

		document.addEventListener downEventType, (e) ->
			element = e.target

			switch element.id
				when "left-button" then leftArrow.className   = 'arrow shown'
				when "right-button" then rightArrow.className = 'arrow shown'

	_handleEnterEvent = (event) ->
		element = event.target

		switch element.className
			when "front", "back", "title", "description", "container", "content"
				if element.parentNode.className is 'flashcard discarded' or element.parentNode.parentNode is 'flashcard discarded'
					restoreIcon.className = "shown"
				    # TODO: FIX THIS

		console.log element.id
		switch element.id
			when "discard-options", "restore-button" then _restoreAllAnim()

	_handleLeaveEvent = (event) ->
		element = event.target

		switch element.className
			when "front", "back", "title", "description", "container", "content"
				if element.parentNode.className is 'flashcard discarded'
					restoreIcon.className = ""
					# TODO: FIX THIS

		switch element.id
			when "discard-options", "restore-button" then _removeRestoreAllAnim()

	_handleUpEvent = (event) ->
		element = event.target
		console.log element

		switch element.id
			when "left-button" then if _canMove('left') then _shiftCards('right')
			when "right-button" then if _canMove('right') then _shiftCards('left')
			when "shuffle-icon" then _shuffleCards()
			when "rotate-icon"
				if rotation is '' then _rotateCards('back') else _rotateCards()
			when "help-button" then _toggleOverlay()
			when "restart" then _unDiscardAll()
			when "IE-back" then _flipCard()

		console.log element.className
		switch element.className
			# A face of the current card has been clicked/touched
			when "front", "back", "title", "description", "container", "content"
				if element.parentNode.className == 'flashcard discarded' || element.parentNode.parentNode.className == 'flashcard discarded' || element.parentNode.parentNode.parentNode.className == 'flashcard discarded'
					_unDiscard()
				else _flipCard()
			when 'flashcard shown rotated' then _flipCard()
			when "remove" then _discard()
			when "restore" then _unDiscardAll()

	# Asseses which direction has accessable cards.
	_canMove = (direction) ->
		tempId = currentCardId
		if direction is 'left'
			if tempId is 0 then return false
			while tempId > 0
				tempId--
				if flashcards[tempId].className == 'flashcard discarded' then continue
				else return true
			return false
		else if direction is 'right'
			if tempId is numCards-1 then return false
			while tempId < numCards-1
				tempId++
				if flashcards[tempId].className == 'flashcard discarded' then continue
				else return true
			return false

	# Shift cards left or right depending on the which directional arrow has been pressed.
	_shiftCards = (direction, rolling = null) ->
		if not animating
			if flashcards[currentCardId].className != 'flashcard discarded'
				flashcards[currentCardId].className = 'flashcard '+direction+rotation

			# If we haven't specified that the shifting action is non-rolling
			# then roll over cards that have been discarded.
			if rolling != 'non-rolling'
				while (true)
					currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1
					if flashcards[currentCardId].className != 'flashcard discarded' then break
			else currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1

			flashcards[currentCardId].className = 'flashcard shown '+(if rotation is '' then '' else 'rotated')

			_setArrowState()

			if isIE
				if rotation is '' then Flashcards.IE.specialFlipHide()
				else Flashcards.IE.specialFlipShow(flashcards[currentCardId], cardData)

	# Shows or hides directional arrows depending on what cards are viewable.
	_setArrowState = () ->
		if _canMove('right') then rightArrow.className = 'arrow shown' else rightArrow.className = 'arrow'
		if _canMove('left') then leftArrow.className = 'arrow shown' else leftArrow.className = 'arrow'

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if flashcards[currentCardId].className != 'flashcard discarded'
			if flashcards[currentCardId].className is 'flashcard shown rotated'
				flashcards[currentCardId].className = 'flashcard shown'
				if isIE then Flashcards.IE.specialFlipHide()
			else
				flashcards[currentCardId].className = 'flashcard shown rotated'
				if isIE then Flashcards.IE.specialFlipShow(flashcards[currentCardId], cardData)


	# Shuffles the entire deck.
	_shuffleCards = () ->
		if numDiscard < numCards
			if not animating
				animating = true
				setTimeout ->
					animating = false
				, 1000

				# Start the animation.
				if flashcards[currentCardId].className != 'flashcard discarded'
					flashcards[currentCardId].className = if rotation is '' then 'flashcard shuffled' else 'flashcard shuffled-rotated'
				
				icons[0].className = 'icon focused' # Focus the shuffle icon.

				# Shuffle and reset the card data, then conclude the animation.
				setTimeout ->
					cardData = _shuffle(cardData)
					_setCardData()
					_setCardPositions(if rotation is '' then null else 'reverse')
					icons[0].className = 'icon'
				, 500

	# Shuffles an array.
	_shuffle = (arr) ->
		for i in [arr.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[arr[i], arr[j]] = [arr[j], arr[i]]
		arr

	# Triggers the illustration for rotating the cards en masse.
	_rotateCards = (face = null) ->
		if numDiscard != numCards
			if not animating
				animating = true

				icons[1].className = 'icon focused' # Focus the rotate icon.

				_rotation            = if rotation is '' then '' else '-rotated'
				_reverseRotation     = if rotation is '' then '-rotated' else ''

				# Access 5 flashcards: two from the left, the current card, and two from the right.
				for i in [-2..2]
					if flashcards[currentCardId+i]?
						if flashcards[currentCardId+i].className != 'flashcard discarded'
							flashcards[currentCardId+i].className = 'flashcard stage-'+(i+2)+_rotation

				# At this point, the flashcards are staged and must be given a rotation animation.
				setTimeout ->
					j = 0 # A counter to allot staging positions to cards.
					timer = setInterval ->
						if flashcards[currentCardId+(j-2)]?
							if flashcards[currentCardId+(j-2)].className != 'flashcard discarded'
								flashcards[currentCardId+(j-2)].className = 'flashcard stage-'+j+_reverseRotation
						if j < 4 then j++
					, 100
				, 600

				# Now it's time to bring the flashcards back to their default positions.
				setTimeout ->
					animating = false
					clearInterval(timer)
					if face is 'back'
						_setCardPositions('reverse')
					else
						_setCardPositions()
					icons[1].className = 'icon'

					if isIE
						if rotation is '' then Flashcards.IE.specialFlipHide()
						else Flashcards.IE.specialFlipShow(flashcards[currentCardId], cardData)
				, 1400

	# Moves the current card into the discard pile.
	_discard = () ->
		if numDiscard < numCards
			numDiscard++

			if numDiscard is 2 then _showElement(discardOptns, true)

			# Store a record of the latest discard.
			discardedIds.push(currentCardId)
			cardData[currentCardId].discarded = true

			flashcards[currentCardId].className = 'flashcard discarded'

			if numDiscard is numCards
				_showElement(finishMssg, false)
				_hideElement(discardOptns, true)
				cardContainer.className = 'hidden'

			else
				# Search for an available card on the left of the deck to move to.
				tempId = currentCardId
				while tempId != 0
					tempId--
					if flashcards[tempId].className != 'flashcard discarded'
						_shiftCards('right')
						return

				# Search for an available card on the right of the deck to move to.
				tempId = currentCardId
				while tempId != numCards-1
					tempId++
					if flashcards[tempId].className != 'flashcard discarded'
						_shiftCards('left')
						return

			_setArrowState()

	# Moves the last discarded card back into the active deck.
	_unDiscard = () ->
		if not buffer
			buffer = true
			setTimeout ->
				buffer = false
			, 100

			if numDiscard > 0 && numDiscard != numCards
				numDiscard--
				_id        = discardedIds.pop()                              # The ID of the card on top the discard stack.
				_dif       = Math.abs(currentCardId-_id)                     # The absolute value of the difference of the two IDs.
				_direction = if _id > currentCardId then 'right' else 'left' # The direction of the last discard relative to the current card.

				# Find the card data for the term we are undiscarding and update it.
				for i in [0..numCards-1]
					if flashcards[_id].children[0].children[0].innerHTML is cardData[i].term
						cardData[i].discarded = false
						break

				# Animate the card out of the stack and into the deck, then shift to its position.
				flashcards[_id].className = 'flashcard '+_direction
				for i in [0.._dif-1]
					_shiftCards((if _direction is 'right' then 'left' else 'right'), 'non-rolling') 
				_setArrowState()

				if numDiscard < 2 then _hideElement(discardOptns, true)

	# Moves all discarded cards into the active deck.
	_unDiscardAll = () ->
		if numDiscard > 0

			_removeRestoreAllAnim()
			discardedIds = []

			# Reset discard data.
			if numDiscard is numCards then currentCardId = 0
			numDiscard = 0
			for i in [0..numCards-1]
				cardData[i].discarded   = false
				flashcards[i].className = 'flashcard right'

			# Remove all cards from discard pile and stage them.
			_reverseRotation = if rotation is '' then '-rotated' else ''
			for i in [-2..2]
				if flashcards[currentCardId+i]?
					flashcards[currentCardId+i].className = 'flashcard stage-'+(i+2)+rotation

			_hideElement(finishMssg, false)
			_hideElement(discardOptns, true)
			cardContainer.className = ''

			# Set all default card data and return cards to default positions.
			setTimeout ->
				_setCardData()
				_setCardPositions(if rotation is '' then null else 'reverse')
				_setArrowState()
			, 800

	_restoreAllAnim = () ->
		console.log 'here'
		for i in [0..discardedIds.length-1]
			flashcards[discardedIds[i]].className = "flashcard discarded-moved-"+i
			if i is 2 then break

	_removeRestoreAllAnim = () ->
		for i in [0..discardedIds.length-1]
			flashcards[discardedIds[i]].className = "flashcard discarded"
			if i is 2 then break

	# Opens or closes the help overlay.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if helpOverlay.className is 'overlay shown'
				icons[2].className    = 'icon'
				gameboard.className   = ''
				helpOverlay.className = 'overlay'
			else 
				icons[2].className    = 'icon focused'
				gameboard.className   = 'blurred'
				helpOverlay.className = 'overlay shown'

	# Adds a shown class to a variable amount of elements.
	_showElement = (elem, fadeIn) ->
		elem.className = 'shown'

		if fadeIn then setTimeout ->
			elem.className = 'shown faded-in'
		, 5

	# Removes all classes from a variable amount of elements.
	_hideElement = (elem, fadeIn) ->
		if fadeIn then elem.className = "shown"
		else elem.className = ""; return;

		setTimeout ->
			elem.className = ""
		, 200

	#public
	start : start
