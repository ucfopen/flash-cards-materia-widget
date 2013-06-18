package {
	import flash.events.EventDispatcher;
	import mx.collections.ArrayCollection;
	public class FlashCardsDeck extends EventDispatcher
	{
		[Bindable] public var cards:ArrayCollection;
		[Bindable] public var decks:ArrayCollection;
		[Bindable] public var name:String;
		public function FlashCardsDeck()
		{
		}
	}
}