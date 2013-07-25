/* See the file "LICENSE.txt" for the full license governing this code. */
package  {
import events.FontSizeSliderEvent;
import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	public class FontSizeSlider extends Sprite
	{
		private var fontSizeSliderBar:FontSizeSliderBar;
		private var sliderMove:Boolean;
		private var defaultSliderPosition:Number;
		private var defaultBoxWidth:Number;
		private var sliderXPos:Number;
		private var slider:MovieClip;
		private var larger:MovieClip;
		private var smaller:MovieClip;
		private var bar:MovieClip;
		private var maxSliderPositions:Number;
		private var currentSliderPosition:Number;
		public function FontSizeSlider(maxSliderPositions:int=4):void
		{
			maxSliderPositions = 4;
			//manualFontChangeOverride = false;
			fontSizeSliderBar = new FontSizeSliderBar();
			this.addChild(fontSizeSliderBar);
			slider = fontSizeSliderBar.slider;
			larger = fontSizeSliderBar.larger;
			smaller = fontSizeSliderBar.smaller;
			bar	= fontSizeSliderBar.bar;
			defaultSliderPosition = slider.x;
			defaultBoxWidth = this.width;
			larger.addEventListener(MouseEvent.CLICK, increaseFontSize, false, 0, true);
			smaller.addEventListener(MouseEvent.CLICK, decreaseFontSize, false, 0, true);
			slider.addEventListener(MouseEvent.MOUSE_DOWN, startDraggingSlider, false, 0, true);
			slider.buttonMode = true;
			slider.useHandCursor = true;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		private function onAddedToStage(event:Event):void {
			slider.x = 15 + bar.x;
			sliderXPos = slider.x - bar.x;
			currentSliderPosition = 2;
			setSliderPosition(currentSliderPosition);
		}
		public function increaseFontSize(event:MouseEvent=null):void
		{
			if (currentSliderPosition == 1)
				{
					currentSliderPosition = 2;
					slider.x = 16 + bar.x;
				}
			else if (currentSliderPosition == 2)
				{
					currentSliderPosition = 3;
					slider.x = 26 + bar.x;
				}
			else if (currentSliderPosition == 3)
				{
					currentSliderPosition = 4;
					slider.x = 36 + bar.x;
				}
			else if (currentSliderPosition == 4)
				{
					currentSliderPosition = 4;
					slider.x = 36 + bar.x;
				}
			//manualFontChangeOverride = true;
			sliderXPos = slider.x - bar.x;
			setSliderPosition(currentSliderPosition);
			//////trace("ADJUSTING SLIDER, CURRENTLY: " + currentSliderPosition);
			//currentSliderPosition++;
			//if (currentSliderPosition >4) {currentSliderPosition = 4}
			//
			//if ((currentSliderPosition >= 1) || (currentSliderPosition <= 4)) {
				//currentSliderPosition++;
				//if (currentSliderPosition >4) {currentSliderPosition = 4}
			//}
			//////trace("ADJUSTING SLIDER, NOW: "+currentSliderPosition);
			//setSliderPosition(currentSliderPosition);
			//manuallyMoveSlider(currentSliderPosition);
		}
		public function decreaseFontSize(event:Event=null):void
		{
			if (currentSliderPosition == 1)
				{
					currentSliderPosition = 1;
					slider.x = 8 + bar.x;
				}
			else if (currentSliderPosition == 2)
				{
					currentSliderPosition = 1;
					slider.x = 8 + bar.x;
				}
			else if (currentSliderPosition == 3)
				{
					currentSliderPosition = 2;
					slider.x = 16 + bar.x;
				}
			else if (currentSliderPosition == 4)
				{
					currentSliderPosition = 3;
					slider.x = 26 + bar.x;
				}
			//manualFontChangeOverride = true;
			sliderXPos = slider.x - bar.x;
			setSliderPosition(currentSliderPosition);
			//////trace("ADJUSTING SLIDER, CURRENTLY: " + currentSliderPosition);
			//currentSliderPosition--;
			//if (currentSliderPosition <1) {currentSliderPosition = 1}
				//
			//if ((currentSliderPosition >= 1) || (currentSliderPosition <= 4)) {
				//currentSliderPosition--;
				//if (currentSliderPosition <1) {currentSliderPosition = 1}
			//}
			//////trace("ADJUSTING SLIDER, NOW: "+currentSliderPosition);
			//setSliderPosition(currentSliderPosition);
			//manuallyMoveSlider(currentSliderPosition);
		}
		private function largerClicked(event:MouseEvent):void {
			dispatchEvent(new FontSizeSliderEvent(FontSizeSliderEvent.INCREASE_FONT, currentSliderPosition));
		}
		private function smallerClicked(event:MouseEvent):void {
			dispatchEvent(new FontSizeSliderEvent(FontSizeSliderEvent.DECREASE_FONT, currentSliderPosition));
		}
		private function startDraggingSlider(event:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, stopDraggingSlider, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, tryToDragSlider, false, 0, true);
			sliderMove = true;
		}
		private function stopDraggingSlider(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraggingSlider);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, tryToDragSlider);
			sliderMove = false;
			//slider.x = defaultSliderPosition;
		}
		private function setSliderPosition(newSliderPosition:Number):void
		{
			dispatchEvent(new FontSizeSliderEvent(FontSizeSliderEvent.SLIDER_POS_CHANGE, newSliderPosition));
		}
		public function manuallyMoveSlider(sliderPosition:Number):void {
			slider.x = 15 * currentSliderPosition + bar.x;
			switch(currentSliderPosition) {
				case 1:
					slider.x = 20// + bar.x;
					break;
				case 2:
					slider.x = 35// + bar.x;
					break;
				case 3:
					slider.x = 45// + bar.x;
					break;
				case 4:
					slider.x = 100// + bar.x;
					break;
				case 5:
					slider.x = 100// + bar.x;
					break;
			}
		}
		private function tryToDragSlider(event:MouseEvent):void
		{
			var localMouseX:Number = this.globalToLocal(new Point(event.stageX, event.stageX)).x;
			slider.x = localMouseX - slider.width/2;
			if ((mouseY < 0) || (mouseY > fontSizeSliderBar.height)) { sliderMove = false; }
			if ((mouseX < 10) || (mouseX > defaultBoxWidth)) { sliderMove = false; }
			var sliderMidPos:Number = slider.x + slider.width / 2;
			var sliderLeftPos:Number = slider.x;
			var sliderRightPos:Number = slider.x+slider.width;
			if (sliderLeftPos < bar.x) {
				slider.x = bar.x;
			}
			if (sliderRightPos > (bar.x + bar.width)) {
				slider.x = bar.x + bar.width - slider.width;
			}
			sliderXPos = slider.x - bar.x;
			if (((sliderXPos <= 0) || ((sliderXPos > 0) && (sliderXPos <= 10))) && (currentSliderPosition != 1)) {
				currentSliderPosition = 1;
				setSliderPosition(currentSliderPosition);
				//////trace("change font size to 1");
			}
			if (((sliderXPos > 10) && (sliderXPos <= 20)) && (currentSliderPosition != 2)) {
				currentSliderPosition = 2;
				setSliderPosition(currentSliderPosition);
				//////trace("change font size to 2");
			}
			if (((sliderXPos > 20) && (sliderXPos <= 30)) && (currentSliderPosition != 3)) {
				currentSliderPosition = 3;
				setSliderPosition(currentSliderPosition);
				//////trace("change font size to 3");
			}
			if (((sliderXPos > 30) && (sliderXPos <= 40)) && (currentSliderPosition != 4)) {
				currentSliderPosition = 4;
				setSliderPosition(currentSliderPosition);
				//////trace("change font size to 4");
			}
		}
	}
}