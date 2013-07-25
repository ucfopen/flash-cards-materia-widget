Namespace('test').Creator = do ->
	_widget  = null # holds widget data
	_qset    = null # Keep tack of the current qset
	_title   = null # hold on to this instance's title
	_version = null # holds the qset version, allows you to change your widget to support old versions of your own code
	_cardTemplate = null # contains a template for a new card's table row, for cloning
	_waitingOnImage = null # contains the span that will hold any selected media

	initNewWidget = (widget, baseUrl) ->
		_buildDisplay 'New Flashcards Widget', widget

	initExistingWidget = (title, widget, qset, version, baseUrl) ->
		_buildDisplay title, widget, qset, version

	onSaveClicked = (mode = 'save') ->
		if _buildSaveData()
			Materia.CreatorCore.save _title, _qset
		else
			Materia.CreatorCore.cancelSave 'Widget not ready to save.'

	onSaveComplete = (title, widget, qset, version) -> true

	onQuestionImportComplete = (questions) ->
		_addCard card for card in questions

	onMediaImportComplete = (media) ->
		url = Materia.CreatorCore.getMediaUrl(media[0].id)
		# place the selected image inside the targeted container
		_waitingOnImage.css("background-image", "url("+url+")");
		_waitingOnImage = null

	_buildDisplay = (title = 'Default test Title', widget, qset, version) ->
		_version = version
		_qset    = qset
		_widget  = widget
		_title   = title

		$('#title').val _title

		#fill the card template object if it's null
		unless _cardTemplate
			_cardTemplate = $('tr.template')
			$('tr.template').remove()
			_cardTemplate.removeClass('template')

		#add an empty row when the 'Add Cards' button is clicked
		$('.add_button').click _addCard

		#populate the table with information from the qset
		_addCard card for card in _qset.items[0].items

	_buildSaveData = ->
		okToSave = false
		_title = $('#title').val()
		okToSave = _title isnt ''

		#reset the qset
		_qset = {}

		#various values that should only ever be one thing
		_qset['assets'] = []
		_qset['rand'] = false
		_qset['options'] = []
		_qset['name'] = ''

		#questionably necessary middle layer
		items = {}
		items['assets'] = []
		items['options'] = []
		items['rand'] = false

		#pull all relevant information out of the table
		cards = $('#cards').children()
		#actual container for the question items
		real_items = []
		for card in cards
			item = _process card
			real_items.push item

		#do the necessary substitutions
		items['items'] = real_items
		items = [items]
		_qset['items'] = items

		okToSave

	_addCard = (card) ->
		#set up all the listeners for this row
		$clone = _cardTemplate.clone()
		$clone.find('.delete_button').click () ->
			$clone.remove()
			Materia.CreatorCore.setHeight()
		$clone.find('.swap_button').click () ->
			$clone.append($clone.find('td')[1])
		$clone.find('.text_radio').click () ->
			td = $(this).closest('td')
			td.find('.card_text').show()
			td.find('.card_image').hide()
		$clone.find('.image_radio').click () ->
			td = $(this).closest('td')
			td.find('.card_text').hide()
			#for some reason, '.show()' sets 'display' to 'inline' instead of 'block'
			td.find('.card_image').css('display', 'block')
		$clone.find('.image_button').click () ->
			_waitingOnImage = $(this).parent()
			Materia.CreatorCore.showMediaImporter()

		#default these to true, change them later if needed
		$clone.find('.text_radio').attr('checked', true)

		#fill the table with any relevant information from the qset
		if card? and card.id?
			front = $clone.find('td')[1]
			back = $clone.find('td')[2]

			#if there are images anywhere on the card, get them
			if card.assets? and card.assets.length > 0
				#first asset, front face
				if card.assets[0] isnt '-1'
					$(front).find('.image_radio').attr('checked', true)
					$(front).find('.card_text').hide()
					$(front).find('.card_image').css('display', 'block')
					url = Materia.CreatorCore.getMediaUrl(card.assets[0])
					$(front).find('.card_image').css("background-image", "url("+url+")");
				else
					$(front).find('textarea').val card.questions[0].text
				#second asset, back face
				if card.assets[1] isnt '-1'
					$(back).find('.image_radio').attr('checked', true)
					$(back).find('.card_text').hide()
					$(back).find('.card_image').css('display', 'block')
					url = Materia.CreatorCore.getMediaUrl(card.assets[1])
					$(back).find('.card_image').css("background-image", "url("+url+")");
				else
					$(back).find('textarea').val card.answers[0].text
			else
				$(front).find('textarea').val card.questions[0].text
				$(back).find('textarea').val card.answers[0].text

		#new row is built, put it in the table
		$('#cards').append($clone)
		Materia.CreatorCore.setHeight()

	#scrape all relevant qset info out of each row
	_process = (card) ->
		front = $(card).find('td')[1]
		back = $(card).find('td')[2]

		#various values that should only ever be one thing
		item = {'assets': null, 'type': 'QA', 'id': ''}
		q = {}
		a = {'id': '', 'value': 100, 'options': []}

		#determine whether each face holds text or image
		is_f_text = $(front).find(':checked').hasClass 'text_radio'
		is_b_text = $(back).find(':checked').hasClass 'text_radio'

		#front face, question
		if is_f_text
			q['text'] = $(front).find('textarea').val()
		else
			bg_url = _scrapeImage front
			#assume back face has no asset for now
			item['assets'] = [bg_url, '-1']
			q['text'] = 'None'

		#back face, answer
		if is_b_text
			a['text'] = $(back).find('textarea').val()
		else
			bg_url = _scrapeImage back
			#initialize the assets array if it's still null
			item['assets'] = ['-1','-1'] unless item['assets']?
			item['assets'][1] = bg_url
			a['text'] = 'None'

		#pack everything together as necessary and send the item back
		item['questions'] = [q]
		item['answers'] = [a]
		item

	#given element with background image, pull out the url and regex it to get the asset id
	_scrapeImage = (target) ->
		url = $(target).find('.card_image').css('background-image')
		url = /^url\((['"]?)(.*)\1\)$/.exec(url)
		url = url[2]
		url = url.substr(url.lastIndexOf('/')+1)
		url

	_trace = ->
		if console? && console.log?
			console.log.apply console, arguments

	#public
	manualResize: true
	initNewWidget: initNewWidget
	initExistingWidget: initExistingWidget
	onSaveClicked:onSaveClicked
	onMediaImportComplete:onMediaImportComplete
	onQuestionImportComplete:onQuestionImportComplete
	onSaveComplete:onSaveComplete
