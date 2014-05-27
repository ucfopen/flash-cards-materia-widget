client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'flash-cards', ->
			client = this
			done()
	, 15000

describe 'Main page', ->
	it 'should have a title', (done) ->
		client
			.getText '#instance-title', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("Psychology")
				done()

	it 'should show first card', (done) ->
		client
			.getText '.flashcard .front .content .description', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("A Swiss psychiatrist")

				client.getText '.flashcard .back .content .title', (err, text) ->
					expect(err).toBeNull()
					expect(text).toContain("Carl Jung")
					done()

	it 'should flip card when clicked', (done) ->
		client.execute "$('.flashcard:first').mouseup()", null, (err) ->
			client.getAttribute '.flashcard', 'class', (err, classes) ->
				expect(err).toBeNull()
				expect(classes).toContain('rotated')
				client.pause 500
				client.execute "$('.flashcard:first').mouseup()", null, (err) ->
					expect(err).toBeNull()
					client.getAttribute '.flashcard', 'class', (err, classes) ->
						console.log classes
						done()

	it 'should go right when I click right', (done) ->
		client
			.execute "$('#icon-right').mouseup()", null, (err) ->
				client.getAttribute '.flashcard.left', 'class', (err, classes) ->
					expect(err).toBeNull()
					done()

	it 'should go left when I click left', (done) ->
		client.execute "$('#icon-left').mouseup()", null, (err) ->
			client.execute "return $('.flashcard.left').length", null, (err, result) ->
				expect(err).toBeNull()
				expect(result.value).toBe(0)
				done()

	it 'should rotate all when I click rotate', (done) ->
		client.execute "$('#icon-rotate').mouseup()", null, (err) ->
			client.execute "return $('.flashcard.rotated').length", null, (err, result) ->
				expect(err).toBeNull()
				expect(result.value).toBe(0)
				done()
				client.execute "$('#icon-rotate').mouseup()", null, (err) ->
					client.execute "return $('.flashcard.rotated').length == $('.flashcard').length", null, (err, result) ->
						expect(err).toBeNull()
						expect(result.value).toBe(true)
						done()
