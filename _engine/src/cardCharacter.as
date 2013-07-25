/* See the file "LICENSE.txt" for the full license governing this code. */
package {
	import flash.display.MovieClip;
	import flash.display.Sprite;
	public class cardCharacter extends Sprite
	{
		//private var torso:CharacterTorso;
		//private var headmc:CharacterHead;
		//private var randHead:Number;
		//private var isF:Boolean;
		//private var theRobotCharacter:robotCharacter;
		private var bodies:characterBodies;
		private var randChar:Number;
		public function cardCharacter() {
			////trace("HELLO, FOR I AM THE CARD CHARACTER");
			bodies = new characterBodies();
			this.addChild(bodies);
			randChar = Math.floor(Math.random() * 46)+1;
			bodies.characters.gotoAndStop(randChar);
			/*theRobotCharacter:robotCharacter = new robotCharacter();
			this.addChild(theRobotCharacter);
			theRobotCharacter.x = 0;
			theRobotCharacter.y = 0;
			torso = new CharacterTorso();
			headmc = new CharacterHead();
			this.addChild(headmc);
			headmc.x = 156;
			headmc.y = 0;
			var randHead:Number;
			randHead = Math.random();
			if (randHead > .5) {
				headmc.female.visible = true;
				headmc.male.visible = false;
				isF = true;
			}
			else if (randHead <= .5) {
				headmc.female.visible = false;
				headmc.male.visible = true;
				isF = false;
				//var newRand:Number = Math.random();
				//if (newRand <= .5)
					//newRand = 1;
				//else
					//newRand = 2;
				//headmc.male.accessories.gotoAndPlay(newRand);
			}
			this.addChild(torso);
			torso.x = 0;
			torso.y = 195;*/
		}
		public function get randomCharacterNum():Number {
			return randChar;
		}
		/*public function get gender():Boolean {
			return isF;
		}
		public function get randCharacter():Number {
			return randHead;
		}
		public function get head():CharacterHead {
			return headmc;
		}
		public function set head(newHead:CharacterHead):void {
			headmc = newHead;
		}	*/
	}
}