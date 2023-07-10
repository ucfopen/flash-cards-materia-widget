
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
	prevFocusNode = null

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

		$('#game').hide()
		$('#overlay').hide()

		if not _browserSupportsSvg()
			$('.error-notice-container').show()
			return

		if instance.name is undefined or null
			instance.name = "Widget Title Goes Here"

		_qset = qset
		_cacheNodes()
		_drawBoard(instance.name, qset.items[0].items.length)
		_storeCards(qset.items[0].items)
		_setCardPositions()
		_addEventListeners()
		_setArrowState()

		$('#hidden-tab-index').hide()
		$('#icon-close').hide()

		if isIE then yepnope(load:['css/IE.css'], complete : () -> document.getElementById('main').className+="IE")

		# If a user unlocks the easter egg, load the atari files and fire her up!
		easterEgg = new Konami _easterEggStart

		# If the user has stumbled upon the meaning of life, give them atari mode.
		if Math.floor(Math.random()*100) is 42 then _easterEggStart()

		# Send log for partipation score
		Materia.Score.submitScoreForParticipation()
		# Force the enginecore to send the logs over (instead of waiting 20-30 seconds)
		Materia.Engine.sendPendingLogs()

	_browserSupportsSvg = ->
		typeof SVGRect != "undefined"

	_hideInstructions = () ->
		$('.instructions').hide()
		$('#game').show()
		$('#icon-help').focus()

	_easterEggStart = () ->
		yepnope(
			load : [
				'assets/js/atari.js',
				'assets/js/timbre.js',
				'assets/css/atari.css'
			]
			complete : () ->
				font = document.createElement('link')
				font.setAttribute('rel', 'stylesheet')
				font.setAttribute('type', 'text/css')
				font.setAttribute('href', 'https://fonts.googleapis.com/css?family=Press+Start+2P')
				document.getElementsByTagName('head')[0].appendChild(font)

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
	# Front of card: 	answer
	# Back of card: 	question
	_storeCards = (data) ->
		numCards   = data.length
		_cardNodes = document.getElementsByClassName 'flashcard'

		for i in [0...numCards]
			Flashcards.Card.push {}
			_card = Flashcards.Card[i]
			console.log("Data: ")
			console.log(data[i])

			# Single flashcard specific data.
			_card.node      = _cardNodes[i]
			_card.BackText = data[i].answers[0].text.replace(/\&\#10\;/g, '<br>')
			_card.FrontText  = data[i].questions[0].text.replace(/\&\#10\;/g, '<br>')

			# Strings that contain inline font scaling style (if applicable)
			frontStyleStr = ""
			backStyleStr = ""

			if data[i].assets?[0]
				# Handle former QSet asset format
				if typeof data[i].assets[0] isnt 'object' and data[i].assets[0] isnt '-1'
					_card.FrontURL = Materia.Engine.getImageAssetUrl data[i].assets[0]
				# Handle new QSet asset format
				else if typeof data[i].assets[0] is 'object'
					_card.FrontURL = data[i].assets[0].url
				# Assign alt text
				_card.FrontAlt  = data[i].assets[0].alt;
			else _card.FrontURL = '-1'

			if data[i].assets?[1]
				# Handle former QSet asset format
				if typeof data[i].assets[1] isnt 'object' and data[i].assets[1] isnt '-1'
					_card.BackURL = Materia.Engine.getImageAssetUrl data[i].assets[1]
				# Handle new QSet asset format
				else if typeof data[i].assets[1] is 'object'
					_card.BackURL = data[i].assets[1].url
				# Assign alt text
				_card.BackAlt  = data[i].assets[1].alt;
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

			_card.node.children[1].children[0].innerHTML = '<p class="'+_frontClass+'" '+frontStyleStr+' ">'+_card.FrontText+'</p>'
			if _card.FrontURL isnt '-1'
				if typeof data[i].assets[0] isnt 'object'
					_card.node.children[1].children[1].innerHTML = '<img class="'+_frontClass+'" src="'+_card.FrontURL+'" alt="'+_card.FrontAlt+'">'
					_card.frontAssetType = "Image"
				else if data[i].assets[0].type == 'jpg' or data[i].assets[0].type == 'jpeg' or data[i].assets[0].type == 'png' or data[i].assets[0].type == 'gif'
					_card.node.children[1].children[1].innerHTML = '<img class="'+_frontClass+'" src="'+_card.FrontURL+'" alt="'+_card.FrontAlt+'">'
					_card.frontAssetType = "Image"
				else if data[i].assets[0].type == 'mp3' || data[i].assets[0].type == 'wav' || data[i].assets[0].type == 'aif'
					_card.node.children[1].children[1].innerHTML = '<audio controls class="'+_frontClass+'" src="'+_card.FrontURL+'">'
					_card.frontAssetType = "Audio"
				else if data[i].assets[0].type == 'link' or data[i].assets[0].type == 'youtube' or data[i].assets[0].type == 'vimeo'
					_card.node.children[1].children[1].innerHTML = '<iframe class="'+_frontClass+'" src="' + _card.FrontURL + '" frameborder="0" allowfullscreen></iframe>'
					_card.frontAssetType="Video"
				else if data[i].assets[0].type == 'mp4'
					_card.node.children[1].children[1].innerHTML = '<video class="'+_frontClass+'"><source src="' + _card.FrontURL + '">Your browser does not support the video tag</video>'
					_card.frontAssetType="Video"

			_card.node.children[0].children[0].innerHTML  = '<p class="'+_backClass+'" '+backStyleStr+' ">'+_card.BackText+'</p>'
			if _card.BackURL isnt '-1'
				if typeof data[i].assets[1] isnt 'object'
					_card.node.children[0].children[1].innerHTML = '<img class="'+_backClass+'" src="'+_card.BackURL+'" alt="'+_card.BackAlt+'">'
					_card.backAssetType = "Image"
				else if data[i].assets[1].type == 'jpg' or data[i].assets[1].type == 'jpeg' or data[i].assets[1].type == 'png' or data[i].assets[1].type == 'gif'
					_card.node.children[0].children[1].innerHTML = '<img class="'+_backClass+'" src="'+_card.BackURL+'" alt="'+_card.BackAlt+'">'
					_card.backAssetType = "Image"
				else if data[i].assets[1].type == 'mp3' or data[i].assets[1].type == 'wav' or data[i].assets[1].type == 'aif'
					_card.node.children[0].children[1].innerHTML = '<audio controls class="'+_backClass+'" src="'+_card.BackURL+'">'
					_card.backAssetType="Audio"
				else if data[i].assets[1].type == 'link' or data[i].assets[1].type == 'youtube' or data[i].assets[1].type == 'vimeo'
					_card.node.children[0].children[1].innerHTML = '<iframe class="'+_backClass+'" src="' + _card.BackURL + '" frameborder="0" allowfullscreen></iframe>'
					_card.backAssetType="Video"
				else if data[i].assets[1].type == 'mp4'
					_card.node.children[0].children[1].innerHTML = '<video class="'+_backClass+'"><source src="' + _card.BackURL + '">Your browser does not support the video tag</video>'
					_card.backAssetType="Video"

			# Aria label for flashcards
			_card.FrontAriaLabel = (if _card.FrontText then _card.FrontText + ", " else "") + (if _card.FrontURL isnt '-1' then _card.frontAssetType + " asset: " + (_card.FrontAlt or "Undescribed.") else "");
			_card.BackAriaLabel  = (if _card.BackText then _card.BackText + ", " else "") + (if _card.BackURL isnt '-1' then _card.backAssetType + " asset: " + (_card.BackAlt or "Undescribed.") else "");
			console.log("Card: ")
			console.log(_card)

	# Places cards in their correct positions within the gameboard and gives them a specific rotation.
	# @face : Specifies whether or not to rotate the card when placing them in their positions.
	_setCardPositions = (face = null) ->
		if face is 'reverse'
			rotation = '-rotated'
			for i in [0...numCards]
				if i is currentCardId
					Flashcards.Card[i].node.className = 'flashcard rotated'
				else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left-rotated'
				else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right-rotated'
		else
			rotation = ''
			for i in [0...numCards]
				if i is currentCardId
					Flashcards.Card[i].node.className = 'flashcard'
				else if i < currentCardId then Flashcards.Card[i].node.className = 'flashcard left'
				else if i > currentCardId then Flashcards.Card[i].node.className = 'flashcard right'
		_ariaUpdate()

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
			Hammer(document.getElementById('icon-close')).on    'tap', _toggleOverlay
			Hammer(document.getElementById('icon-restore')).on 'tap', _unDiscardAll
			Hammer(document.getElementById('icon-finish')).on  'tap', _unDiscardAll
			Hammer(document.getElementById('icon-rotate')).on  'tap', -> _rotateCards(if rotation is '' then 'back')
			Hammer(document.getElementById('icon-shuffle')).on 'tap', _shuffleCards

			_flashcardNodes = document.getElementsByClassName('flashcard')
			for i in [0..._flashcardNodes.length]
				Hammer(_flashcardNodes[i]).on 'tap', ->
					if _isDiscarded(this) then _unDiscard()
					else _flipCard()

			Hammer(document.getElementById('icon-remove')).on 'tap', (e) ->
				_discard()
				e.stopPropagation()
		else
			document.addEventListener upEventType, -> if overlay then _toggleOverlay()

			$('#icon-left').on    'click', ->
				_leftSelected()
				_killAudioVideo()
			$('#icon-right').on   'click', ->
				_rightSelected()
				_killAudioVideo()
			$('#icon-help').on    'click', _toggleOverlay
			$('#icon-close').on    'click', _toggleOverlay
			$('#icon-restore').on 'click', ->
				_killAudioVideo()
				_unDiscardAll()
			$('#icon-finish').on  'click', ->
				_killAudioVideo()
				_unDiscardAll()
			$('#icon-rotate').on  'click', ->
				_killAudioVideo()
				_rotateCards(if rotation is '' then 'back')
			$('#icon-shuffle').on 'click', ->
				_killAudioVideo()
				_shuffleCards()

			$('audio').on    'click', (e)->
				if _isDiscarded(this) then _unDiscard()
				else e.stopPropagation()

			$('.flashcard').on    'click', ->
				# Shuts off all audio players when card is flipped.
				_killAudioVideo()
				if _isDiscarded(this) then _unDiscard()
				else _flipCard()
			$('.flashcard').on    'keydown', (e) ->
				if e.key is ' ' or e.key is 'Enter'
					_killAudioVideo()
					if _isDiscarded(this) then _unDiscard()
					else _flipCard()

			$('#icon-remove').on 'click', (e) ->
				# Shuts off all audio players when card is discarded.
				_killAudioVideo()
				_discard()
				e.stopPropagation()

			# Because screenreaders are able to move out of overlay tab loop,
			# we should hide overlay if it goes out of focus
			$('.flashcard').on 'focus', () ->
				if overlay then _toggleOverlay()

		# Key events for keyboardz.
		window.addEventListener 'keydown', (e) ->
			switch e.key
				when 'ArrowLeft', 'a'   	then _leftSelected()
				when 'ArrowUp', 'w'     	then _unDiscard()
				when 'ArrowRight', 'd'     	then _rightSelected()
				when 'd'     				then _rightSelected()
				when 'ArrowDown', 'x'     	then _discard()
				when 'f' 					then _flipCard()
				when 'h'     				then _toggleOverlay()
				when 'r'     				then _rotateCards(if rotation is '' then 'back')
				when 's'     				then _shuffleCards()
				when 'u'     				then _unDiscardAll()
				# when 27		then

			_killAudioVideo()

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

			# Update aria based on card rotation
			_ariaUpdate();

			# Focus the new card
			Flashcards.Card[currentCardId].node.focus();

			_setArrowState()

	# Shows or hides directional arrows depending on what cards are viewable.
	_setArrowState = () ->
			if _canMove 'right'
				nodes.rightArrow.className = 'arrow shown'
				nodes.rightArrow.setAttribute("aria-hidden", false);
				nodes.rightArrow.setAttribute("tabindex", "0");
			else
				nodes.rightArrow.className = 'arrow'
				nodes.rightArrow.setAttribute("aria-hidden", true);
				nodes.rightArrow.setAttribute("tabindex", "-1");
			if _canMove 'left'
				nodes.leftArrow.className  = 'arrow shown'
				nodes.leftArrow.setAttribute("aria-hidden", false);
				nodes.leftArrow.setAttribute("tabindex", "0");
			else
				nodes.leftArrow.className  = 'arrow'
				nodes.leftArrow.setAttribute("aria-hidden", true);
				nodes.leftArrow.setAttribute("tabindex", "-1");

	# Rotates the current card 180 degrees.
	_flipCard = () ->
		if numCards > 0
			if atari then Flashcards.Atari.playFlip()
			# The back is currently showing.
			if Flashcards.Card[currentCardId].node.className is 'flashcard rotated'
				Flashcards.Card[currentCardId].node.className = 'flashcard'
				_ariaSetLiveRegion(Flashcards.Card[currentCardId].FrontAriaLabel)
			# The front is currently showing.
			else
				Flashcards.Card[currentCardId].node.className = 'flashcard rotated'
				_ariaSetLiveRegion(Flashcards.Card[currentCardId].BackAriaLabel)
			# Update aria
			_ariaShow(currentCardId, false)
			# Focus card
			Flashcards.Card[currentCardId].node.focus();


	_ariaUpdate = () ->
		for i in [0...Flashcards.Card.length]
			if i is currentCardId
				_ariaShow(i, false)
			else
				_ariaHide(i, false)
		for i in [0...Flashcards.DiscardPile.length]
			if i is numDiscard - 1
				_ariaShow(i, true)
			else
				_ariaHide(i, true)

	_ariaShow = (id, isDiscardPile) ->
		if (isDiscardPile)
			# Make last card on discard pile visible to keyboard users and screenreader
			face = if Flashcards.DiscardPile[id].node.className is 'flashcard rotated' then 'back' else 'front';
			Flashcards.DiscardPile[id].node.setAttribute('tabindex', '0');
			Flashcards.DiscardPile[id].node.setAttribute("aria-hidden", false);
			Flashcards.DiscardPile[id].node.setAttribute("aria-label", "Restore last card. " + numDiscard + " card" + (if numDiscard > 1 then "s" else "") + " in discard pile.");
			Flashcards.DiscardPile[id].node.setAttribute("title",  "Restore last card.");
			Flashcards.DiscardPile[id].node.children[if face is 'front' then 1 else 0].setAttribute("aria-hidden", false);
			Flashcards.DiscardPile[id].node.children[if face is 'front' then 0 else 1].removeAttribute("inert");
			Flashcards.DiscardPile[id].node.children[if face is 'front' then 0 else 1].setAttribute("aria-hidden", true);
			Flashcards.DiscardPile[id].node.children[if face is 'front' then 0 else 1].setAttribute("inert", true);
			Flashcards.DiscardPile[id].node.removeAttribute('inert');
		else
			# Get rotation
			face = if Flashcards.Card[id].node.className is 'flashcard rotated' then 'back' else 'front';
			# Set Flashcard parent aria label
			# Flashcards.Card[id].node.setAttribute('aria-label', (if face is 'front' then "flashcard front" else "flashcard back"));
			Flashcards.Card[id].node.setAttribute('aria-label', if face is 'front' then Flashcards.Card[id].FrontAriaLabel else Flashcards.Card[id].BackAriaLabel)
			Flashcards.Card[id].node.setAttribute("title", "Flip card");
			# Make flashcard tabbable and visible to screenreader
			Flashcards.Card[id].node.setAttribute('tabindex', '0');
			Flashcards.Card[id].node.setAttribute("aria-hidden", false);
			Flashcards.Card[id].node.removeAttribute('inert');
			# Show face content depending on rotation
			if face is 'front'
				# Front of card. Show contents if there is video or audio asset
				Flashcards.Card[id].node.children[1].setAttribute("aria-hidden", (if Flashcards.Card[id].FrontURL isnt "-1" and Flashcards.Card[id].frontAssetType != "Image" then false else true));
				Flashcards.Card[id].node.children[1].removeAttribute("inert");
				# Always hide back of card
				Flashcards.Card[id].node.children[0].setAttribute("aria-hidden", true);
				Flashcards.Card[id].node.children[0].setAttribute("inert", true);
			else
				# Back of card
				Flashcards.Card[id].node.children[0].setAttribute("aria-hidden", (if Flashcards.Card[id].BackURL isnt "-1" and Flashcards.Card[id].backAssetType != "Image" then false else true));
				Flashcards.Card[id].node.children[0].removeAttribute("inert");
				# Always hide front of card
				Flashcards.Card[id].node.children[1].setAttribute("aria-hidden", true);
				Flashcards.Card[id].node.children[1].setAttribute("inert", true);

	_ariaHide = (id, isDiscardPile) ->
		if (isDiscardPile)
			Flashcards.DiscardPile[id].node.setAttribute("aria-hidden", true);
			Flashcards.DiscardPile[id].node.setAttribute('tabindex', '-1');
			Flashcards.DiscardPile[id].node.setAttribute('inert', true);
			Flashcards.DiscardPile[id].node.children[0].setAttribute("aria-hidden", true);
			Flashcards.DiscardPile[id].node.children[1].setAttribute("aria-hidden", true);
		else
			Flashcards.Card[id].node.setAttribute("aria-hidden", true);
			Flashcards.Card[id].node.setAttribute('tabindex', '-1');
			Flashcards.Card[id].node.setAttribute('inert', true);
			Flashcards.Card[id].node.children[0].setAttribute("aria-hidden", true);
			Flashcards.Card[id].node.children[1].setAttribute("aria-hidden", true);

	_ariaSetLiveRegion = (msg) ->
		document.getElementById("aria-updates").innerText = msg

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
					_ariaSetLiveRegion("All cards have been shuffled. Current card: " + (if Flashcards.Card[currentCardId].node.className is "flashcard rotated" then Flashcards.Card[currentCardId].BackAriaLabel else Flashcards.Card[currentCardId].FrontAriaLabel))
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

					_ariaSetLiveRegion("All cards have been flipped. Current card: " + (if Flashcards.Card[currentCardId].node.className is "flashcard rotated" then Flashcards.Card[currentCardId].BackAriaLabel else Flashcards.Card[currentCardId].FrontAriaLabel))
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
					document.getElementById("icon-finish").focus()
				else
					if Flashcards.Card[currentCardId]?
						Flashcards.Card[currentCardId].node.className = "flashcard "+(if rotation is '' then '' else 'rotated')
					else
						currentCardId--
						Flashcards.Card[currentCardId].node.className = "flashcard "+(if rotation is '' then '' else 'rotated')

				# Update aria labels
				_ariaUpdate()
				# Focus current flashcard
				# Flashcards.Card[currentCardId]?.node.focus()

				# Update arrows
				_setArrowState()

				# Move card DOM element to discard pile
				lastDiscard = Flashcards.DiscardPile[numDiscard - 1].node;
				# Wait until discard animation has finished
				setTimeout ->
					lastDiscard.remove();
					document.getElementById('discardpile').append(lastDiscard);
					setTimeout ->
						if numCards > 0
							if Flashcards.Card[currentCardId].className = "flashcard rotated"
								_ariaSetLiveRegion("Discarded card. Next card: " + Flashcards.Card[currentCardId].FrontAriaLabel)
							else
								_ariaSetLiveRegion("Discarded card. Next card: " + Flashcards.Card[currentCardId].BackAriaLabel)
						else
							_ariaSetLiveRegion("Discarded card. There are no more cards. Press U to restore all cards.")
					, (600)
				, (if _len > 4 then 720 else 400)


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

				if numDiscard is 0 then document.getElementById("icon-finish").className = "icon unselectable"

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

				# Update aria
				_ariaUpdate()

				# Move card DOM element back to container
				# Wait until discard animation has finished
				setTimeout ->
					Flashcards.Card[currentCardId].node.remove();
					document.getElementById('container').append(Flashcards.Card[currentCardId].node);

					# If there are still cards in the discard pile
					# then keep focus on last discard, otherwise focus flashcard
					if (numDiscard > 0)
						Flashcards.DiscardPile[numDiscard - 1].node.focus()
						_ariaSetLiveRegion("Restored card." + numDiscard + " left in discard pile.")
					else
						Flashcards.Card[currentCardId].node.focus()
						_ariaSetLiveRegion("Restored card. No cards left in discard pile.")
				, 400

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
						document.getElementById("icon-finish").className = "icon unselectable"
						if (Flashcards.Card[currentCardId].node.className = "flashcard rotated")
							_ariaSetLiveRegion("All cards have been restored. Next card: " + Flashcards.Card[currentCardId].BackAriaLabel)
						else
							_ariaSetLiveRegion("All cards have been restored. Next card: " + Flashcards.Card[currentCardId].FrontAriaLabel)
					, 1200
				, 20
				_ariaUpdate()

				# Move all cards to container
				cards = document.querySelectorAll('.flashcard');
				container = document.getElementById('container');
				for card in cards
					card.remove();
					container.append(card);
			else
				_ariaSetLiveRegion("There are no cards to restore.")

	# Opens or closes the help overlay.
	_toggleOverlay = () ->
		if not animating
			animating = true
			setTimeout ->
				animating = false
			, 300

			if overlay is true
				_hideOverlay()
			else
				_showOverlay()

	_showOverlay = () ->
		# Save currently focused object
		prevFocusNode = $(document.activeElement)
		overlay = true
		$('#overlay').show()
		$('#icon-close').show()
		$('#icon-close').focus()
		$('#icon-help').hide()
		$('#hidden-tab-index').show()
		nodes.rightArrow.className  = 'arrow shown'
		nodes.leftArrow.className   = 'arrow shown'
		nodes.icons[4].className    = 'icon focused'
		nodes.gameboard.className   = 'blurred'
		nodes.helpOverlay.className = 'overlay shown'

	_hideOverlay = () ->
		overlay = false
		$('#overlay').hide()
		$('#hidden-tab-index').hide()
		$('#icon-close').hide()
		$('#icon-help').show()
		_setArrowState()
		nodes.icons[4].className    = 'icon'
		nodes.gameboard.className   = ''
		nodes.helpOverlay.className = 'overlay'
		# If previously focused on something, focus that
		if prevFocusNode
			prevFocusNode.focus()
		else
			# Else, focus the current flashcard
			Flashcards.Card[currentCardId].node.focus()

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
			if (nodes.icons[i]).id != 'icon-finish'
				nodes.icons[i].className = 'icon hidden'

	_showIcons = () ->
		for i in [1...nodes.icons.length]
			nodes.icons[i].className = 'icon'

	# Public.
	start : start
	nodes : nodes
	hideInstructions : _hideInstructions
	toggleOverlay : _toggleOverlay
	hideOverlay : _hideOverlay
