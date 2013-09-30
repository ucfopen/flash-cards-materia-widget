# You're very, very special, IE.
Namespace('Flashcards').IE = do ->
	Nodes = {}

	pointer = window.navigator.msPointerEnabled
	upEventType = if pointer then "MSPointerUp" else "mouseup"
	
	start = ($container) ->
		# Applies special style for IE.
		document.getElementById('main').className = "IE"

		Nodes.clarification = document.getElementById 'clarification'

		# Inserts a container that will replace the back of all flashcards.
		_insertIEBack $container
		_addEventListeners()

	_insertIEBack = ($container) ->
		# References the back template.
		_tIEBack = $(document.getElementById('t-IE-back').innerHTML)

		# Inserts it after all flashcards have been inserted.
		$container.append _tIEBack.clone()

		Nodes.IEBack = document.getElementById 'IE-back'

	_addEventListeners = () ->
		document.addEventListener upEventType, _handleUpEvent
		document.addEventListener 'keydown', (e) ->
			switch e.keycode
				when 37, 39 then _handleCardShift()
				when 40     then _handleDiscard()
				when 32, 70 then _handleCardFlip()
				when 82     then _handleRotate()
				when 83     then _handleShuffle()
				when 85     then _handleRestore()
			e.preventDefault()

		Hammer(document).on 'swiperight', -> _handleCardShift()
		Hammer(document).on 'swipeleft',  -> _handleCardShift()

	_handleUpEvent = (event) ->
		switch event.target.id
			when "left-button", "right-button" then _handleCardShift()

			when 'shuffle-icon' then _handleShuffle()
			when 'restore-icon' then _handleRestore()
			when 'rotate-icon'  then _handleRotate()

			when "IE-back" then _flipCard()

		switch event.target.className
			when "front", "back", "title", "description", "container", "content"

				_handleCardFlip()
			when 'remove-button' then _handleDiscard()

	_handleCardShift = () ->
		_rotation = Flashcards.Engine.getRotation()
		_curCard  = Flashcards.Card[Flashcards.Engine.getCurrentCardId()].node
		if _rotation is '' then _specialFlipHide _curCard
		else setTimeout ->
			_specialFlipShow _curCard
		, 400

	_handleCardFlip = () ->
		_rotation = Flashcards.Engine.getRotation()
		_curCard  = Flashcards.Card[Flashcards.Engine.getCurrentCardId()].node

		if _curCard.className is 'flashcard rotated' then _specialFlipHide _curCard
		else _specialFlipShow _curCard

	_handleDiscard = () ->
		if Flashcards.Engine.getNumCards() is 0 then _hideIEBack()

	_handleShuffle = () ->
		_showClarification 'Shuffling...'
		_fadeIEBack 1500

		setTimeout ->
			_rotation = Flashcards.Engine.getRotation()
			_curCard  = Flashcards.Card[Flashcards.Engine.getCurrentCardId()].node

			_specialFlipShow _curCard
		, 1500

	_handleRestore = () ->
		_showClarification 'Restoring...'
		_fadeIEBack 700
		
	_handleRotate = () ->
		_showClarification 'Rotating...'
		_fadeIEBack 1200
		if rotation isnt '' then _showIEBack()

		setTimeout ->
			_rotation = Flashcards.Engine.getRotation()
			_curCard  = Flashcards.Card[Flashcards.Engine.getCurrentCardId()].node

			if _rotation is '' then _specialFlipHide _curCard else _specialFlipShow _curCard
		, 1400

	_specialFlipShow = (currentCard) ->
		Nodes.IEBack.children[0].innerHTML = currentCard.children[1].children[0].innerHTML

		currentCard.className = "flashcard rotated"
		Nodes.IEBack.className = "rotated"

	_specialFlipHide = (currentCard) ->
		# Hides the back.
		Nodes.IEBack.className = ''
		currentCard.className = 'flashcard'

	_hideIEBack = () -> Nodes.IEBack.className = ''
	_showIEBack = () -> Nodes.IEBack.className = 'rotated'

	_fadeIEBack = (time) ->
		Nodes.IEBack.style.opacity = "0"
		setTimeout ->
			Flashcards.IE.Nodes.IEBack.style.opacity = "1"
		, time

	_showClarification = (string) ->
		Nodes.clarification.innerHTML = string
		setTimeout ->
			Flashcards.IE.Nodes.clarification.innerHTML = ''
		, 800

	# Public.
	return {
		Nodes          : Nodes
		handleCardFlip : _handleCardFlip
		start          : start
	}

