Namespace('Flashcards').Card        = []
Namespace('Flashcards').DiscardPile = []

# You're very, very special, IE.
Namespace('Flashcards').IE = 
	nodes : {}
	
	start : ($container) ->
		# Applies special style for IE.
		document.getElementById('main').className = "IE"

		# Inserts a container that will replace the back of all flashcards.
		this.insertIEBack($container)

	insertIEBack : ($container) ->
		# References the back template.
		_tIEBack = $(document.getElementById('t-IE-back').innerHTML)

		# Inserts it after all flashcards have been inserted.
		$container.append(_tIEBack.clone())

		this.nodes.IEBack = document.getElementById('IE-back')

	specialFlipShow : (currentCard) ->
		# Shows the back when the card has been flipped.
		this.nodes.IEBack.className = 'shown'
		this.nodes.IEBack.children[0].innerHTML = currentCard.children[1].children[0].innerHTML

	specialFlipHide : () ->
		# Hides the back.
		Flashcards.IE.nodes.IEBack.className = ''

Namespace('Flashcards').Engine = do ->
	# DOM Elements.
	Nodes = {}

	# Logical variables.
	discardedIds  = []
	currentCardId = 0
	numCards      = null
	numDiscard    = null
	animating     = false
	buffer        = false
	overlay       = false
	rotation      = ''
	timer         = null
	noCards       = false

	# Environmental conditions.
	isMobile = navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/
	isIE     = /MSIE (\d+\.\d+);/.test(navigator.userAgent)
	pointer  = window.navigator.msPointerEnabled

	# If a user has touch and mouse capabilities, make sure we don't 
	# restrict them to a mobile environment.
	if pointer then isMobile = false

	downEventType = switch
		when pointer  then "MSPointerDown"
		when isMobile then "touchstart"
		else               "mousedown"
	upEventType = switch
		when pointer  then "MSPointerUp"
		else               "mouseup"
	enterEventType = switch
		when pointer  then "MSPointerOver"
		else               "mouseover"
	leaveEventType = switch
		when pointer  then "MSPointerOut"
		else               "mouseout"

	# Called by Materia.Engine when widget Engine should start the UI.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_cacheNodes()
		_drawBoard(instance.name, qset.items[0].items.length)
		_storeCards(qset.items[0].items)
		_setCardData()
		_setCardPositions()
		_addEventListeners()

		if isIE then Flashcards.IE.start(Nodes.$container)

	# Reference commonly accessed nodes.
	_cacheNodes = () ->
		Nodes.container    = document.getElementById('container')
		Nodes.gameboard    = document.getElementById('board')
		Nodes.leftArrow    = document.getElementById('arrow-left')
		Nodes.rightArrow   = document.getElementById('arrow-right')
		Nodes.helpOverlay  = document.getElementById('overlay')
		Nodes.icons        = document.getElementsByClassName('icon')
		Nodes.discardOptns = document.getElementById('discard-options')
		Nodes.finishMssg   = document.getElementById('finished')
		Nodes.restoreText  = document.getElementById('restore-text')

		Nodes.$container   = $(Nodes.container)

	# Draws the gameboard.
	_drawBoard = (title, length) ->
		document.getElementById('instance-title').innerHTML = title

		_tFlashcard = $($('#t-flashcard').html())
		Nodes.$container.append(_tFlashcard.clone()) for i in [0..length-1]

	# Copies the qset cards into an array.
	_storeCards = (data) ->
		numCards = data.length
		_cardNodes = document.getElementsByClassName('flashcard')

		for i in [0..numCards-1]
			Flashcards.Card.push({})

			# Decide if the text will be presented as a term or description based upon length.
			_ansClass = if data[i].answers[0].text.split(' ').length < 8   then "title" else "description"
			_queClass = if data[i].questions[0].text.split(' ').length < 8 then "title" else "description"

			Flashcards.Card[i].discarded = false
			Flashcards.Card[i].node      = _cardNodes[i]
			Flashcards.Card[i].FrontText = data[i].answers[0].text
			Flashcards.Card[i].BackText  = data[i].questions[0].text
			
			# Handle image assets if they are used.
			if data[i].answers[0].text is 'None'
				_ansUrl = Materia.Engine.getMediaUrl(data[i].assets[0])
				Flashcards.Card[i].frontHTML = '<img class="'+_ansClass+'" src="'+_ansUrl+'">'
			else 
				Flashcards.Card[i].frontHTML = '<p class="'+_ansClass+'">'+data[i].answers[0].text+'</p>'

			if data[i].answers[0].text is 'None'
				_queUrl = Materia.Engine.getMediaUrl(data[i].assets[1])
				Flashcards.Card[i].backHTML = '<img class="'+_queClass+'" src="'+_queUrl+'">'
			else
				Flashcards.Card[i].backHTML = '<p class="'+_queClass+'">'+data[i].questions[0].text+'</p>'

	# Populates the each card with terms and definitions.
	_setCardData = () ->
		for i in [0..numCards-1]
			Flashcards.Card[i].node.children[0].children[0].innerHTML = Flashcards.Card[i].frontHTML
			Flashcards.Card[i].node.children[1].children[0].innerHTML = Flashcards.Card[i].backHTML

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0..numCards-1]
				if not Flashcards.Card[i].discarded
					if i is currentCardId     then Flashcards.Card[i].node.className = 'flashcard shown rotated'
					else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left-rotated'
					else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0..numCards-1]
				if not Flashcards.Card[i].discarded
					if i is currentCardId     then Flashcards.Card[i].node.className = 'flashcard shown'
					else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left'
					else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right'

	_addEventListeners = () ->
		window.onscroll = -> window.scrollTo(0,0)
		if isMobile
			document.addEventListener 'click', (e) ->      e.stopPropagation()
			document.addEventListener 'touchstart', (e) -> e.preventDefault()
			document.addEventListener 'touchend', (e) ->   _handleUpEvent(e)
			Hammer(document).on 'swiperight', ->           if _canMove('left')  then _shiftCards('right', true)
			Hammer(document).on 'swipeleft', ->            if _canMove('right') then _shiftCards('left', true)
			Hammer(document).on 'swipedown', ->            _discard()
			Hammer(document).on 'swipeup', ->              _shuffleCards()
			Hammer(document).on 'rotate', ->               _rotateCards(if rotation is '' then 'back')
		else
			document.addEventListener enterEventType, (e) -> _handleEnterEvent(e)
			document.addEventListener leaveEventType, (e) -> _handleLeaveEvent(e)
			document.addEventListener upEventType, (e) ->    _handleUpEvent(e)
			window.addEventListener 'keydown', (e) ->
				switch e.keyCode
					when 37 then if  _canMove('left')  then _shiftCards('right') # Left arrow key.
					when 38 then     _unDiscard()                                # Up arrow key.
					when 39 then if  _canMove('right') then _shiftCards('left')  # Right arrow key.
					when 40 then     _discard()                                  # Down arrow key.
					when 32, 70 then _flipCard()                                 # F key and space bar.
					when 72 then     _toggleOverlay()                            # H key.
					when 82 then     _rotateCards(if rotation is '' then 'back') # R key.
					when 83 then     _shuffleCards()                             # S key.
					when 85 then     _unDiscardAll()                             # U key.
				e.preventDefault()

	_handleEnterEvent = (event) ->
		element = event.target

		switch element.tagName
			when "SECTION" then _hideRestoreMssg()

		switch element.className
			when "front"
				if      _isDiscarded(element.parentNode)                       then if not noCards then _showRestoreMssg()
				else if _isDiscarded(element.parentNode.parentNode.parentNode) then if not noCards then _showRestoreMssg()

	_handleLeaveEvent = (event) ->
		element = event.target

	_handleUpEvent = (event) ->
		element = event.target

		switch element.id
			when "left-button"  then if _canMove('left')  then _shiftCards('right')
			when "right-button" then if _canMove('right') then _shiftCards('left')
			when "shuffle-icon" then _shuffleCards()
			when "help-button"  then _toggleOverlay()
			when "restart"      then _unDiscardAll()
			when "IE-back"      then _flipCard()
			when "rotate-icon"
				if rotation is '' then _rotateCards('back') else _rotateCards()

		switch element.className
			# A face of the current card has been clicked/touched
			when "front", "back", "title", "description", "container", "content"
				if      _isDiscarded(element.parentNode)                       then _unDiscard()
				else if _isDiscarded(element.parentNode.parentNode.parentNode) then _unDiscard()
				else    _flipCard()
			when 'flashcard shown rotated' then _flipCard()
			when "remove"                  then _discard()
			when "restore"                 then _unDiscardAll(); _hideRestoreMssg();

	# Asseses which direction has accessable cards.
	_canMove = (direction) ->
		tempId = currentCardId
		if direction is 'left'
			if tempId is 0 then return false
			while tempId > 0
				tempId--
				if Flashcards.Card[tempId].discarded then continue
				else return true
			return false
		else if direction is 'right'
			if tempId is numCards-1 then return false
			while tempId < numCards-1
				tempId++
				if Flashcards.Card[tempId].discarded then continue
				else return true
			return false

	# Shift cards left or right depending on the which directional arrow has been pressed.
	_shiftCards = (direction, rolling = true) ->
		if not animating
			if not Flashcards.Card[currentCardId].discarded
				Flashcards.Card[currentCardId].node.className = 'flashcard '+direction+rotation

			# If we haven't specified that the shifting action is non-rolling
			# then roll over cards that have been discarded.
			if rolling 
				while true
					currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1
					if not Flashcards.Card[currentCardId].discarded then break
			else currentCardId = if direction is 'left' then currentCardId+1 else currentCardId-1

			if not Flashcards.Card[currentCardId].discarded
				Flashcards.Card[currentCardId].node.className = "flashcard shown "+(if rotation is '' then '' else 'rotated')

			_setArrowState()

			if isIE
				if rotation is '' then Flashcards.IE.specialFlipHide()
				else Flashcards.IE.specialFlipShow(Flashcards.Card[currentCardId].node)

	_isDiscarded = (flashcard) ->
		if flashcard.className.split(' ')[1]? && flashcard.className.split(' ')[1].split('-')[0]?
			return flashcard.className.split(' ')[1].split('-')[0] is 'discarded'

	_discardPosition = (flashcard) ->
		return _elemPos = Number(flashcard.className.split(' ')[1].split('-')[2])

	# Shows or hides directional arrows depending on what cards are viewable.
	_setArrowState = () ->
		if _canMove('right') then Nodes.rightArrow.className = 'arrow shown' else Nodes.rightArrow.className = 'arrow'
		if _canMove('left')  then Nodes.leftArrow.className  = 'arrow shown' else Nodes.leftArrow.className  = 'arrow'

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if not Flashcards.Card[currentCardId].discarded
			if Flashcards.Card[currentCardId].node.className is 'flashcard shown rotated'
				Flashcards.Card[currentCardId].node.className = 'flashcard shown'
				if isIE then Flashcards.IE.specialFlipHide()
			else
				Flashcards.Card[currentCardId].node.className = 'flashcard shown rotated'
				if isIE then Flashcards.IE.specialFlipShow(Flashcards.Card[currentCardId].node)

	# Shuffles the entire deck.
	_shuffleCards = () ->
		if numDiscard < numCards
			if not animating
				animating = true
				setTimeout ->
					animating = false
				, 1000

				# Start the animation.
				# if not Flashcards.Card[currentCardId].discarded
				Flashcards.Card[currentCardId].node.className = if rotation is '' then 'flashcard shuffled' else 'flashcard shuffled-rotated'
				
				Nodes.icons[0].className = 'icon focused' # Focus the shuffle icon.

				# Shuffle and reset the card data, then conclude the animation.
				setTimeout ->
					Flashcards.Card = _shuffle(Flashcards.Card)
					_setCardPositions(if rotation is '' then null else 'reverse')
					Nodes.icons[0].className = 'icon'
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

				Nodes.icons[1].className = 'icon focused' # Focus the rotate icon.

				_rotation        = if rotation is '' then '' else '-rotated'
				_reverseRotation = if rotation is '' then '-rotated' else ''

				# Access 5 flashcards: two from the left, the current card, and two from the right.
				for i in [-2..2]
					if Flashcards.Card[currentCardId+i]? && not Flashcards.Card[currentCardId+i].discarded
						Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-'+(i+2)+_rotation

				# At this point, the flashcards are staged and must be given a rotation animation.
				setTimeout ->
					j = 0 # A counter to allot staging positions to cards.
					timer = setInterval ->
						if Flashcards.Card[currentCardId+(j-2)]? && not Flashcards.Card[currentCardId+(j-2)].discarded
							Flashcards.Card[currentCardId+(j-2)].node.className = 'flashcard stage-'+j+_reverseRotation
						if j < 4 then j++
					, 100
				, 600

				# Now it's time to bring the flashcards back to their default positions.
				setTimeout ->
					animating = false
					clearInterval(timer)

					if face is 'back' then _setCardPositions('reverse')
					else                   _setCardPositions()

					Nodes.icons[1].className = 'icon'

					if isIE
						if rotation is '' then Flashcards.IE.specialFlipHide()
						else                   Flashcards.IE.specialFlipShow(Flashcards.Card[currentCardId].node)
				, 1400

	# Moves the current card into the discard pile.
	_discard = () ->
		if not animating
			if numDiscard < numCards
				numDiscard++

				if numDiscard is 0 then _hideRestoreMssg()

				# Store a record of the latest discard.
				discardedIds.push(currentCardId)
				Flashcards.Card[currentCardId].discarded = true

				# Animate the card into the discard pile.
				if discardedIds.length > 3 then Flashcards.Card[currentCardId].node.className = 'flashcard discarded-pos-3'
				else Flashcards.Card[currentCardId].node.className = 'flashcard discarded-pos-'+(discardedIds.length-1)

				# If the user has discarded the entire deck, prompt them to restore it.
				if numDiscard is numCards
					noCards = true
					_showElement(Nodes.finishMssg, false)
					_hideElement(Nodes.discardOptns, true)
					Nodes.container.className = 'hidden'

				# Move to a card that hasn't been discarded.
				else
					# Search for an available card on the left of the deck to move to.
					tempId = currentCardId
					while tempId != 0
						tempId--
						if not Flashcards.Card[tempId].discarded then _shiftCards('right', true); return

					# Search for an available card on the right of the deck to move to.
					tempId = currentCardId
					while tempId != numCards-1
						tempId++
						if not Flashcards.Card[tempId].discarded then _shiftCards('left', true); return

				_setArrowState()

	# Takes a card from the first array and places it in the second.
	_moveCardObject = (arr1, arr2, index) ->
		_tempArray = arr1
		arr2.push( _tempArray.splice(index, 1) )
		arr1 = _tempArray

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

				Flashcards.Card[_id].discarded = false

				# Animate the card out of the stack and into the deck, then shift to its position.
				Flashcards.Card[_id].node.className = 'flashcard ' + _direction
				for i in [0.._dif-1]
					_shiftCards((if _direction is 'right' then 'left' else 'right'), false)
				_setArrowState()

	# Moves all discarded cards into the active deck.
	_unDiscardAll = () ->
		if numDiscard > 0
			discardedIds = []

			noCards = false

			# Reset discard data.
			if numDiscard is numCards then currentCardId = 0
			numDiscard = 0
			for i in [0..numCards-1]
				Flashcards.Card[i].discarded      = false
				Flashcards.Card[i].node.className = "flashcard right"

			# Remove all cards from discard pile and stage them.
			_reverseRotation = if rotation is '' then '-rotated' else ''
			for i in [-2..2]
				if Flashcards.Card[currentCardId+i]?
					Flashcards.Card[currentCardId+i].node.className = 'flashcard stage-'+(i+2)+rotation

			_hideElement(Nodes.finishMssg, false)
			_hideElement(Nodes.discardOptns, true)
			Nodes.container.className = ''

			# Set all default card data and return cards to default positions.
			setTimeout ->
				_setCardPositions(if rotation is '' then null else 'reverse')
				_setArrowState()
			, 800

	_showRestoreMssg = () ->
		Nodes.restoreText.className = 'restore'

	_hideRestoreMssg = () ->
		Nodes.restoreText.className = 'restore hidden'

	# Opens or closes the help overlay.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if Nodes.helpOverlay.className is 'overlay shown'
				Nodes.icons[2].className    = 'icon'
				Nodes.gameboard.className   = ''
				Nodes.helpOverlay.className = 'overlay'
			else 
				Nodes.icons[2].className    = 'icon focused'
				Nodes.gameboard.className   = 'blurred'
				Nodes.helpOverlay.className = 'overlay shown'

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
