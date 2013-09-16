Namespace('Flashcards').IE = 
	nodes : {}
	
	start : ($container) ->
		document.getElementById('main').className = "IE"

		this.insertIEBack($container)

	insertIEBack : ($container) ->
		_tIEBack = $(document.getElementById('t-IE-back').innerHTML)

		$container.append(_tIEBack.clone())

		this.nodes.IEBack = document.getElementById('IE-back')

	specialFlipShow : (currentCard, data) ->
		Flashcards.IE.nodes.IEBack.className = 'shown'
		Flashcards.IE.nodes.IEBack.children[0].innerHTML = currentCard.children[1].children[0].innerHTML

	specialFlipHide : () ->
		Flashcards.IE.nodes.IEBack.className = ''

	specialRotation : () ->
		Flashcards.IE.nodes.IEBack.className = 'shown'
		Flashcards.IE.nodes.IEBack.children[0].innerHTML = currentCard.children[1].children[0].innerHTML
		#fasdf
