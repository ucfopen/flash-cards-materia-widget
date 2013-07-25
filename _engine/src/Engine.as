/* See the file "LICENSE.txt" for the full license governing this code. */
package {
	import com.gskinner.motion.GTween;
	import events.FlashCardsEvent;
	import flash.accessibility.Accessibility;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import nm.arrays.Randomize;
	import nm.gameServ.common.QuestionSet;
	import nm.gameServ.engines.EngineCore;
	public class Engine extends EngineCore
	{
		//var TODO_ITEMS
		// TODO: when a card and the next card are the same image, there is only 1 clip of the image internally
		//    so one of the cards will look wrong, cause it re-parents when you go to addChild it twice
		//    its probably a rare thing to make in a game, so i think we are ok
		// pressing next card very fast looks bad
		protected static const FRONT:String = "front";
		protected static const BACK:String = "back";
		protected var _cachedImageIds:Array = [];
		protected var _cachedImageData:Array = [];
		private var myDeckList:DeckList;
		private var currentDeck:Number;
		private var previousDeck:Number;
		private var currentCard:Number;
		private var displayCard:CardDisplay;
		private var flipped:Boolean;
		private var animating:Boolean;
		private var indexArray:Array;
		private var decks:Array;
		private var theKeyboardHelpWindow:keyboardHelpWindow;
		private var keyboardHelpOpen:Boolean;
		private var background:Background;
		protected override function startEngine():void
		{
			super.startEngine();
			background = new Background();
			addChild(background);
			displayCard = new CardDisplay();
			addChild(displayCard);
			displayCard.x = 169;//800 / 2 - displayCard.width / 2;
			displayCard.y = 70;//525 / 2 - displayCard.height / 2;
			myDeckList = new DeckList();
			addChild(myDeckList);
			flipped = true;
			indexArray = new Array();
			processQSet();
			theKeyboardHelpWindow = new keyboardHelpWindow();
			myDeckList.addEventListener(FlashCardsEvent.DECK_CLICKED, changeDeck, false, 0, true);
			addEventListener(FlashCardsEvent.SHUFFLE_BUTTON_PRESSED, shuffleButtonPressed, true, 0, true);
			displayCard.addEventListener(FlashCardsEvent.HAND_CLICKED, changeCard, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.CARD_CLICKED, flipCard, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.SWITCHING_CARDS, switchCards, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.CARD_SWITCH_COMPLETE, cardSwitchComplete, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.SHUFFLING_CARDS, shuffleCardsUpdateCards, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.KEYBOARD_BUTTON_PRESSED, clickedKeyboardHelpButton, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPressedDown, false, 0, true);
			displayCard.addEventListener(FlashCardsEvent.DROP_CARDS, dropCards, false, 0, true);
			MovieClip(background).gameName.text = inst.name;
			keyboardHelpOpen = false;
			if(Accessibility.active)
			{
				Accessibility.updateProperties();
				addEventListener(MouseEvent.CLICK, focusHelpInitially);
				addEventListener(KeyboardEvent.KEY_DOWN, focusHelpInitially);
			}
		}
		private function focusHelpInitially(event:Event = null):void
		{
			removeEventListener(MouseEvent.CLICK, focusHelpInitially);
			removeEventListener(KeyboardEvent.KEY_DOWN, focusHelpInitially);
			stage.focus = displayCard.helpBtn;
			addEventListener(MouseEvent.CLICK, removeHelpInitially);
			addEventListener(KeyboardEvent.KEY_DOWN, removeHelpInitially);
		}
		private function removeHelpInitially(event:Event = null):void
		{
			removeEventListener(MouseEvent.CLICK, removeHelpInitially);
			removeEventListener(KeyboardEvent.KEY_DOWN, removeHelpInitially);
		}
		private function onKeyPressedDown(event:KeyboardEvent):void {
			switch(event.keyCode)
			{
				case Keyboard.NUMPAD_8: case Keyboard.UP: { onUpArrow(); break; }
				case Keyboard.NUMPAD_2: case Keyboard.DOWN: { onDownArrow(); break; }
				case Keyboard.NUMPAD_4: case Keyboard.LEFT: { onLeftArrow(); break; }
				case Keyboard.NUMPAD_6: case Keyboard.RIGHT: { onRightArrow(); break; }
				case Keyboard.ESCAPE: { onEscPressed(); break; }
				case Keyboard.SPACE: case Keyboard.NUMPAD_5: { onSpacePressed(); break; }
				case 187: case Keyboard.NUMPAD_ADD: { onPlus(); break; }
				case 189: case Keyboard.NUMPAD_SUBTRACT: { onMinus(); break; }
				case 75: //k key
				{
					if(!Accessibility.active) //don't make the keyboard help screen pop-uppable for blind
					{
						onKPressed();
					}
					break;
				}
				case 83: { onSPressed(); break; } //s key
				case 70: { onFPressed(); break; } //f key
			}
		}
		private function dropCards(event:FlashCardsEvent):void
		{
			background.fallingCards.dropCards(event.data.num, event.data.delay, event.data.max);
		}
		private function onUpArrow():void
		{
			if(decks.length < 2) return;
			if (keyboardHelpOpen) { theKeyboardHelpWindow.up.gotoAndPlay(2) }
			else { changeDeckTo(true); }
		}
		private function onDownArrow():void
		{
			displayCard.flipCardOver();
		}
		private function onLeftArrow():void
		{
			////trace("left");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.left.gotoAndPlay(2) }
			else { displayCard.goToPreviousCard(); }
		}
		private function onRightArrow():void
		{
			////trace("right");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.right.gotoAndPlay(2) }
			else { displayCard.goToNextCard(); }
		}
		private function onPlus():void
		{
			////trace("+");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.plus.gotoAndPlay(2) }
			else { displayCard.fontSizeSliderBar.increaseFontSize(); }
		}
		private function onMinus():void
		{
			////trace("-");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.minus.gotoAndPlay(2) }
			else { displayCard.fontSizeSliderBar.decreaseFontSize(); }
		}
		private function onKPressed():void
		{
			////trace("k");
			if (keyboardHelpOpen) {	theKeyboardHelpWindow.k.gotoAndPlay(2); closeKeyboardHelpWindow();}
			else { clickedKeyboardHelpButton(); }
		}
		private function onEscPressed():void
		{
			////trace("Esc");
			if (keyboardHelpOpen) {	theKeyboardHelpWindow.k.gotoAndPlay(2); closeKeyboardHelpWindow();}
		}
		private function onSPressed():void {
			////trace("s");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.s.gotoAndPlay(2) }
			else { shuffleButtonPressed(); }
		}
		private function onGPressed():void {
			////trace("g");
			if (!keyboardHelpOpen) { shuffleButtonPressed(); }
		}
		private function onSpacePressed():void
		{
			////trace("space");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.space.gotoAndPlay(2) }
			else { displayCard.flipCardOver(); }
		}
		private function onFPressed():void
		{
			////trace("f");
			if (keyboardHelpOpen) { theKeyboardHelpWindow.f.gotoAndPlay(2) }
			else { displayCard.flipCardOver(); }
		}
		private function clickedKeyboardHelpButton(event:* = null):void
		{
			addChild(theKeyboardHelpWindow);
			theKeyboardHelpWindow.alpha = 0;
			new GTween(theKeyboardHelpWindow, .3, { alpha: 1 });
			theKeyboardHelpWindow.addEventListener(MouseEvent.CLICK, closeKeyboardHelpWindow);
			keyboardHelpOpen = true;
		}
		private function closeKeyboardHelpWindow(event:MouseEvent = null):void
		{
			var fadeOutTween:GTween = new GTween(theKeyboardHelpWindow, .3, { alpha: 0 });
			fadeOutTween.onComplete = completeCloseHelpWindow;
		}
		private function completeCloseHelpWindow(tween:GTween):void
		{
			removeChild(theKeyboardHelpWindow);
			keyboardHelpOpen = false;
		}
		private function shuffleButtonPressed(event:*=null):void
		{
			decks[currentDeck].cards = decks[currentDeck].cards.sort(randomSort);
			displayCard.shuffleCardsAnimation();
			var cards:Array = decks[currentDeck].cards;
			var cl:int = cards.length;
			for(var c:int = 0; c < cl; c++)
			{
				indexArray[currentDeck][c] = cards[c].cardNumber;
			}
			displayCard.shuffleCardsAnimation();
		}
		private function randomSort(objA:Object, objB:Object):int {
			return Math.round(Math.random() * 2) - 1
		}
		private function changeDeckTo(goingUp:Boolean):void
		{
			var topDeck:Boolean = false;
			previousDeck = currentDeck;
			if(goingUp)
			{
				currentDeck++;
				if(currentDeck >= decks.length)
				{
					currentDeck = 0;
				}
			}
			else
			{
				currentDeck--;
				if(currentDeck < 0)
				{
					currentDeck = decks.length - 1;
				}
			}
			myDeckList.selectItem(currentDeck);
			currentCard = 0;
			displayCard.changeDeck();
			var cardNum:int = indexArray[currentDeck][currentCard];
			var backCardText:String = decks[currentDeck].cards[cardNum].back;
			var frontCardText:String = decks[currentDeck].cards[cardNum].front;
			var prevCard:int = prevCardNum(currentDeck, cardNum);
			if (flipped == true)
			{
				showDisplayCard(currentDeck, prevCard, FRONT, false);
				showDisplayCard(currentDeck, cardNum, FRONT, true);
			}
			else
			{
				showDisplayCard(currentDeck, prevCard, BACK, false);
				showDisplayCard(currentDeck, cardNum, BACK, true);
			}
		}
		private function changeDeck(event:*):void
		{
			previousDeck = currentDeck;
			currentDeck = Number(event.data);
			if (previousDeck != currentDeck) {
				currentCard = 0;
				displayCard.changeDeck();
				var cardNum:int = indexArray[currentDeck][currentCard];
				var backCardText:String = decks[currentDeck].cards[cardNum].back;
				var frontCardText:String = decks[currentDeck].cards[cardNum].front;
				if (flipped == true)
				{
					showDisplayCard(currentDeck, cardNum, BACK, false);
					showDisplayCard(currentDeck, cardNum, FRONT, true);
				}
				else
				{
					showDisplayCard(currentDeck, cardNum, FRONT, false);
					showDisplayCard(currentDeck, cardNum, BACK, true);
				}
			}
		}
		public function get previousDeckCardAmount():Number
		{
			return decks[previousDeck].cards.length;
		}
		private function shuffleCardsUpdateCards(event:*):void
		{
			if (flipped == true)
			{
				showDisplayCard(currentDeck, indexArray[currentDeck][currentCard], FRONT, true);
			}
			else
			{
				showDisplayCard(currentDeck, indexArray[currentDeck][currentCard], BACK, true);
			}
		}
		private function flipCard(event:*):void {
			var cardNum:int = indexArray[currentDeck][currentCard];
			var backCardText:String = decks[currentDeck].cards[cardNum].back;
			var frontCardText:String = decks[currentDeck].cards[cardNum].front;
			if (event.data == "flip")
			{
				if (flipped == true)
				{
					flipped = false;
					showDisplayCard(currentDeck, cardNum, BACK, true);
				}
				else
				{
					flipped = true;
					showDisplayCard(currentDeck, cardNum, FRONT, true);
				}
			}
		}
		private function changeCard(event:*):void {
			var cardNum:Number;
			var prevCardNum:Number;
			var nextCardNum:Number;
			if (event.data == "next")
			{
				var lastCard:Boolean = false;
				if (currentCard == decks[currentDeck].cards.length - 1) { currentCard = 0; lastCard = true;
				}
				else { currentCard++; }
				cardNum = indexArray[currentDeck][currentCard];
				prevCardNum = indexArray[currentDeck][currentCard - 1];
				nextCardNum = indexArray[currentDeck][currentCard + 1];
				if (flipped == false)
				{
					if (lastCard == true)
					{
						showDisplayCard( currentDeck, indexArray[currentDeck][0], BACK, true);
					}
					else
					{
						showDisplayCard( currentDeck, prevCardNum, BACK, true);
					}
					showDisplayCard( currentDeck, cardNum, BACK, false);
				}
				else
				{
					if (lastCard == true)
					{
						showDisplayCard( currentDeck, indexArray[currentDeck][0], FRONT, true);
					}
					else
					{
						showDisplayCard( currentDeck, prevCardNum, FRONT, true);
					}
					showDisplayCard( currentDeck, cardNum, FRONT, false);
				}
			}
			else
			{
				var firstCard:Boolean = false;
				if (currentCard == 0) { currentCard = decks[currentDeck].cards.length - 1; firstCard = true; }
				else { currentCard--; }
				cardNum = indexArray[currentDeck][currentCard];
				prevCardNum = indexArray[currentDeck][currentCard - 1];
				nextCardNum = indexArray[currentDeck][currentCard + 1];
				if (flipped == false)
				{
					if (firstCard == true)
					{
						showDisplayCard( currentDeck, indexArray[currentDeck][decks[currentDeck].cards.length - 1], BACK, false);
					}
					else
					{
						showDisplayCard( currentDeck, cardNum, BACK, false);
					}
				}
				else
				{
					if (firstCard == true)
					{
						showDisplayCard( currentDeck, indexArray[currentDeck][decks[currentDeck].cards.length - 1], FRONT, false);
					}
					else
					{
						showDisplayCard( currentDeck, cardNum, FRONT, false);
					}
				}
			}
			if(!_loadingImages)
			{
				displayCard.continueCurrentAnimation();
			}
			else
			{
				_continueDisplayCardAnimationAfterLoad = true;
			}
		}
		// show either the text or the image associated with the given card
		protected function showDisplayCard(theDeckNum:int, theCardNum:int, textSide:String, cardSide:Boolean):void
		{
			// the cards will swap, and the back card will be shifted to be the front card
			var isCardImage:Boolean;
			var assetId:String;
			if(textSide == FRONT)
			{
				isCardImage = decks[theDeckNum].cards[theCardNum].isFrontImage;
				assetId = decks[theDeckNum].cards[theCardNum].frontAssetId;
			}
			else
			{
				isCardImage = decks[theDeckNum].cards[theCardNum].isBackImage;
				assetId = decks[theDeckNum].cards[theCardNum].backAssetId;
			}
			var myQset:QuestionSet = EngineCore.qSetData;
			if(isCardImage)
			{
				var asset:* = getCachedImageAsset(assetId);
				if( asset != null)
				{
					displayCard.setCardImage(asset, theCardNum + 1, cardSide);
				}
				else
				{
					loadAssetToDisplay(assetId, theCardNum+1, cardSide);
				}
			}
			else
			{
				displayCard.setCardText(decks[theDeckNum].cards[theCardNum][textSide], theCardNum + 1, cardSide);
			}
		}
		protected function clearDisplayCard(i:int, side:String ,b:Boolean):void
		{
			displayCard.setCardText("", i, b);
		}
		protected function getCachedImageAsset(assetId:String):* // return type is sprite i think?
		{
			var i:int = _cachedImageIds.indexOf(assetId);
			if( i != -1)
			{
				return _cachedImageData[i];
			}
			return null;
		}
		protected function loadAssetToDisplay(assetId:String, cardNum:int, b:Boolean):void
		{
			_loadingCount++;
			getImageAssetSprite(assetId, assetReturned, {assetId:assetId, cardNum:cardNum, side:b});
		}
		protected function assetReturned(theSprite:*, data:Object):void
		{
			_cachedImageIds.push(data.assetId);
			_cachedImageData.push(theSprite);
			displayCard.setCardImage(theSprite, data.cardNum, data.side);
			_loadingCount--;
			// ASSERT it wont get below zero
			if(! _loadingImages)
			{
				if(_continueDisplayCardAnimationAfterLoad)
				{
					_continueDisplayCardAnimationAfterLoad = false;
					displayCard.continueCurrentAnimation();
				}
			}
		}
		// Note: this code is for delaying card switching until images are loaded
		protected var _continueDisplayCardAnimationAfterLoad:Boolean = false;
		protected var _loadingCount:int = 0; // how many images we are currently loading
		protected function get _loadingImages():Boolean
		{
			return _loadingCount != 0;
		}
		private function switchCards(event:*):void
		{
			//displayCard.swapCards();
		}
		protected function prevCardNum(theDeck:int, theCard:int):int
		{
			var prevCard:int = theCard - 1;
			if(decks[theDeck].cards.length <= prevCard)
			{
				prevCard - 0;
			}
			else if (prevCard < 0 )
			{
				prevCard = decks[theDeck].cards.length-1;
			}
			return prevCard;
		}
		private function cardSwitchComplete(event:*):void
		{
			////trace(TRACE_STRING + "::cardSwitchComplete");
			var cardNum:int = indexArray[currentDeck][currentCard];
			var backCardText:String = decks[currentDeck].cards[cardNum].back;
			var frontCardText:String = decks[currentDeck].cards[cardNum].front;
			var prevCard:int = prevCardNum(currentDeck, cardNum);
			if (event.data == "next")
			{
				if (flipped == false)
				{
					showDisplayCard(currentDeck, prevCard, BACK, false);
					showDisplayCard(currentDeck, cardNum, BACK, true);
				}
				else
				{
					showDisplayCard(currentDeck, prevCard, FRONT, false);
					showDisplayCard(currentDeck, cardNum, FRONT, true);
				}
			}
			else
			{
				if (flipped == false)
				{
					showDisplayCard(currentDeck, prevCard, BACK, false);
					showDisplayCard(currentDeck, cardNum, BACK, true);
				}
				else
				{
					showDisplayCard(currentDeck, prevCard, FRONT, false);
					showDisplayCard(currentDeck, cardNum, FRONT, true);
				}
			}
		}
		private function processQSet():void
		{
			decks = new Array();
			var newCard:Card;
			var maxCats:Number = EngineCore.qSetData.items.length;
			var maxCards:Number;
			var bigDeck:Deck = new Deck();
			var newDeck:Deck = new Deck()
			var tempAllCardArray:Array = new Array();
			var allCardsNumber:Number = 0;
			var curCat:Object
			var tempCardArray:Array
			var curQ:Object
			// loop through categories
			for (var i:Number = 0; i < maxCats; i++)
			{
				curCat = EngineCore.qSetData.items[i]
				maxCards = curCat.items.length
				newDeck = new Deck()
				newDeck.name = curCat.name
				newDeck.category = i
				tempCardArray = []
				curQ
				// loop through cards in each category
				for (var f:Number = 0; f < maxCards; f++)
				{
					curQ = curCat.items[f];
					tempCardArray.push(f);
					tempAllCardArray.push(allCardsNumber);
					allCardsNumber++;
					newCard = new Card()
					newCard.categoryNumber = i
					newCard.cardNumber = f
					newCard.back = curQ.answers[0].text
					newCard.front = curQ.questions[0].text
					if(curQ.assets != null && curQ.assets.length>0)
					{
						newCard.frontAssetId = curQ.assets[0];
						newCard.backAssetId = curQ.assets[1];
					}
					newDeck.addCard(newCard)
					bigDeck.addCard(newCard)
				}
				decks.push(newDeck)
				indexArray.push(tempCardArray);
			}
			bigDeck.name = "All Cards";
			indexArray.splice(0, 0, tempAllCardArray);
			//decks.splice(0, 0, bigDeck);
			for each(var deck:Deck in decks)
			{
				myDeckList.addItem(deck.name, deck.cards.length);
			}
			// if there is only one deck, don't show decks
			if(maxCats == 1)
			{
				myDeckList.visible = false;
			}
			myDeckList.selectItem(0);
			currentDeck = 0;
			currentCard = 0;
			var cardNum:int = indexArray[currentDeck][currentCard];
			var backCardText:String = decks[currentDeck].cards[cardNum].back;
			var frontCardText:String = decks[currentDeck].cards[cardNum].front;
			if (flipped == true)
			{
				showDisplayCard(currentDeck, cardNum, BACK, false);
				showDisplayCard(currentDeck, cardNum, FRONT, true);
			}
			else
			{
				showDisplayCard(currentDeck, cardNum, FRONT, false);
				showDisplayCard(currentDeck, cardNum, BACK, true);
			}
		}
	}
}