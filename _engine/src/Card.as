/* See the file "LICENSE.txt" for the full license governing this code. */
/*
* NewMedia - CDWS - University of Central Florida newmedia.cdws.ucf.edu
* Keegan Berry --/--/--
*/
package {
	public class Card {
		private var _categoryNumber:Number
		private var _cardNumber:Number
		private var _front:String
		private var _back:String
		private var _new:Boolean
		public var frontAssetId:String = '-1';
		public var backAssetId:String = '-1';
		public function get isFrontImage():Boolean
		{
			return frontAssetId != '-1';
		}
		public function get isBackImage():Boolean
		{
			return backAssetId != '-1';
		}
		public function Card() { }
		public function set categoryNumber(catNum:Number):void {
			_categoryNumber = catNum
		}
		public function set cardNumber(cardNum:Number):void {
			_cardNumber = cardNum
		}
		public function set front(frontString:String):void {
			_front = frontString
		}
		public function set back(backString:String):void {
			_back = backString
		}
		public function get categoryNumber():Number {
			return _categoryNumber
		}
		public function get cardNumber():Number {
			return _cardNumber
		}
		public function get front():String {
			return _front
		}
		public function get back():String {
			return _back
		}
		public function toString():String {
			return "Card: "+_cardNumber+"<\n>";
		}
	}
}