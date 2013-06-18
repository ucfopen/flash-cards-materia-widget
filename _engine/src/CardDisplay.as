/* See the file "LICENSE.txt" for the full license governing this code. */
package {
import com.gskinner.motion.GTween;
import events.FlashCardsEvent;
import events.FontSizeSliderEvent;
import flash.accessibility.Accessibility;
import flash.accessibility.AccessibilityProperties;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.text.*;
import flash.utils.*;
import nm.ui.ScrollClip;
	public class CardDisplay extends Sprite
	{
		private var cardFront:SingleFlashCard;
		private var cardBack:SingleFlashCard;
		private var leftHand:SingleLeftHand;
		private var rightHand:SingleRightHand;
		private var theCardPerson:cardCharacter;
		private var fontSizeSlider:FontSizeSlider;
		private var cardFontSize:Number;
		private var newCardFormat:TextFormat;
		private var theSingleShuffleButton:singleShuffleButton;
		private var theKeyboardHelpButton:keyboardHelpButton;
		private var frontCardScroll:ScrollClip;
		private var backCardScroll:ScrollClip;
		private var frontCardText:CardText;
		private var backCardText:CardText;
		private static const CARD_ROTATION_DEGREE:Number = 65;
		private static const CARD_SWITCH_TIME:Number = .25;
		private var veryBIGTEST:ScrollClip;
		private var finishedChangingNextCards:Boolean;
		private var finishedChangingPreviousCards:Boolean;
		private var finishedFlippingCards:Boolean;
		private var clickingDisabled:Boolean;
		private var clickedOnScrollBar:Boolean;
		private var changingCard:Boolean;
		private var rollOutTimer:Timer
		protected var _backImage:* = null;
		protected var _frontImage:* = null;
		public function CardDisplay()
		{
			finishedChangingNextCards = true;
			finishedChangingPreviousCards = true;
			finishedFlippingCards = true;
			clickingDisabled = false;
			clickedOnScrollBar = false;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			this.accessibilityProperties = new AccessibilityProperties();
			this.tabIndex = 0;
		}
		private function onAddedToStage(event:Event):void {
			theCardPerson = new cardCharacter();
			this.addChild(theCardPerson);
			cardFontSize = 18;
			cardFront = new SingleFlashCard();
			cardBack = new SingleFlashCard();
			leftHand = new SingleLeftHand();
			rightHand = new SingleRightHand();
			this.addChild(cardBack);
			this.addChild(cardFront);
			frontCardScroll = new ScrollClip(450, 317, true);
			cardFront.cardClip.addChild(frontCardScroll);
			frontCardScroll.x = 8;
			frontCardScroll.y = 20;
			frontCardScroll.setStyle("bgAlpha", 0);
			backCardScroll = new ScrollClip(450, 317, true);
			cardBack.cardClip.addChild(backCardScroll);
			backCardScroll.x = 8;
			backCardScroll.y = 20;
			backCardScroll.setStyle("bgAlpha", 0);
			changingCard = false;
			backCardText = new CardText();
			frontCardText = new CardText();
			backCardText.cardText.autoSize = TextFieldAutoSize.CENTER;
			frontCardText.cardText.autoSize = TextFieldAutoSize.CENTER;
			frontCardScroll.clip.addChild(frontCardText);
			backCardScroll.clip.addChild(backCardText);
			theCardPerson.x = 65;
			theCardPerson.y = 0;
			fontSizeSlider = new FontSizeSlider(4);
			this.addChild(rightHand);
			this.addChild(leftHand);
			leftHand.alpha = rightHand.alpha = 1;
			var dropShadowFilter:DropShadowFilter = new DropShadowFilter(12, 45, 0, .2, 12, 12);
			cardFront.filters = [dropShadowFilter];
			cardBack.filters = [dropShadowFilter];
			cardFront.x = 590;
			cardFront.y = 475;
			cardBack.x = 590;
			cardBack.y = 475;
			rightHand.x = 591+15;
			rightHand.y = 475+50;
			leftHand.x = -71-15;
			leftHand.y = 475 + 50;
			if(Accessibility.active)
			{
				theKeyboardHelpButton.accessibilityProperties = new AccessibilityProperties();
				theKeyboardHelpButton.tabIndex = 1;
				var helpString:String =
					"Left key or Numpad 4: Previous card. Right key or Numpad 6: Next card. " +
					"S key: Shuffle deck. Space or F key or Numpad 5: Flip card. " +
					"Plus key: Increase font size. Minus key: Decrease font size. ";
				theKeyboardHelpButton.accessibilityProperties.name = helpString;
				Accessibility.updateProperties();
			}
			theSingleShuffleButton = new singleShuffleButton();
			theKeyboardHelpButton = new keyboardHelpButton();
			this.addChild(theKeyboardHelpButton);
			theKeyboardHelpButton.x = 515;
			this.addChild(theSingleShuffleButton)
			theSingleShuffleButton.x = 515;
			theSingleShuffleButton.y = -theSingleShuffleButton.height - 10;
			theKeyboardHelpButton.addEventListener(MouseEvent.CLICK, clickedKeyboardHelpButton);
			theSingleShuffleButton.addEventListener(MouseEvent.CLICK, clickedSingleShuffleButton);
			rightHand.addEventListener(MouseEvent.CLICK, nextCard, false, 0, true);
			leftHand.addEventListener(MouseEvent.CLICK, previousCard, false, 0, true);
			rightHand.addEventListener(MouseEvent.MOUSE_OVER, fadeInHands, false, 0, true);
			rightHand.addEventListener(MouseEvent.MOUSE_OUT, fadeOutHands, false, 0, true);
			leftHand.addEventListener(MouseEvent.MOUSE_OVER, fadeInHands, false, 0, true);
			leftHand.addEventListener(MouseEvent.MOUSE_OUT, fadeOutHands, false, 0, true);
			cardFront.cardClip.addEventListener(MouseEvent.CLICK, flipCard, false, 0, true);
			rightHand.buttonMode = true;
			rightHand.useHandCursor = true;
			leftHand.buttonMode = true;
			leftHand.useHandCursor = true;
			cardFront.gotoAndStop(1);
			cardBack.gotoAndStop(1);
			newCardFormat = new TextFormat("Courier New", 11);
			setStyleFormat();
			this.addChild(fontSizeSlider);
			fontSizeSlider.x = 516 + 12;
			fontSizeSlider.y = 43;
			fontSizeSlider.addEventListener(FontSizeSliderEvent.SLIDER_POS_CHANGE, newFontSize);
			rightHand.theHand.gotoAndStop(theCardPerson.randomCharacterNum);
			leftHand.theHand.gotoAndStop(theCardPerson.randomCharacterNum);
			fadeOutHands();
		}
		public function get getfrontCardScroll():ScrollClip {
			return frontCardScroll;
		}
		public function get fontSizeSliderBar():FontSizeSlider {
			return fontSizeSlider;
		}
		public function updateCards():void {
			frontCardScroll.update();
		}
		private function clickedKeyboardHelpButton(event:* = null):void
		{
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.KEYBOARD_BUTTON_PRESSED));
		}
		private function clickedSingleShuffleButton(event:MouseEvent):void
		{
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.SHUFFLE_BUTTON_PRESSED));
		}
		private function fadeInHands(event:MouseEvent=null):void
		{
			new GTween(leftHand, .25, { alpha:1 } );
			new GTween(rightHand, .25, { alpha:1 } );
			rollOutTimer.stop();
		}
		private function fadeOutHands(event:MouseEvent = null):void {
			rollOutTimer = new Timer(150, 1);
			rollOutTimer.addEventListener("timer", hoverOutCardFadeBack);
			rollOutTimer.start();
		}
		private function hoverOutCardFadeBack(event:TimerEvent):void {
			if (!changingCard) {
				new GTween(leftHand, .25, { alpha:.35 } );
				new GTween(rightHand, .25, { alpha:.35 } );
			}
		}
		public function flipCardOver():void {
			flipTheCard();
		}
		private function flipCard(event:MouseEvent=null):void {
			clickedOnScrollBar = (frontCardScroll.objectIsScrollBar(event.target));
			if (!clickedOnScrollBar) {
				clickedOnScrollBar = false;
				flipTheCard();
			}
			else { clickedOnScrollBar = false; }
		}
		private function flipTheCard():void {
			clickingDisabled = true;
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.CARD_CLICKED, "flip"));
			var t:GTween = new GTween(leftHand, .25, { x:(450) /*, scaleX: -1*/ } );
			t.onComplete = completeFlipCard;
			var t2:GTween = new GTween(cardFront, .15, { x:(590-560/2-50), y:(475-cardFront.height/2+190), scaleX:0, scaleY:1.05} );
			t2.onComplete = continueToFlipCard;
			rightHand.arrow.visible = false;
			leftHand.arrow.visible = false;
			leftHand.alpha = 1;
			rightHand.alpha = 1;
			fadeInHands();
		}
		private function continueToFlipCard(tween:GTween = null):void {
			cardFront.cardClip.gotoAndPlay(2);
			new GTween(cardFront, .15, { x:590 , y:475,  scaleX:1, scaleY:1 } );// , ease: Elastic.easeOut } );
		}
		private function completeFlipCard(tween:GTween = null):void {
			cardBack.cardClip.gotoAndPlay(2);
			var t:GTween = new GTween(leftHand, .2, { x:( -86), /*scaleX:1,*/ scaleY:1 } );
			t.onComplete = flipCardComplete;
			rightHand.arrow.visible = true;
			leftHand.arrow.visible = true;
		}
		private function flipCardComplete(tween:GTween = null):void {
			clickingDisabled = false;
			updateCards();
			checkScrollBars();
			fadeOutHands();
		}
		public function goToNextCard():void {
			nextCard();
		}
		public function goToPreviousCard():void {
			previousCard();
		}
		// this is for the code that delays card switching until images are loaded
		protected var currentAnimationIsNextCard:Boolean = true;
		public function continueCurrentAnimation():void
		{
			if(currentAnimationIsNextCard)
			{
				nextCardReadyToGo();
			}
			else
			{
				previousCardReadyToGo();
			}
		}
		private function nextCard(event:MouseEvent=null):void {
			if (clickingDisabled != true)
			{
				changingCard = true;
				currentAnimationIsNextCard = true;
				dispatchEvent(new FlashCardsEvent(FlashCardsEvent.HAND_CLICKED, "next"));
			}
		}
		protected function nextCardReadyToGo():void
		{
			rightHand.rotation = 0;
			cardFront.cardClip.x = -560;
			cardFront.x = 590;
			if (finishedChangingNextCards != true)
			{
				this.swapChildren(cardBack, cardFront);
				finishedChangingNextCards = true;
			}
			fadeInHands();
			new GTween(cardFront, CARD_SWITCH_TIME, { rotation:CARD_ROTATION_DEGREE } );
			var t:GTween = new GTween(rightHand, CARD_SWITCH_TIME, { rotation:CARD_ROTATION_DEGREE } );
			t.onComplete = nextCardTweenBack;
		}
		private function nextCardTweenBack(tween:GTween = null):void {
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.SWITCHING_CARDS, "next"));
			if (finishedChangingNextCards != false)
			{
				finishedChangingNextCards = false;
				this.swapChildren(cardBack, cardFront);
			}
			new GTween(cardFront, CARD_SWITCH_TIME, { rotation:0 } );
			var t:GTween = new GTween(rightHand, CARD_SWITCH_TIME, { rotation:0 } );
			t.onComplete = completeCardChange;
		}
		private function previousCard(event:MouseEvent=null):void {
			if (clickingDisabled != true)
			{
				changingCard = true;
				currentAnimationIsNextCard = false;
				dispatchEvent(new FlashCardsEvent(FlashCardsEvent.HAND_CLICKED, "previous"));
			}
		}
		protected function previousCardReadyToGo():void
		{
			cardBack.cardClip.x = 94
			cardBack.x = -64
			if (finishedChangingPreviousCards != true) {
				this.swapChildren(cardBack, cardFront);
				finishedChangingPreviousCards = true;
			}
			fadeInHands();
			new GTween(cardBack, CARD_SWITCH_TIME, { rotation:-CARD_ROTATION_DEGREE } );
			var t:GTween = new GTween(leftHand, CARD_SWITCH_TIME, { rotation: -CARD_ROTATION_DEGREE } );
			t.onComplete = previousCardTweenBack;
		}
		private function previousCardTweenBack(tween:GTween = null):void {
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.SWITCHING_CARDS, "previous"));
			if (finishedChangingPreviousCards != false) {
				finishedChangingPreviousCards = false;
				this.swapChildren(cardBack, cardFront);
			}
			new GTween(cardBack, CARD_SWITCH_TIME, { rotation:0 } );
			var t:GTween = new GTween(leftHand, CARD_SWITCH_TIME, { rotation:0 } );
			t.onComplete = completeCardChange;
		}
		public function completeCardChange(tween:GTween = null):void {
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.CARD_SWITCH_COMPLETE, "previous"));
			this.swapChildren(cardBack, cardFront);
			updateCardScrollBars();
			checkScrollBars();
			frontCardScroll.setVScroll(0);
			backCardScroll.setVScroll(0);
			finishedChangingPreviousCards = true;
			finishedChangingNextCards = true;
			changingCard = false;
			if (this.getChildIndex(cardFront) < this.getChildIndex(cardBack)) {
				this.swapChildren(cardBack, cardFront);
			}
			fadeOutHands();
		}
		public function checkScrollBars():void {
			if (frontCardScroll.showVertScrollBar) {
				new GTween(rightHand, .2, { rotation:17 } );
			}
			else {new GTween(rightHand, .1, { rotation:0 } );}
		}
		public function shuffleCardsAnimation():void {
			new GTween(cardFront, .5, { y: 1200 } );
			new GTween(cardBack, .5, { y: 1200 } );
			new GTween(leftHand, .5, { y:1200 } );
			var t:GTween = new GTween(rightHand, .5, { y:1200 } );
			t.onComplete = continueToShuffleCards;
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.SHUFFLING_CARDS));
		}
		public function continueToShuffleCards(event:GTween):void {
			new GTween(cardFront, .2, { y: 475 } );
			new GTween(cardBack, .2, { y: 475 } );
			new GTween(leftHand, .2, { y:525 } );
			new GTween(rightHand, .2, { y:525 } );
			checkTextScroll()
		}
		public function changeDeck():void
		{
			fadeInHands();
			clickingDisabled = true;
			rightHand.gotoAndStop(4);
			leftHand.gotoAndStop(2);
			var randRot:Number = Math.floor(Math.random() * 70);
			var negOrPos:Number = Math.random();
			if (negOrPos <= .5) negOrPos = -1;
			else if (negOrPos > .5) negOrPos = 1;
			rightHand.arrow.visible = false;
			leftHand.arrow.visible = false;
			new GTween(cardFront, .2, { rotation:randRot * negOrPos, y: -500 } );
			randRot = Math.floor(Math.random() * 70);
			negOrPos = Math.random();
			if (negOrPos <= .5) negOrPos = -1;
			else if (negOrPos > .5) negOrPos = 1;
			new GTween(cardBack, .2, { rotation: randRot * negOrPos, y: -500 } );
			new GTween(leftHand, .15, { rotation: -15, y:leftHand.y-100 } );
			var t:GTween = new GTween(rightHand, .15, { rotation: 15, y:rightHand.y - 100 } );
			t.onComplete = continueToChangeDeck;
		}
		public function continueToChangeDeck(tween:GTween = null):void {
			var x:Number = Engine(this.parent).previousDeckCardAmount;
			if (x > 100) { x = 100; }
			this.dispatchEvent(new FlashCardsEvent(FlashCardsEvent.DROP_CARDS, {num:x, delay:1, max: Math.ceil(Math.pow((x/53), 3))}));
			new GTween(leftHand, .15, { rotation: -30, y:800, overwrite:false} );
			var t:GTween = new GTween(rightHand, .15, { rotation: 30, y:800, overwrite:false} );
			t.onComplete = bringDeckBack;
		}
		public function bringDeckBack(tween:GTween = null):void
		{
			cardFront.y = cardBack.y = leftHand.y = rightHand.y = 900;
			cardFront.rotation = cardBack.rotation = leftHand.rotation = rightHand.rotation = 0;
			var t:GTween = new GTween(cardFront, .15, { rotation: 0, y:475 } );// , ease:Back.easeOut } );
			t.onComplete = checkTextScroll;
			new GTween(cardBack, .15, { rotation: 0, y:475 } );//, ease:Back.easeOut} );
			new GTween(leftHand, .15, { rotation: 0, y:525 } );//, ease:Back.easeOut} );
			new GTween(rightHand, .15, { rotation: 0, y:525 } );//, ease:Back.easeOut} );
			rightHand.arrow.visible = true;
			leftHand.arrow.visible = true;
			clickingDisabled = false;
			fadeOutHands();
		}
		public function checkTextScroll(tween:GTween = null):void {
			if (frontCardScroll.showVertScrollBar) {
				new GTween(rightHand, .2, { rotation:17 } );
			}
			else { new GTween(rightHand, .1, { rotation:0 } ); }
		}
		public function setCardText(newText:String, cardNum:Number = 0, front:Boolean = true):void {
			if (front == true)
			{
				removeFrontImage();
				frontCardText.cardText.text = newText;
				if (cardNum == 0)
				{
					cardFront.cardClip.cardNumber.text = "";
				}
				else
				{
					cardFront.cardClip.cardNumber.text = "("+cardNum+")";
				}
			}
			else
			{
				removeBackImage();
				backCardText.cardText.text = newText;
				if (cardNum == 0)
				{
					cardBack.cardClip.cardNumber.text = "";
				}
				else
				{
					cardBack.cardClip.cardNumber.text = "("+cardNum+")";
				}
			}
			setStyleFormat();
			if(Accessibility.active)
			{
				hackRefocus(this, newText);
			}
		}
		protected function removeBackImage():void
		{
			if( _backImage != null && _backImage.parent == cardBack.cardClip)
			{
				cardBack.cardClip.removeChild(_backImage);
				_backImage = null;
			}
		}
		protected function removeFrontImage():void
		{
			if(_frontImage != null && _frontImage.parent == cardFront.cardClip)
			{
				cardFront.cardClip.removeChild(_frontImage);
				_frontImage = null;
			}
		}
		public function setCardImage(image:*, cardNum:int = 0, front:Boolean = true):void
		{
			var curCard:MovieClip;
			if( front == true)
			{
				frontCardText.cardText.text = "";
				curCard = cardFront;
				removeFrontImage();
				_frontImage = image;
			}
			else
			{
				backCardText.cardText.text = "";
				curCard = cardBack;
				removeBackImage();
				_backImage = image;
			}
			// shrink image to fit
			var cardWidth:Number = curCard.cardClip.width;
			var cardHeight:Number = curCard.cardClip.height;
			var imageWidth:Number = image.width;
			var imageHeight:Number = image.height;
			var widthDiff:Number = imageWidth - cardWidth;
			var heightDiff:Number = imageHeight - cardHeight;
			if( widthDiff > 0 || heightDiff > 0)
			{
				const MINIMUM_PADDING:Number = 20.0;
				var scaleChange:Number;
				if( widthDiff > heightDiff)
				{
					// shrink the width
					scaleChange = (cardWidth - MINIMUM_PADDING)/ imageWidth;
					image.width *= scaleChange;
					image.height *= scaleChange;
				}
				else
				{
					// shrink the height
					scaleChange = (cardHeight - MINIMUM_PADDING)/ imageHeight;
					image.width *= scaleChange;
					image.height *= scaleChange;
				}
			}
			// now add it
			curCard.cardClip.addChild(image);
			// center it
			image.x = ( cardWidth - image.width ) / 2.0;
			image.y = ( cardHeight - image.height ) / 2.0;
			// set the card number
			if (cardNum == 0)
			{
				curCard.cardClip.cardNumber.text = "";
			}
			else
			{
				curCard.cardClip.cardNumber.text = "("+cardNum+")";
			}
			if(Accessibility.active)
			{
				hackRefocus(this,"Image");
			}
		}
		private function updateCardScrollBars():void {
			frontCardScroll.update();
			backCardScroll.update();
		}
		private function setStyleFormat():void {
			frontCardText.cardText.setTextFormat(newCardFormat);
			backCardText.cardText.setTextFormat(newCardFormat);
		}
		private function newFontSize(event:FontSizeSliderEvent):void {
			changeFontSize(event.sliderPosition);
		}
		private function changeFontSize(sliderPos:Number):void {
			switch (sliderPos) {
				case 1:
					newCardFormat.size = cardFontSize = 18;
					break;
				case 2:
					newCardFormat.size = cardFontSize = 22;
					break;
				case 3:
					newCardFormat.size = cardFontSize = 26;
					break;
				case 4:
					newCardFormat.size = cardFontSize = 30;
					break;
			}
			setStyleFormat();
			updateCardScrollBars();
			checkScrollBars();
		}
		public function get helpBtn():keyboardHelpButton
		{
			return theKeyboardHelpButton;
		}
		private function hackRefocus(obj:CardDisplay ,newName:String):void
		{
			stage.focus = null;
			this.accessibilityProperties.name = newName;
			Accessibility.updateProperties();
			var hack:Timer = new Timer(250,1);
			hack.addEventListener(TimerEvent.TIMER_COMPLETE, refocus,false,0,true);
			hack.start();
			function refocus(e:TimerEvent):void
			{
				hack.removeEventListener(TimerEvent.TIMER_COMPLETE, refocus);
				stage.focus = obj;
			}
		}
	}
}