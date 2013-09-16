Namespace("Flashcards").Data =
	isMobile : navigator.userAgent.match /(iPhone|iPod|iPad|Android|BlackBerry)/
	isIE     : window.navigator.msPointerEnabled

	qset          : null   # Stores a reference to relevant qset data.
	numCards      : null   # The number of cards in the deck.
	numDiscard    : 0      # The number of cards currently discarded.
	currentCardId : 0      # The ID of the viewable card.
	discardedIds  : []     # IDs of the divs representing discarded cards.
	rotation      : ''     # Specifies the current default rotation for all cards.

	nodes         : {}     # Node references.

	card          : []     # Array of data for each card.

	gates :                # Stores control flow regulators.
		animating : false  # Stops events from happening mid-animating.
		buffer    : false  # Similar to animating but with a shorter lifespan.
		overlay   : false  # Tells us whether the overlay is shown or not.
		timer     : null   # 

	eventType : {}

	setEventType : () ->
		this.eventType.down = switch
			when this.isIE     then "MSPointerDown"
			when this.isMobile then "touchstart"
			else                    "mousedown"
		this.eventType.move = switch
			when this.isIE     then "MSPointerMove"
			when this.isMobile then "touchmove"
			else                    "mousemove"
		this.eventType.up = switch
			when this.isIE     then "MSPointerUp"
			when this.isMobile then "touchend"
			else                    "mouseup"
		this.eventType.enter = switch
			when this.isIE     then "MSPointerEnter"
			when this.isMobile then "touchmove"
			else                    "mouseenter"
		this.eventType.leave = switch
			when this.isIE     then "MSPointerLeave"
			when this.isMobile then "touchend"
			else                    "mouseleave"

	setData : (qset) ->
		this.qset = qset

	cacheNodes : () ->
		this.nodes.container    = document.getElementById('container')
		this.nodes.gameboard    = document.getElementById('board')
		this.nodes.leftArrow    = document.getElementById('arrow-left')
		this.nodes.rightArrow   = document.getElementById('arrow-right')
		this.nodes.helpOverlay  = document.getElementById('overlay')
		this.nodes.icons        = document.getElementsByClassName('icon')
		this.nodes.discardOptns = document.getElementById('discard-options')
		this.nodes.finishMssg   = document.getElementById('finished')

		# Needed for templating cards.
		this.nodes.$container    = $(container)

	# Cache important nodes that were inserted when templating.
	cacheLateNodes : () ->
		this.nodes.flashcards = document.getElementsByClassName('flashcard')

	storeCardData : () ->
		this.numCards = this.qset.length
		for i in [0..this.numCards-1]
			this.card[i] = {}
			this.card[i].term    = this.qset[i].answers[0].text
			this.card[i].defin   = this.qset[i].questions[0].text
			this.card[i].discard = false

	setCardData : () ->
		j = 0 # Represents an independent incrementor for card data.
		for i in [0..this.numCards-1]
			# If a node represents a discarded card, don't write to it.
			if this.nodes.flashcards[i].className != 'flashcard discarded'
				# Vice versa; Don't write any discarded data to a node.
				j++ while this.card[j].discard

				# Write to the front and back of the card.
				this.nodes.flashcards[i].children[0].children[0].innerHTML = this.card[j].term
				this.nodes.flashcards[i].children[1].children[0].innerHTML = this.card[j].defin

				j++

	shuffleCards : () ->
		if this.numDiscard < this.numCards
			_curNodeClass = this.nodes.flashcards[this.currentCardId].className
			if not this.animating
				this.animating = true
				setTimeout ->
					this.animating = false
				, 1000

				# Start the animation.
				if _curNodeClass != 'flashcard discarded'
					_curNodeClass = if this.rotation is '' then 'flashcard shuffled' else 'flashcard shuffled-rotated'
				
				this.nodes.icons[0].className = 'icon focused' # Focus the shuffle icon.

				# Shuffle and reset the card data, then conclude the animation.
				setTimeout ->
					card = _shuffle(card)
					this.setCardData()
					Flashcards.Engine.setCardPositions(if this.rotation is '' then null else 'reverse')
					this.nodes.icons[0].className = 'icon'
				, 500

	discard : () ->
		if this.numDiscard < this.numCards
			this.numDiscard++

			if this.numDiscard is 2 then this.showNode(this.nodes.discardOptns)

			# Store a record of the latest discard.
			this.discardedIds.push(this.currentCardId)
			this.card[this.currentCardId].discarded = true

			this.nodes.flashcards[this.currentCardId].className = 'flashcard discarded'

			if this.numDiscard is this.numCards
				this.showNode(this.nodes.finishMssg)
				this.hideNode(this.nodes.discardOptns)
				this.nodes.container.className = 'hidden'

			else
				# Search for an available card on the left of the deck to move to.
				_tempId = this.currentCardId
				while _tempId != 0
					_tempId--
					if this.nodes.flashcards[_tempId].className != 'flashcard discarded'
						Flashcards.Engine.shiftCards('right')
						return

				# Search for an available card on the right of the deck to move to.
				_tempId = this.currentCardId
				while _tempId != this.numCards-1
					_tempId++
					if this.nodes.flashcards[_tempId].className != 'flashcard discarded'
						Flashcards.Engine.shiftCards('left')
						return

			Flashcards.Engine.setArrowState()

	unDiscard : () ->
		if not this.gates.buffer
			this.gates.buffer = true
			setTimeout ->
				this.gates.buffer = false
			, 100

			if this.numDiscard > 0 && this.numDiscard != this.numCards
				this.numDiscard--
				_id        = this.discardedIds.pop()                              # The ID of the card on top the discard stack.
				_dif       = Math.abs(this.currentCardId-_id)                     # The absolute value of the difference of the two IDs.
				_direction = if _id > this.currentCardId then 'right' else 'left' # The direction of the last discard relative to the current card.

				# Find the card data for the term we are undiscarding and update it.
				for i in [0..this.numCards-1]
					if this.nodes.flashcards[_id].children[0].children[0].innerHTML == this.card[i].term
						this.card[i].discarded = false
						break

				# Animate the card out of the stack and into the deck, then shift to its position.
				this.nodes.flashcards[_id].className = 'flashcard '+_direction
				for i in [0.._dif-1]
					Flashcards.Engine.shiftCards((if _direction is 'right' then 'left' else 'right'), 'non-rolling') 
				Flashcards.Engine.setArrowState()

				if this.numDiscard < 2 then this.hideNode(this.nodes.discardOptns)

	unDiscardAll : () ->
		if this.numDiscard > 0
			# Reset discard data.
			if this.numDiscard is this.numCards then this.currentCardId = 0

			this.numDiscard = 0

			for i in [0..numCards-1]
				this.card[i].discarded   = false
				this.nodes.flashcards[i].className = 'flashcard right'

			# Remove all cards from discard pile and stage them.
			_reverseRotation = if this.rotation is '' then '-rotated' else ''
			for i in [-2..2]
				if this.nodes.flashcards[this.currentCardId+i]?
					this.nodes.flashcards[this.currentCardId+i].className = 'flashcard stage-'+(i+2)+this.rotation

			hideNode(finishMssg)
			hideNode(discardOptns)

			this.nodes.container.className = ''

			# Set all default card data and return cards to default positions.
			setTimeout ->
				this.setCardData()
				Flashcards.Engine.setCardPositions(if this.rotation is '' then null else 'reverse')
				Flashcards.Engine.setArrowState()
			, 800

	# Shuffles an array.
	shuffle : (arr) ->
		for i in [arr.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[arr[i], arr[j]] = [arr[j], arr[i]]
		arr

	showNode : (node) -> node.className = 'shown'
	hideNode : (node) -> node.className = ''


