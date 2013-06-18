package {
	import flash.display.Graphics;
	import flash.display.Sprite;
	import mx.controls.TileList;
	import mx.controls.listClasses.IListItemRenderer;
	public class FlashCardsRoundedSelectionTileList extends TileList
	{
		private var selectionWidth:int	= 132;
		private var selectionHeight:int = 92;
		public function FlashCardsRoundedSelectionTileList()
		{
			super();
		}
		override protected function drawSelectionIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void {
			var g:Graphics= indicator.graphics;
			g.clear();
			g.beginFill(0xFFFFFF, .033);
			g.lineStyle(2,0x3399CC);
			g.drawRoundRect(x+(width-selectionWidth)/2 - 3,y, selectionWidth,selectionHeight,15,15);
			g.endFill();
		}
		override protected function drawHighlightIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void {
			var g:Graphics = indicator.graphics;
			g.clear();
			g.beginFill(0x3399CC, .1);
			g.lineStyle(2,0x759CB3);
			g.drawRoundRect(x+(width-selectionWidth)/2 - 3,y, selectionWidth,selectionHeight,15,15);
			g.endFill();
		}
		override protected function drawCaretIndicator(indicator:Sprite, x:Number, y:Number, width:Number, height:Number, color:uint, itemRenderer:IListItemRenderer):void
		{
			// hide the focus rectangle
		}
	}
}