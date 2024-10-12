package;

import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import openfl.events.EventType;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;


class NiceBox extends Sprite {
	public var text(get, set):String;

	var bg:Sprite;
	var textField:TextField;
	var alt:Bool;
	public function new(boxText:String, alt:Bool) {
		super();
		bg = new Sprite();
		this.alt = alt;
		redraw(false);
		addChild(bg);
		textField = new TextField();
		textField.filters = [new GlowFilter(0xFF000000, 1, 6, 6, 150, 3)];
		text = boxText;
		addChild(textField);
		addEventListener(MouseEvent.CLICK, clicked);
	}

	public function redraw(?white:Bool) {
		var borderCol = white ? 0xFFFFFFFF : 0xFF383838;
		var w = 200;
		var h = 72;
		var mat = new Matrix();
		mat.createGradientBox(w, h, 90 * (Math.PI/180), 0, 0);
		bg.graphics.clear();
		bg.graphics.beginGradientFill(LINEAR, alt ? [0xFF8B8B8B, 0xFF484848] : [0xFFD3D3D3, 0xFF797979],  null, [0x00, 0xFF], mat, REFLECT);
		bg.graphics.lineStyle(3, borderCol);
		bg.graphics.drawRoundRect(0, 0, w, h, 10, 10);
	}

	function clicked(event:MouseEvent) {
		trace('clicked', text);
		dispatchEvent(new NiceBoxEvent(this));
	}

	function get_text() {
		return textField.text;
	}

	function set_text(v:String):String {
		if(textField.text != v) {
			textField.selectable = false;
			textField.text = v;
			textField.setTextFormat(new TextFormat(Assets.getFont('Assets/Fonts/vcr.ttf').fontName, 20, 0xFFFFFFFF, null, null, null, null, null, CENTER));
			textField.width = 200;
			textField.wordWrap = true;
			textField.y = (72 - textField.textHeight) * .5;
		}
		return v;
	}
}

class NiceBoxEvent extends Event {
	public static var NICEBOX_CLICK:EventType<NiceBoxEvent> = 'nicebox_click';

	public var box:NiceBox;

	public function new(box:NiceBox) {
		super(NICEBOX_CLICK);
		this.box = box;
	}
}