/* See the file "LICENSE.txt" for the full license governing this code. */
/*
* NewMedia - CDWS - University of Central Florida newmedia.cdws.ucf.edu
* Keegan Berry --/--/--
*/
package {
	public class Deck {
		private var _cards:Array
		private var _name:String
		private var _category:Number
		function Deck(){
			_cards = new Array()
		}
		public function set name(nameString:String):void {
			_name = nameString
		}
		public function set category(catNum:Number):void {
			_category = catNum
		}
		public function get name():String {
			return _name
		}
		public function get cards():Array {
			return _cards
		}
		public function set cards(cards:Array):void {
			_cards = cards
		}
		public function get category():Number {
			return _category
		}
		public function addCard(card:Card):void{
			cards.push(card)
		}
	}
}