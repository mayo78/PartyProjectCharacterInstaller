package;

import haxe.MainLoop;
import sys.thread.Thread;
import openfl.display.BitmapData;

using StringTools;

typedef LoadingDumb = {field:String, url:String};

class CharacterBitmapGroup {
	public var map:Map<String, BitmapData> = [];

	var loading:Int;

	public function new(data:CharacterData, onComplete:Map<String, BitmapData>->Void) {
		// lazy and dumb
		var toLoad:Array<LoadingDumb> = [];
		for (field in Reflect.fields(data.data)) {
			if (field.startsWith('url')) {
				final url = Reflect.field(data.data, field);
				trace('loading', url);
				loading++;
				toLoad.push({
					field: field,
					url: url,
				});
			}
		}
		Thread.create(() -> {
			while (toLoad.length > 0) {
				final a = toLoad.shift();
				BitmapData.loadFromFile(a.url).onError(onError).onComplete(bitmap -> {
					map.set(a.field, bitmap);
					loading--;
					if (loading == 0)
						MainLoop.runInMainThread(() -> onComplete(map));
				});
			}
		});
	}

	function onError(e:Dynamic) {
		trace('[ERROR] $e');
	}
}