package {
	import flash.events.Event;
	public class FlashCardsEvent extends Event
	{
		public static const CARD_UPDATED:String = "cardUpdated";
		public static const CARD_TEXT_CLICKED:String = "cardTextClicked";
		public static const CARD_TEXT_OUT:String = "cardTextOut";
		public static const SWAPCARDS_BUTTON_PRESSED:String = "swapCardsButtonPressed";
		public static const DELETE_BUTTON_PRESSED:String = "deleteButtonPressed";
		public static const EXPAND_BUTTON_PRESSED:String = "expandButtonPressed";
		public static const DECK_CLICKED:String = "deckClicked";
		public static const DECK_HOVER:String = "deckHover";
		public static const DECK_PLAY_ANIMATION:String = "deckPlayAnimation";
		public static const DECK_FORCE_CHECK:String = "deckForceCheck";
		public static const DECK_SAVE_TITLE:String = "deckSaveTitle";
		public static const DISABLE_DRAGGING:String = "disableDragging";
		public static const ENABLE_DRAGGING:String = "enableDragging"
		public var data:Object;
		public function FlashCardsEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
	}
}