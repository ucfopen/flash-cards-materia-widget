// Note: this class is not being used, it is safe to delete it
package {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	public class DeckCardManager extends EventDispatcher
	{
		var DELETE_THIS_CLASS_IT_IS_NOT_BEING_USED;
		private static const CARD_LABEL:String = "card";
		private static const CARDS_LABEL:String = "cards";
		public  static const UPDATE_TEXT_EVENT:String = "UPDATE_TEXT_EVENT";
		private var curSize:Number;
		private var tf:TextFormat;
		private var stillSelectable:Boolean = true;
		private var isFocused:Boolean = false;
		private var dragDetectionTimer:Timer = null; // when the mouse is held down for a bit, they are draggin instead of selecting
		private var _theCard:deckListDeckClip; // the movie clip this class is taking care of
		private var _theDeckTextField:TextField; // a text field found on _theCard
		public function DeckCardManager(theCard:deckListDeckClip)
		{
			_theCard = theCard;
			_theDeckTextField = theCard.deckText;
			_theCard.transparent.buttonMode = true;
			_theCard.deckText.addEventListener(Event.CHANGE, resizeFontToFit, false, 0, true);
			_theCard.transparent.addEventListener(MouseEvent.MOUSE_DOWN, startTimer, false, 0, true);
			_theCard.transparent.addEventListener(MouseEvent.MOUSE_UP, selectText, false, 0, true);
			_theCard.deckText.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, focusAway, false, 0, true);
		}
		public function destroy():void
		{
			_theCard.deckText.removeEventListener(Event.CHANGE, resizeFontToFit);
			_theCard.transparent.removeEventListener(MouseEvent.MOUSE_DOWN, startTimer);
			_theCard.transparent.removeEventListener(MouseEvent.MOUSE_UP, selectText);
			_theCard.deckText.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, focusAway);
		}
		private function resizeFontToFit(event:Event=null):void
		{
			curSize = 19;
			tf = new TextFormat();
			tf.size = curSize;
			_theDeckTextField.setTextFormat(tf);
			while ((_theDeckTextField.textHeight > 38) || (_theDeckTextField.textWidth > 80))
			{
				tf = new TextFormat();
				tf.size = curSize--;
				tf.leading = -2;
				_theDeckTextField.setTextFormat(tf);
			}
			if(event != null) event.stopPropagation();
			dispatchEvent(new Event(UPDATE_TEXT_EVENT));
		}
		private function selectText(event:MouseEvent):void
		{
			if (stillSelectable == true)
			{
				if(dragDetectionTimer != null)
				{
					dragDetectionTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerIsDone);
					dragDetectionTimer.stop();
				}
				var theDeckText:TextField = TextField(_theCard.deckText);
				theDeckText.setSelection(0,theDeckText.text.length);
			}
		}
		private function startTimer(event:MouseEvent):void
		{
			stillSelectable = true;
			dragDetectionTimer = new Timer(25, 5);
			dragDetectionTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerIsDone, false, 0, true);
			dragDetectionTimer.start();
		}
		private function timerIsDone(event:TimerEvent):void
		{
			dragDetectionTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerIsDone);
			stillSelectable = false;
		}
		private function focusAway(event:FocusEvent):void
		{
			isFocused = false;
		}
		/**
		 * Getters and setters.
		 */
		public function set name(name:String):void
		{
			_theCard.deckText.text = name;
			resizeFontToFit();
			//_theCard.resizeFontToFit();
		}
		public function get name():String
		{
			return _theCard.deckText.text;
		}
		public function set numCards(num:int):void
		{
			if(num == 1) _theCard.deckNum.text = num + " " + CARD_LABEL;
			else _theCard.deckNum.text = num + " " + CARDS_LABEL;
		}
	}
}