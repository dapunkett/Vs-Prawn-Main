package funkin.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.data.ClientPrefs;

class FreeplayCard extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var songText:FlxText;
	
	public var targetYIndex:Float = 0;
	public var targetX:Float = 85;
	public var targetY:Float = 268.5;
	public var targetAlpha:Float = 1.0;
	public var targetScale:Float = 1.05;
	public var targetColor:FlxColor = FlxColor.WHITE;
	
	public var songName:String = '';
	
	// White capsule slot inside freeplaycard.png: center (327, 114), usable width 340
	public static inline final PILL_CENTER_X:Float = 327;
	public static inline final PILL_CENTER_Y:Float = 114;
	public static inline final TEXT_WIDTH:Float = 340;
	
	public function new(x:Float, y:Float, songName:String)
	{
		super(x, y);
		directAlpha = true;
		this.songName = songName;
		
		bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/freeplay/freeplaycard'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		
		var formattedName:String = songName.toUpperCase();
		
		var fontSize:Int = 28;
		if (formattedName.length > 20)
			fontSize = 17;
		else if (formattedName.length > 16)
			fontSize = 20;
		else if (formattedName.length > 12)
			fontSize = 24;
		
		final textLeft:Float = PILL_CENTER_X - (TEXT_WIDTH / 2); // 157
		songText = new FlxText(textLeft, 0, TEXT_WIDTH, formattedName, fontSize);
		songText.setFormat(Paths.font('round'), fontSize, 0xFF181824, CENTER);
		songText.antialiasing = ClientPrefs.globalAntialiasing;
		
		// Vertically center inside the white capsule before add() applies group offset
		songText.y = PILL_CENTER_Y - (songText.height / 2) - 2;
		add(songText);
		
		// Scale smoothly from the card's visual center
		origin.set(bg.width / 2, bg.height / 2);
	}
	
	public function bounce():Void
	{
		scale.set(1.14, 1.14);
	}
	
	public function snapToTarget():Void
	{
		x = targetX;
		y = targetY;
		alpha = targetAlpha;
		scale.set(targetScale, targetScale);
		bg.color = targetColor;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		final lerpRate:Float = FlxMath.getElapsedLerp(0.18, elapsed);
		x = FlxMath.lerp(x, targetX, lerpRate);
		y = FlxMath.lerp(y, targetY, lerpRate);
		alpha = FlxMath.lerp(alpha, targetAlpha, lerpRate);
		
		final currentScale:Float = FlxMath.lerp(scale.x, targetScale, lerpRate);
		scale.set(currentScale, currentScale);
		
		bg.color = FlxColor.interpolate(bg.color, targetColor, lerpRate);
	}
}
