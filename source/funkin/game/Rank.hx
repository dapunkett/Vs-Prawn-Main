package funkin.game;

import flixel.util.FlxColor;

class Rank
{
	/**
	 * Worst to best
	 */
	public static final ORDER:Array<String> = ['F', 'D', 'C', 'B', 'A', 'S', 'P'];

	public static final COLORS:Map<String, FlxColor> = [
		'P' => 0xFFFF69B4, // pink
		'S' => 0xFFFFD700, // gold
		'A' => 0xFF00E676, // green
		'B' => 0xFF00BFFF, // sky blue
		'C' => 0xFFFFA500, // orange
		'D' => 0xFFFF5959, // red
		'F' => 0xFFB3B3B3, // gray
	];

	public static function getColor(rank:String):FlxColor
	{
		return COLORS.get(rank) ?? FlxColor.WHITE;
	}

	public static function isBetter(a:String, b:String):Bool
	{
		return ORDER.indexOf(a) > ORDER.indexOf(b);
	}

	public static function calculate(accuracy:Float, misses:Int):String
	{
		var rank:String = 'F';

		if (accuracy >= 0.999 && misses <= 0) rank = 'P';
		else if (accuracy >= 0.95) rank = 'S';
		else if (accuracy >= 0.90) rank = 'A';
		else if (accuracy >= 0.80) rank = 'B';
		else if (accuracy >= 0.70) rank = 'C';
		else if (accuracy >= 0.60) rank = 'D';

		// misses cap the highest rank you can get
		if (misses >= 10 && isBetter(rank, 'C')) rank = 'C';
		else if (misses > 0 && isBetter(rank, 'A')) rank = 'A';

		return rank;
	}
}
