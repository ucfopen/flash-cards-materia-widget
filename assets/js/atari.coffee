Namespace("Flashcards").Atari =
	Nodes : {}
	Sound : {}
	start : ->
		console.log('atari start')
		document.getElementById('main').className = "atari"

		@cacheNodes()
		@pixelateIcons()
		@initializeSounds()

		@showLoadingElem(@Nodes.loadingElem[i], i) for i in [0..@Nodes.loadingElem.length-1]

		setTimeout ->
			document.getElementById('fake-loading-screen').className = 'hidden'
			document.getElementById('game').className = 'shown'
		, 1500

	cacheNodes : ->
		@Nodes.loadingElem = document.getElementsByClassName('load')

	pixelateIcons : ->
		$('#icon-left').append($($('#t-arrow').html()).clone().addClass('left'))
		$('#icon-right').append($($('#t-arrow').html()).clone().addClass('right'))

		$('#icon-finish').append($($('#t-icon').html()).clone().addClass('restore-table'))
		$('#icon-restore').append($($('#t-icon').html()).clone().addClass('restore-table'))
		$('#icon-rotate').append($($('#t-icon').html()).clone().addClass('rotate-table'))
		$('#icon-shuffle').append($($('#t-icon').html()).clone().addClass('shuffle-table'))

	initializeSounds : ->
		@Sound.saw0 = T("saw", {freq:110, mul:0.1})
		@Sound.saw1 = T("saw", {freq:440, mul:0.1})
		@Sound.saw2 = T("saw", {freq:660, mul:0.1})
		@Sound.saw3 = T("saw", {freq:880, mul:0.1})
		@Sound.saw4 = T("saw", {freq:990, mul:0.1})
		@Sound.saw5 = T("saw", {freq:1000, mul:0.1})
		@Sound.saw6 = T("saw", {freq:1110, mul:0.1})
		@Sound.saw7 = T("saw", {freq:1220, mul:0.1})

	showLoadingElem : (elem, i) ->
		console.log elem
		setTimeout ->
			elem.className = 'shown'
		, i*150+(Math.random()*400)

	playIcon : (type) ->
		table = [1760, [110, "200ms"]]

		freq = T("env", {table:table}).on("bang", -> VCO.mul = 0.2).on("ended", -> VCO.mul = 0)
		VCO  = T("saw", {freq:freq, mul:0}).play()

		midicps = T("midicps")

		freq.bang()

		if type is 'rotate'  then @playRotate()
		if type is 'shuffle' then @playShuffle()
		if type is 'restore' then @playRestore()

	playShuffle : ->
		setTimeout ->
			T("perc", {r:300}, Flashcards.Atari.Sound.saw1).on("ended", -> @pause()).bang().play()
			setTimeout ->
				T("perc", {r:300}, Flashcards.Atari.Sound.saw2).on("ended", -> @pause()).bang().play()
				setTimeout ->
					T("perc", {r:300}, Flashcards.Atari.Sound.saw3).on("ended", -> @pause()).bang().play()
					setTimeout ->
						T("perc", {r:300}, Flashcards.Atari.Sound.saw4).on("ended", -> @pause()).bang().play()
					, 100
				, 100
			, 100
		, 800

	playRotate : ->
		setTimeout ->
			T("perc", {r:700}, Flashcards.Atari.Sound.saw6).on("ended", -> @pause()).bang().play()
			T("perc", {r:700}, Flashcards.Atari.Sound.saw1).on("ended", -> @pause()).bang().play()
			T("perc", {r:700}, Flashcards.Atari.Sound.saw3).on("ended", -> @pause()).bang().play()
		, 600

	playRestore : ->
		setTimeout ->
			table = [550, [1100], "300ms"]

			freq = T("env", {table:table}).on("bang", -> VCO.mul = 0.2).on("ended", -> VCO.mul = 0)
			VCO  = T("saw", {freq:freq, mul:0}).play()

			midicps = T("midicps")

			freq.bang()
		, 500

	playDiscard : ->
		table = [440, [0, "200ms"]]

		freq = T("env", {table:table}).on("bang", -> VCO.mul = 0.2).on("ended", -> VCO.mul = 0)
		VCO  = T("saw", {freq:freq, mul:0}).play()

		midicps = T("midicps")

		freq.bang()

	playButton : ->
		T("perc", {r:100}, @Sound.saw0).on("ended", -> @pause()).bang().play();

	playFlip : ->
		T("perc", {r:50}, Flashcards.Atari.Sound.saw1).on("ended", -> @pause()).bang().play()
		setTimeout ->
			T("perc", {r:50}, Flashcards.Atari.Sound.saw2).on("ended", -> @pause()).bang().play()
			setTimeout ->
				T("perc", {r:50}, Flashcards.Atari.Sound.saw3).on("ended", -> @pause()).bang().play()
				setTimeout ->
					T("perc", {r:50}, Flashcards.Atari.Sound.saw4).on("ended", -> @pause()).bang().play()
					setTimeout ->
						T("perc", {r:50}, Flashcards.Atari.Sound.saw5).on("ended", -> @pause()).bang().play()
						setTimeout ->
							T("perc", {r:50}, Flashcards.Atari.Sound.saw6).on("ended", -> @pause()).bang().play()
						, 50
					, 50
				, 50
			, 50
		, 50


