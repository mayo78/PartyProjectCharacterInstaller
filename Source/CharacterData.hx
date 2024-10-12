package;

typedef CharacterData = {
	@:default(true)
	var c2dictionary:Bool; // always true??

	var data:{
		var name:String;

		var longName:String;

		var author:String;

		var urlSprites:String; // character sprites

		var urlFront:String; // icon

		var urlSide:String; // side icon

		var urlStart:String;

		var urlSticker1:String;

		var urlSticker2:String;

		@:default(3)
		var runFrames:Int;
	};
}