/* See the file "LICENSE.txt" for the full license governing this code. */
package events
{
	import flash.events.Event;
	/**
	* ...
	* @author DefaultUser (Tools -> Custom Arguments...)
	*/
	public class FlashCardsEvent extends Event
	{
		public static const DECK_CLICKED:String = "deckClicked";
		public static const HAND_CLICKED:String = "handClicked";
		public static const CARD_CLICKED:String = "cardClicked";
		public static const SWITCHING_CARDS:String = "switchingCards";
		public static const CARD_SWITCH_COMPLETE:String = "cardSwitchComplete";
		public static const SHUFFLING_CARDS:String = "shufflingCards";
		public static const SHUFFLE_BUTTON_PRESSED:String = "shuffle_button_pressed";
		public static const KEYBOARD_BUTTON_PRESSED:String = "keyboard_button_pressed";
		public static const DROP_CARDS:String = "drop_cards";
		public var data:Object;
		public function FlashCardsEvent(type:String, data:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			if (data == null) {
				data = new Object();
			}
			this.data = data;
			super(type, bubbles, cancelable);
		}
		public override function clone():Event
		{
			return new FlashCardsEvent(type, data, bubbles, cancelable);
		}
		public override function toString():String
		{
			return formatToString("FlashCardsEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}