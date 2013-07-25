/* See the file "LICENSE.txt" for the full license governing this code. */
package events
{
	import flash.events.Event;
	/**
	* ...
	* @author DefaultUser (Tools -> Custom Arguments...)
	*/
	public class FontSizeSliderEvent extends Event
	{
		public static const INCREASE_FONT:String = "increaseFont";
		public static const DECREASE_FONT:String = "decreaseFont";
		public static const SLIDER_POS_CHANGE:String = "sliderPositionChanged";
		public var sliderPosition:Number;
		public function FontSizeSliderEvent(type:String, sliderPosition:Number=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.sliderPosition = sliderPosition;
			super(type, bubbles, cancelable);
		}
		public override function clone():Event
		{
			return new FontSizeSliderEvent(type, sliderPosition, bubbles, cancelable);
		}
		public override function toString():String
		{
			return formatToString("FontSizeSlider", "type", "bubbles", "cancelable", "eventPhase");
		}
	}
}