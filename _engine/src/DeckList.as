/* See the file "LICENSE.txt" for the full license governing this code. */
package {
	import com.gskinner.motion.GTween;
	import events.FlashCardsEvent;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.*;
	public class DeckList extends Sprite {
		private var list:Sprite;
		private var itemArray:Array;
		private var currentItem:MovieClip;
		public var selectedNumber:Number;
		private static const MAX_ITEMS:Number = 6;
		private var shuffleButton:shuffleDeckButton;
		public function DeckList()
		{
			////trace("HELLO, I AM THE DECK LIST");
			list = new Sprite();
			itemArray = new Array;
			this.addChild(list);
			list.addEventListener(MouseEvent.MOUSE_DOWN, onMouseAction, false, 0, true);
			list.addEventListener(MouseEvent.MOUSE_UP, onMouseAction, false, 0, true);
			shuffleButton = new shuffleDeckButton();
			this.addChild(shuffleButton);
			shuffleButton.addEventListener(MouseEvent.CLICK, shuffleButtonPressed, false, 0, true);
			///shuffleButton.y -= shuffleButton.height;
			//shuffleButton.x = 140;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		private function onAddedToStage(event:Event):void {
			//nothing
		}
		private function shuffleButtonPressed(event:MouseEvent):void {
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.SHUFFLE_BUTTON_PRESSED, "Shuffle_Deck"));
		}
		public function addItem(title:String, numOfCards:Number):void {
			if (itemArray.length <5) {
				////trace("adding item");
				////trace(title);
				////trace(numOfCards);
				var newDeck:DeckAsset = new DeckAsset();
				this.addChildAt(newDeck, 0);
				if (numOfCards == 1) newDeck.topCard.cardNum.text = "1 Card";
				else newDeck.topCard.cardNum.text = numOfCards + " Cards";
				var cardFormat:TextFormat = new TextFormat();
				cardFormat.leading = -3;
				newDeck.topCard.cardText.defaultTextFormat = cardFormat;
				newDeck.topCard.cardText.text = title;
				newDeck.topCard.cardNum.text = numOfCards + " cards";
				newDeck.useHandCursor = true;
				//newDeck.topCard.cardText.autoSize = TextFieldAutoSize.CENTER;
				var curSize:Number = 19;
				while ((newDeck.topCard.cardText.textHeight > 38) || (newDeck.topCard.cardText.textWidth > 70)) {
					////trace("TOO BIG!!!! "+curSize);
					var tf:TextFormat = new TextFormat();
					tf.size = curSize--;
					newDeck.topCard.cardText.setTextFormat(tf);
				}
				newDeck.topCard.cardText.height = newDeck.topCard.cardText.textHeight + 5;
				newDeck.topCard.cardText.y = 2 - newDeck.topCard.cardText.textHeight / 2 - 8;
				newDeck.y = (itemArray.length) * (newDeck.height - 2) + (newDeck.height/2)+30;
				newDeck.x = 4;
				newDeck.topCard.cardNum.visible = true;
				newDeck.topCard.cardText.visible = true;
				itemArray.push(newDeck);
				var randRot:Number = Math.floor(Math.random() * 6);
				var negOrPos:Number = Math.random();
				if (negOrPos <= .5) negOrPos = -1;
				else if (negOrPos > .5) negOrPos = 1;
				newDeck.rotation = randRot * negOrPos;
				newDeck.addEventListener(MouseEvent.CLICK, onClickItem, false, 0, true);
				newDeck.addEventListener(MouseEvent.ROLL_OVER, onMouseOverItem, false, 0, true);
				newDeck.addEventListener(MouseEvent.ROLL_OUT, onMouseOutItem, false, 0, true);
				this.removeChild(shuffleButton);
				shuffleButton = new shuffleDeckButton();
				this.addChild(shuffleButton);
				shuffleButton.addEventListener(MouseEvent.CLICK, shuffleButtonPressed, false, 0, true);
			//	addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
		}
		private function onMouseAction(event:MouseEvent):void {
			if (event.type == MouseEvent.MOUSE_DOWN) {
				////trace("DOWN");
			}
			else if (event.type == MouseEvent.MOUSE_UP) {
				////trace("UP");
			}
		}
		private function onClickItem(event:MouseEvent):void {
			var selectedItem:MovieClip = event.currentTarget as MovieClip;
			pushBackPrevious();
			var glow:GlowFilter = new GlowFilter();
			glow.color = 0xff00cc;
			glow.alpha = .50;
			glow.blurX = glow.blurY = 15;
			selectedItem.filters = [glow];
			selectedItem.gotoAndStop(9);
			currentItem = selectedItem;
			shuffleButton.y = selectedItem.y //-shuffleButton.height/2//+(selectedItem.height/2)
			shuffleButton.x = selectedItem.x+18;// + selectedItem.width - 55;
			shuffleButton.rotation = selectedItem.rotation;
			shuffleButton.alpha = 0;
			new GTween(shuffleButton, .3, { alpha:1 } );
			var itemArrayLen:Number = itemArray.length;
			for (var i:Number = 0; i < itemArrayLen; i++){
				if (itemArray[i] == currentItem) selectedNumber = i;
			}
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.DECK_CLICKED, String(selectedNumber)));
		}
		private function pushBackPrevious():void {
			var itemArrayLen:Number = itemArray.length;
			for (var i:Number = 0; i < itemArrayLen; i++){
				itemArray[i].filters = [];
				itemArray[i].gotoAndStop(1);
			}
		}
		private function onMouseOverItem(event:MouseEvent):void {
			var selectedItem:MovieClip = event.currentTarget as MovieClip;
			if (currentItem != selectedItem) {
				selectedItem.gotoAndPlay("pushOut");
			}
		}
		private function onMouseOutItem(event:MouseEvent):void {
			var selectedItem:MovieClip = event.currentTarget as MovieClip;
			if (currentItem != selectedItem) {
				selectedItem.gotoAndStop(1);
			}
		}
		public function selectItem(itemNum:Number):void
		{
			selectedNumber = itemNum;
			currentItem = itemArray[selectedNumber];
			pushBackPrevious();
			var glow:GlowFilter = new GlowFilter();
			glow.color = 0xff00cc;
			glow.alpha = .50;
			glow.blurX = glow.blurY = 15;
			currentItem.filters = [glow];
			currentItem.gotoAndStop(9);
			shuffleButton.y = currentItem.y //-shuffleButton.height/2//+(selectedItem.height/2)
			shuffleButton.x = currentItem.x+18;
			shuffleButton.rotation = currentItem.rotation;
			shuffleButton.alpha = 0;
			new GTween(shuffleButton, .3, { alpha:1 } );
			dispatchEvent(new FlashCardsEvent(FlashCardsEvent.DECK_CLICKED, String(selectedNumber)));
		}
	}
}