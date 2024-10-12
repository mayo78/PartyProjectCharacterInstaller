package;

import openfl.display.FPS;
import openfl.events.Event;
import openfl.display.Tilemap;
import openfl.geom.Matrix;
import NiceBox.NiceBoxEvent;
import haxe.MainLoop;
import sys.thread.Thread;
import lime.ui.FileDialog;
import sys.io.File;
import sys.FileSystem;
import openfl.display.Sprite;
import openfl.net.FileReference;

class Main extends Sprite {
	static var parser = new json2object.JsonParser<CharacterData>([]); // only used for reading imported jsons

	var file = new FileReference();

	var done = false;

	var boxes = new Sprite();

	var bg = new Sprite();

	var bgTile = new Sprite();

	var tileOffset:Float;

	var canSelect = true;

	public function new() {
		super();

		stage.application.window.onDropFile.add(onDropFile);
		stage.application.window.onResize.add(onResize);
		stage.addEventListener(Event.ENTER_FRAME, enterFrame);

		var mat = new Matrix();
		mat.createGradientBox(100, 100, 90 * (Math.PI/180), 0, 0);

		bg.graphics.clear();
		bg.graphics.beginGradientFill(LINEAR, [0xFF6D6D6D, 0xFF323232],  null, [0x00, 0xFF], mat, REFLECT);
		bg.graphics.drawRect(0, 0, 100, 100);
		bg.graphics.endFill();
		bg.graphics.beginFill(0xFF000000, .8);
		bg.graphics.drawRect(0, 0, 100, 15);
		bg.graphics.drawRect(0, 85, 100, 15);
		bg.graphics.endFill();
		addChild(bg);

		bgTile.blendMode = ADD;
		addChild(bgTile);

		addChild(new FPS());

		var loadJsonBox = new NiceBox('Import Character(s)', false);
		loadJsonBox.addEventListener(NiceBoxEvent.NICEBOX_CLICK, e -> {
			if (canSelect) {
				canSelect = false;
				getPartyPath(_ -> {
					var popup = new FileDialog();
					//popup.onSelectMultiple.add(files -> {
					//	for (file in files) 
					//		onDropFile(file);
					//});
					popup.onCancel.add(() -> canSelect = true);
					popup.browse(OPEN_MULTIPLE);
				}, () -> canSelect = true);
			}
		});
		boxes.addChild(loadJsonBox);

		var setPartyPathBox = new NiceBox('Set Path to Party Project', true);
		setPartyPathBox.addEventListener(NiceBoxEvent.NICEBOX_CLICK, e -> {
			if (canSelect) {
				canSelect = false;
				getPartyPath(_ -> canSelect = true, () -> canSelect = true, true);
			}
		});
		setPartyPathBox.y = 82;
		boxes.addChild(setPartyPathBox);

		addChild(boxes);
		onResize(stage.application.window.width, stage.application.window.height);
	}

	function enterFrame(e) {
		final w = stage.application.window.width;
		final h = stage.application.window.height;
		final s = Math.max(w, h) * .1;
		final endH = 15 * bg.scaleY;
		var ww = tileOffset;
		var hh = endH;
		var tile = false;
		bgTile.graphics.clear();
		bgTile.graphics.beginFill(0xFFFFFFFF, .2);
		tileOffset++;
		if (tileOffset >= 0)
			tileOffset = -s * 2;
		while (hh < (h - endH)) {
			bgTile.graphics.drawRect(ww, hh, s, (Math.min(hh + s, h - endH) - hh));
			ww += s * 2;
			if (ww > w) {
				tile = !tile;
				ww = (tile ? s : 0) + tileOffset;
				hh += s;
			}
		}
	}

	function onResize(w:Int, h:Int) {
		boxes.height = h * .8;
		boxes.scaleX = boxes.scaleY;
		boxes.x = (w - boxes.width) * .5;
		boxes.y = (h - (154 * boxes.scaleY)) * .5;
		bg.width = w;
		bg.height = h;
		stage.application.window.minWidth = Math.ceil(boxes.width + 50);
	}

	function onDropFile(file:String):Void {
		trace('file $file dropped');
		if (canSelect) {
			final path = new haxe.io.Path(file);
			switch path.ext {
				case 'json':
					trace('loading json $file');
					loadJson(file);
					// File.saveContent(FileSystem.)
					// trace();
			}
		}
	}

