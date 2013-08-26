Namespace('flashcards').Engine = do ->
	# DOM Elements
	$container    = null
	gameboard     = null
	flashcards    = null
	leftArrow     = null
	rightArrow    = null
	helpOverlay   = null
	shuffleIcon   = null
	rotateIcon    = null
	helpIcon      = null
	discardOptns  = null
	finishMssg    = null

	# Logical variables.
	cardData      = []
	discardedIds  = []
	currentCardId = 0
	numCards      = null
	numDiscard    = null
	animating     = false
	buffer        = false
	rotation      = ''
	timer         = null

	# Environmental conditions.
	_ms     = window.navigator.msPointerEnabled
	_mobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/

	downEventType = switch
		when _ms     then "MSPointerDown"
		when _mobile then "touchstart"
		else              "mousedown"
	moveEventType = switch
		when _ms     then "MSPointerMove"
		when _mobile then "touchmove"
		else              "mousemove"
	upEventType = switch
		when _ms     then "MSPointerUp"
		when _mobile then "touchend"
		else              "mouseup"
	enterEventType = switch
		when _ms     then "MSPointerEnter"
		when _mobile then "touchstart"
		else              "mouseenter"
	leaveEventType = switch
		when _ms     then "MSPointerLeave"
		when _mobile then "touchend"
		else              "mouseleave"

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

	# Copies the qset cards into an array.
	_storeCards = (data) ->
		numCards   = data.length
		numDiscard = 0
		for i in [0..numCards-1]
			cardData[i]             = {}
			cardData[i].term        = data[i].answers[0].text
			cardData[i].description = data[i].questions[0].text
			cardData[i].discarded   = false

	# Reference commonly accessed nodes.
	_cacheElements = () ->
		$container    = $('#container')
		gameboard     = document.getElementById('board')
		leftArrow     = document.getElementById('arrow-left')
		rightArrow    = document.getElementById('arrow-right')
		helpOverlay   = document.getElementById('overlay')
		shuffleIcon   = document.getElementById('shuffle-icon')
		rotateIcon    = document.getElementById('rotate-icon')
		helpIcon      = document.getElementById('help-icon')
		discardOptns  = document.getElementById('discard-options')
		finishMssg    = document.getElementById('finished')

	# Some elements need to be referenced after the board is drawn.
	_cacheLateElements = () ->
		flashcards = document.getElementsByClassName('flashcard')

	_addEventListeners = () ->
		if _mobile
			document.addEventListener enterEventType, (e) -> e.preventDefault()
			document.addEventListener leaveEventType, (e) -> e.preventDefault()
			Hammer(document).on 'swiperight', -> if _canMove('left') then _shiftCards('right')
			Hammer(document).on 'swipeleft', -> if _canMove('right') then _shiftCards('left')
			Hammer(document).on 'swipedown', -> _discard()
			Hammer(document).on 'swipeup', -> _shuffleCards()
			Hammer(document).on 'tap', (e) -> _handleUpEvent(e)
			Hammer(document).on 'rotate', -> _rotateCards(if rotation is '' then 'back')
		else
			# Handles keyboard interaction.
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

			document.addEventListener upEventType, (e) ->
				_handleUpEvent(e)

		document.addEventListener downEventType, (e) ->
			element = e.target

			switch element.id
				when "left-button" then leftArrow.className   = 'arrow shown'
				when "right-button" then rightArrow.className = 'arrow shown'

	# Draws the gameboard.
	_drawBoard = (title) ->
		document.getElementById('instance-title').innerHTML = title

		_tFlashcard = $($('#t-flashcard').html())
		$container.append(_tFlashcard.clone()) for i in [0..numCards-1]

	_handleUpEvent = (event) ->
		element = event.target

		switch element.id
			when "left-button" then if _canMove('left') then _shiftCards('right')
			when "right-button" then if _canMove('right') then _shiftCards('left')
			when "shuffle-icon" then _shuffleCards()
			when "rotate-icon"
				if rotation is '' then _rotateCards('back') else _rotateCards()
			when "help-button" then _toggleOverlay()
			when "restart" then _unDiscardAll()

		switch element.className
			when "front", "back", "title", "description", "container"
				if element.parentNode.className == 'flashcard discarded' || element.parentNode.parentNode.className == 'flashcard discarded'
					_unDiscard()
				else _flipCard()
			when "remove" then _discard()
			when "restore" then _unDiscardAll()

	# Populates the each card with terms and definitions.
	_setCardData = () ->
		j = 0
		for i in [0..numCards-1]
			if flashcards[i].className != 'flashcard discarded'
				j++ while cardData[j].discarded

				flashcards[i].children[0].children[0].innerHTML = cardData[j].term
				flashcards[i].children[1].children[0].innerHTML = cardData[j].description

				j++

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0..numCards-1]
				if flashcards[i].className != 'flashcard discarded'
					if i is currentCardId then flashcards[i].className     = 'flashcard shown rotated'
					else if i < currentCardId then flashcards[i].className = 'flashcard left-rotated'
					else if i > currentCardId then flashcards[i].className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0..numCards-1]
				if flashcards[i].className != 'flashcard discarded'
					if i is currentCardId then flashcards[i].className     = 'flashcard shown'
					else if i < currentCardId then flashcards[i].className = 'flashcard left'
					else if i > currentCardId then flashcards[i].className = 'flashcard right'

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

			if rolling != 'non-rolling'
				while (true)
					currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1
					if flashcards[currentCardId].className != 'flashcard discarded' then break
			else currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1
			
			flashcards[currentCardId].className = 'flashcard shown '+(if rotation is '' then '' else 'rotated')

			_setArrowState()

	# Shows or hides directional arrows depending on what cards are viewable.
	_setArrowState = () ->
		if _canMove('right') then rightArrow.className = 'arrow shown' else rightArrow.className = 'arrow'
		if _canMove('left') then leftArrow.className = 'arrow shown' else leftArrow.className = 'arrow'

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if flashcards[currentCardId].className != 'flashcard discarded'
			if flashcards[currentCardId].className is 'flashcard shown rotated'
				flashcards[currentCardId].className = 'flashcard shown'
			else 
				flashcards[currentCardId].className = 'flashcard shown rotated'

	# Shuffles the entire deck.
	_shuffleCards = () ->
		if numDiscard < numCards
			if not animating
				animating = true
				setTimeout ->
					animating = false
				, 1000

				if flashcards[currentCardId].className != 'flashcard discarded'
					flashcards[currentCardId].className = if rotation is '' then 'flashcard shuffled' else 'flashcard shuffled-rotated'
				shuffleIcon.className = 'icon focused'

				setTimeout ->
					cardData = _shuffle(cardData)
					_setCardData()
					_setCardPositions(if rotation is '' then null else 'reverse')
					shuffleIcon.className = 'icon'
				, 500

	# Shuffles an array.
	_shuffle = (a) ->
		for i in [a.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[a[i], a[j]] = [a[j], a[i]]
		a

	# Triggers the illustration for rotating the cards en masse.
	_rotateCards = (face = null) ->
		if numDiscard != numCards
			if not animating
				animating = true

				rotateIcon.className = 'icon focused'
				_rotation            = if rotation is '' then '' else '-rotated'
				_reverseRotation     = if rotation is '' then '-rotated' else ''

				for i in [-2..2]
					if flashcards[currentCardId+i]?
						if flashcards[currentCardId+i].className != 'flashcard discarded'
							flashcards[currentCardId+i].className = 'flashcard stage-'+(i+2)+_rotation
				setTimeout ->
					j = 0
					timer = setInterval ->
						if flashcards[currentCardId+(j-2)]?
							if flashcards[currentCardId+(j-2)].className != 'flashcard discarded'
								flashcards[currentCardId+(j-2)].className = 'flashcard stage-'+j+_reverseRotation
						if j < 4 then j++
					, 100
				, 600

				setTimeout ->
					animating = false
					clearInterval(timer)
					if face is 'back'
						_setCardPositions('reverse')
					else
						_setCardPositions()
					rotateIcon.className = 'icon'
				, 1400

	# Moves the current card into the discard pile.
	_discard = () ->
		if numDiscard < numCards
			numDiscard++

			if numDiscard is 2 then _showDiscardOptions()

			discardedIds.push(currentCardId)
			cardData[currentCardId].discarded = true

			flashcards[currentCardId].className = 'flashcard discarded'

			tempId = currentCardId
			while tempId != 0
				tempId--
				if flashcards[tempId].className != 'flashcard discarded'
					_shiftCards('right')
					return
			tempId = currentCardId
			while tempId != numCards-1
				tempId++
				if flashcards[tempId].className != 'flashcard discarded'
					_shiftCards('left')
					return
			if numDiscard is numCards then _displayFinish(); discardOptns.className = ''

			_setArrowState()

	# Moves the last discarded card back into the active deck.
	_unDiscard = () ->
		if !buffer
			buffer = true
			setTimeout ->
				buffer = false
			, 100

			if numDiscard > 0 && numDiscard != numCards
				numDiscard--
				_id        = discardedIds.pop()                              # The ID of the card on top the discard stack.
				_dif       = Math.abs(currentCardId-_id)                     # The absolute value of the difference of the two IDs.
				_direction = if _id > currentCardId then 'right' else 'left' # The direction of the last discard relative to the current card.

				for i in [0..numCards-1]
					if flashcards[_id].children[0].children[0].innerHTML == cardData[i].term
						cardData[i].discarded = false
						break

				flashcards[_id].className = 'flashcard '+_direction
				for i in [0.._dif-1]
					_shiftCards((if _direction is 'right' then 'left' else 'right'), 'non-rolling') 
				_setArrowState()

				if numDiscard is 0 then _hideDiscardOptions()

	# Moves all discarded cards into the active deck.
	_unDiscardAll = () ->
		if numDiscard > 0
			if numDiscard is numCards then currentCardId = 0

			numDiscard = 0
			for i in [0..numCards-1]
				cardData[i].discarded   = false
				flashcards[i].className = 'flashcard right'
			_hideFinish()

			_reverseRotation = if rotation is '' then '-rotated' else ''
			for i in [-2..2]
				if flashcards[currentCardId+i]?
					flashcards[currentCardId+i].className = 'flashcard stage-'+(i+2)+rotation

			_hideDiscardOptions()

			setTimeout ->
				_setCardData()
				_setCardPositions(if rotation is '' then null else 'reverse')
				_setArrowState()
			, 800

	_showDiscardOptions = () ->
		discardOptns.className = 'shown'

	_hideDiscardOptions = () ->
		discardOptns.className = ''

	# Opens or closes a popup.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if helpOverlay.className is 'overlay shown'
				helpIcon.className = 'icon'
				gameboard.className = ''
				helpOverlay.className = 'overlay'
			else 
				helpIcon.className = 'icon focused'
				gameboard.className = 'blurred'
				helpOverlay.className = 'overlay shown'

	# Shows a finsh message.
	_displayFinish = () ->
		finishMssg.className = 'shown'

	# Hides a finish message.
	_hideFinish = () ->
		finishMssg.className = ''

	#public
	start: start
