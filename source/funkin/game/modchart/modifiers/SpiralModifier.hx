package funkin.game.modchart.modifiers;

/**
	SpiralModifier forked from troll engine. Support them and check out their engine sometime! :)
	I had to change some stuff so it could be properly supported on NMV, so it isn't 1:1, but still...
	https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/SpiralModifier.hx
**/
class SpiralModifier extends NoteModifier
{
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, column:Int, player:Int, obj:FlxSprite)
	{
		final t = visualDiff / 100;
		
		final limit = 15.0;
		final t_clamped = Math.min(t, limit);
		
		var spiralX = getValue(player);
		var spiralY = getSubmodValue("spiralY", player);
		var spiralZ = getSubmodValue("spiralZ", player);
		
		if (spiralX != 0)
		{
			var offset = getSubmodValue("spiralXOffset", player);
			var period = getSubmodValue("spiralXPeriod", player);
			
			var radius = t_clamped * spiralX * 10;
			var angle = t * (period * 5) + offset;
			pos.x += Math.cos(angle) * radius;
		}
		
		if (spiralY != 0)
		{
			var offset = getSubmodValue("spiralYOffset", player);
			var period = getSubmodValue("spiralYPeriod", player);
			
			var radius = t_clamped * spiralY * 10;
			var angle = t * (period * 5) + offset;
			pos.y += Math.sin(angle) * radius;
		}
		
		if (spiralZ != 0)
		{
			var offset = getSubmodValue("spiralZOffset", player);
			var period = getSubmodValue("spiralZPeriod", player);
			
			var radius = Math.min(t, 20.0) * spiralZ * 0.1;
			var angle = t * (period) + offset;
			pos.z += Math.sin(angle) * radius;
		}
		
		return pos;
	}
	
	override function getName()
	{
		return "spiralX";
	}
	
	override function getSubmods()
	{
		return [
			"spiralY",
			"spiralZ",
			
			"spiralXOffset",
			"spiralXPeriod",
			
			"spiralYOffset",
			"spiralYPeriod",
			
			"spiralZOffset",
			"spiralZPeriod"
		];
	}
}