	// loads a json
	function loadJson(file:String):Void {
		final rawJson = File.getContent(file);
		final data = parser.fromJson(rawJson);
		for (error in parser.errors) {
			switch error {
				case UninitializedVariable(variable, pos):
				default:
					trace('[ERROR] $error');
			}
		}
		trace(data);
		// load the images
		new CharacterBitmapGroup(data, map -> {
			getPartyPath(path -> {
				// make the final directories for the downloaded character
				final modPath = makeDirLoop(path, '/customs/${data.data.author}/${data.data.longName}');
				for (field => bitmapData in map) {
					// get a split of "/" stuff to get the file name
					final dumb = (Reflect.field(data.data, field):String).split('/');
					final name = haxe.io.Path.withoutExtension(dumb[dumb.length - 1]);
					final path = '$modPath/$name.png';
					trace('saving', field, 'to', path, name);
					
					// save the image data to a file
					File.saveBytes(path,
						bitmapData.encode(new openfl.geom.Rectangle(0, 0, bitmapData.width, bitmapData.height), new openfl.display.PNGEncoderOptions()));
				}
				// resave the raw json to the char directory
				File.saveContent('$modPath/${data.data.name}.json', rawJson);
				// write the character json to the saves
				final savePath = '$path/partySave.sav'; // dont think i actually need to save here, but a copy of the customs save is here
				final customPath = '$path/partyCustoms.sav'; // save with a weird array of character string jsons
				final saveJson:C2Array = cast haxe.Json.parse(File.getContent(savePath));
				final charData:C2Array = cast haxe.Json.parse(File.getContent(customPath));

				// see if a character with the same name is there and write to there instead of whatever
				var index = -1;
				// clear not used data if its there idk if its ever there lol
				charData.data.splice(charData.size[0], charData.data.length - 1);
				for (i in 0...charData.size[0]) {
					final arr = charData.data[i];
					trace(arr);
					final realChar:CharacterData = cast haxe.Json.parse(arr[0][0]);
					if (realChar.data.longName == data.data.longName && realChar.data.name == data.data.name) {
						trace('match found');
						index = i;
					}
				}
				// if its not there push a new guy
				if (index == -1) {
					index = charData.size[0];
					charData.size[0]++;
				}
				charData.data[index] = [[
					haxe.Json.stringify(data)
				]];
				saveJson.data[7][0] = [haxe.Json.stringify(charData)]; // whys it at 7 and whys the array like this who cares
				File.saveContent(customPath, haxe.Json.stringify(charData)); // resave the save
				File.saveContent(savePath, haxe.Json.stringify(saveJson)); // resave the customs save
				canSelect = true;
			}, () -> { // if cancelled dispose the downloaded bitmaps
				for (bitmap in map)
					bitmap.dispose();
				map.clear();
				canSelect = true;
			});
		});
	}

	function makeDirLoop(start:String, end:String):String
	{
		final split = end.split('/');
		var buffer = start;
		while (split.length > 0) {
			final dir = split.shift();
			buffer += '/$dir';
			trace(dir, buffer);
			if (haxe.io.Path.extension(dir) == '' && !FileSystem.exists(buffer)) {
				FileSystem.createDirectory(buffer);
				trace('making $buffer cause it dont exist');
			}
		}
		return '$start/$end';
	}

	function getPartyPath(got:String->Void, ?cancel:Void->Void, ?force:Bool):Void {
		final appPath = FileSystem.fullPath('./');
		final path = '$appPath/PartyProjectPath.txt';
		if (!force && FileSystem.exists(path)) {
			// validate path
			final path = File.getContent(path);
			if (validatePartyPath(path)) {
				got(path);
			} else {
				trace('bad path $path');
				getPartyPath(got, cancel, true);
			}
		} else {
			// wtf?
			Thread.create(() -> {
				Sys.sleep(.01);
				MainLoop.runInMainThread(() -> {
					var popup = new FileDialog();
					popup.onSelect.add(goodpath -> {
						if (validatePartyPath(goodpath)) {
							File.saveContent(path, goodpath);
							got(goodpath);
						} else {
							getPartyPath(got, cancel, true);
						}
					});
					if (cancel != null)
						popup.onCancel.add(cancel);
					popup.browse(OPEN_DIRECTORY, null, appPath, 'Directory of Party Project');
				});
			});
		}
	}

	function validatePartyPath(path:String) {
		trace('validating', path);
		return FileSystem.exists('$path/nw.exe');
	}
}
