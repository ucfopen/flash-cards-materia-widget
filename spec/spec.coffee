client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'flash-cards', ->
			client = this
			done()
	, 15000

describe 'Main page', ->
	it 'should show instructions', (done) ->
		client.getText '#instructions h2', (err, text) ->
			expect(text).toBe("Studying with Flash Cards")
		client.getText '#instructions .gotit', (err, text) ->
			expect(text).toBe("Got it!")
			done()

	it 'should be able to hide instructions', (done) ->
		client.click '#instructions .gotit', (err, text) ->
			client.getAttribute '#instructions', 'style', (err, classes) ->
				expect(classes).toContain("display: none")
				done()

	it 'should have a title', (done) ->
		client
			.getText '#instance-title', (err, text) ->
				expect(text).toContain("Psychology")
				done()

	it 'should show first card', (done) ->
		client
			.getText '.flashcard .front .content .description', (err, text) ->
				expect(text.join()).toContain("A Swiss psychiatrist")

				client.getText '.flashcard .back .content .title', (err, text) ->
					expect(text).toContain("Carl Jung")
					done()

	it 'should flip card when clicked', (done) ->
		client.execute "$('.flashcard:first').mouseup()", (err) ->
			client.getAttribute '.flashcard', 'class', (err, classes) ->
				expect(classes.join()).toContain('rotated')
				client.pause 500
				client.execute "$('.flashcard:first').mouseup()", (err) ->
					client.getAttribute '.flashcard', 'class', (err, classes) ->
						done()

	it 'should go right when I click right', (done) ->
		client
			.execute "$('#icon-right').mouseup()", (err) ->
				client.getAttribute '.flashcard.left', 'class', (err, classes) ->
					done()

	it 'should go left when I click left', (done) ->
		client.execute "$('#icon-left').mouseup()", (err) ->
			client.execute "return $('.flashcard.left').length", (err, result) ->
				expect(result.value).toBe(0)
				done()

	it 'should rotate all when I click rotate', (done) ->
		client.execute "$('#icon-rotate').mouseup()", (err) ->
			client.execute "return $('.flashcard.rotated').length", (err, result) ->
				expect(result.value).toBe(0)
				client.execute "$('#icon-rotate').mouseup()", (err) ->
					client.pause 5000
					client.execute "return $('.flashcard.rotated, .flashcard.right-rotated').length == $('.flashcard').length", (err, result) ->
						expect(result.value).toBe(true)
						done()
						client.end()
