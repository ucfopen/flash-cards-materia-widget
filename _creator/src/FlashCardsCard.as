package {
	import flash.events.EventDispatcher; // event dispatcher so data binding can happen?
	public class FlashCardsCard extends EventDispatcher
	{
		// i dont think these need to be bindable anymore
		[Bindable] public var question:String = "";
		[Bindable] public var answer:String = "";
		[Bindable] public var cid:int;
		[Bindable] public var id:int = 0;
		// if the sides are set to show images
		public var isFrontAnImage:Boolean = false;
		public var isBackAnImage:Boolean = false;
		// the image data for the cards
		public var frontImageData:Object = {assetId:-1, source:null};
		public var backImageData:Object = {assetId:-1, source:null};
		public function FlashCardsCard(theCid:int, theQuestion:String, theAnswer:String, id:int = 0)
		{
			cid = theCid;
			answer = theAnswer;
			question = theQuestion;
			this.id = id;
		}
		public function isEdited():Boolean
		{
			if( question != "" || answer != "" || frontImageData.assetId != -1 || backImageData.assetId != -1 )
			{
				return true;
			}
			return false;
		}
		public function copy():FlashCardsCard
		{
			return new FlashCardsCard(cid, question, answer, id);
		}
		// swap the front and back images
		public function swapImages():void
		{
			var tempB:Boolean = isFrontAnImage;
			isFrontAnImage = isBackAnImage;
			isBackAnImage = tempB;
			var tempO:Object = frontImageData;
			frontImageData = backImageData;
			backImageData = tempO;
		}
	}
}