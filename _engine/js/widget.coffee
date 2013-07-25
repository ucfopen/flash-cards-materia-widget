Namespace('test').Engine = do ->
	_qset = null
	_currentCat = null
	_currentQuestion = null
	_$currentQuestionSquare = null
	_currentQuestionIndex = null
	_$board = null
	_categories = {}
	_questions = {}
	_scores = []
	_totalQuestions = 0
	_finalScore = 0

	# Called by Materia.Engine when your widget Engine should start the user experience
	start = (instance, qset, version = '1') ->
		# Go get qset data
		_qset = qset
		_drawBoard(instance.name)


	# shuffle any array
	_shuffle = (a) ->
		for i in [a.length-1..1]
			j = Math.floor Math.random() * (i + 1)
			[a[i], a[j]] = [a[j], a[i]]
		a

	# Draw the main board
	_drawBoard = (title) ->
		tBoard = _.template $('#t-board').html()
		_$board = $(tBoard title: title, categories:_qset.items )
		# make an array of each category, questions, and count the questions
		for ci, category of _qset.items
			_categories[ci] = category
			for qi, question of category.items
				question.answers = _shuffle(question.answers) if _qset.options.randomize
				_totalQuestions++
				_questions[question.id] = question

		_$board.find('.question').on 'click', _onBoardQuestionClick
		$('body').append _$board

	# When a Question on the main board is clicked
	_onBoardQuestionClick = (e) ->
		# set the current state
		_$currentQuestionSquare = $(e.target)
		_currentCat = _categories[_$currentQuestionSquare.parent('.category').data('id')]
		_currentQuestion = _questions[_$currentQuestionSquare.data('id')]
		_currentQuestionIndex = parseInt _$currentQuestionSquare.html(), 10

		# Draw the Question Page
		tQuestion = _.template $('#t-question-page').html()
		$question = $ tQuestion
			index: _currentQuestionIndex
			id: _currentQuestion.id
			answers: _currentQuestion.answers
			category: _currentCat.name
			question: _currentQuestion.questions[0].text

		# setup the button listeners
		$question.find('.button.return').on 'click', _closeQuestion
		$question.find('.button.submit').on 'click', _submitAnswer
		$question.find('.answers input').on 'click', (e) ->
			$('.answers li').removeClass 'selected'
			$(e.target).parent('li').addClass 'selected'
			$question.find('.button.submit').prop 'disabled', false

		_$board.hide()
		$('body').append $question

	# Answer submitted by user
	_submitAnswer = ->
		$chosenRadio = $(".answers input[type='radio']:checked")
		chosenAnswer = $chosenRadio.val()
		answer = _checkAnswer _currentQuestion, chosenAnswer
		Score.submitQuestionForScoring _currentQuestion.id, answer.text
		_scores.push answer.score
		_updateScore()

		# Update the question square
		newTitle = "#{_currentCat.name} question  ##{_currentQuestionIndex} "

		if answer.score == 100
			$chosenRadio.parents('li').prepend '<span class="correct mark">&#x2714;</span>'
			_$currentQuestionSquare
				.addClass('correct')
				.html('&#x2714;') # checkmark
				.attr('title', "#{newTitle} Correct")
		else
			$chosenRadio.parents('li').prepend '<span class="wrong mark">X</span>'
			_$currentQuestionSquare
				.addClass('wrong')
				.html('X') # incorrect X
				.attr('title', "#{newTitle} Wrong")

		# Update the radio list and buttons
		$(".answers input[type='radio']").prop 'disabled', true
		$('.button.submit').prop 'disabled', true
		$('.button.return').addClass 'highlight'
		$('.answers ul').addClass('answered');
		$chosenRadio.parents('li').append("<span class=\"feedback\"><strong>Feedback:</strong> #{answer.feedback}</span>") if answer.feedback?
		_$currentQuestionSquare.removeClass('unanswered').off 'click'

	# Draw the final screen that transitions to the Score Screen
	_drawFinishScreen = ->
		tFinish = _.template $('#t-finish-notice').html()
		$finish = $(tFinish score: _finalScore)
		$finish.find('button').on 'click', _end
		_$board.hide();
		$('body').append $finish

	# Update the score on the main screen
	_updateScore = ->
		_finalScore = 0
		for i in _scores
			_finalScore += i

		_finalScore = Math.round _finalScore/_totalQuestions
		$('.score .value').html _finalScore

	# Check the value of the chosen answer
	_checkAnswer = (question, answerId) ->
		for answer in question.answers
			if answer.id == answerId
				return {
					score: parseInt(answer.value, 10)
					text: answer.text
					feedback: answer.options.feedback
				}

		throw Error 'Submitted answer not in this questions'

	# Close a Question screen to return to the main board
	_closeQuestion = ->
		$('.screen.question').remove()
		_$board.show()
		_drawFinishScreen() if _scores.length ==_totalQuestions

	_end = ->
		Materia.Engine.end()

	#public
	start: start
