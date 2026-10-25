package funkin.game.modchart.modifiers;

class TransformModifier extends NoteModifier
{ // this'll be transformX in ModManager
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}
	
	override function getName() return 'transformX';
	
	override function getOrder() return Modifier.ModifierOrder.LAST;
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		pos.x += getValue(player) + getSubmodValue("transformX-a", player);
		pos.y += getSubmodValue("transformY", player) + getSubmodValue("transformY-a", player);
		pos.z += getSubmodValue('transformZ', player) + getSubmodValue("transformZ-a", player);
		
		pos.x += getSubmodValue('transform${data}X', player) + getSubmodValue('transform${data}X-a', player);
		pos.y += getSubmodValue('transform${data}Y', player) + getSubmodValue('transform${data}Y-a', player);
		pos.z += getSubmodValue('transform${data}Z', player) + getSubmodValue('transform${data}Z-a', player);
		
		if (obj is Note)
		{
			pos.x += getSubmodValue('noteX', player) + getSubmodValue('note${data}X', player);
			pos.y += getSubmodValue('noteY', player) + getSubmodValue('note${data}Y', player);
			pos.z += getSubmodValue('noteZ', player) + getSubmodValue('note${data}Z', player);
		}
		if (obj is StrumNote)
		{
			pos.x += getSubmodValue('receptorX', player) + getSubmodValue('receptor${data}X', player);
			pos.y += getSubmodValue('receptorY', player) + getSubmodValue('receptor${data}Y', player);
			pos.z += getSubmodValue('receptorZ', player) + getSubmodValue('receptor${data}Z', player);
		}
		
		return pos;
	}
	
	override function getSubmods()
	{
		var subMods:Array<String> = ["transformY", "transformZ", "transformX-a", "transformY-a", "transformZ-a", 'receptorX', 'receptorY', 'receptorZ', 'noteX', 'noteY', 'noteZ'];
		
		var receptors = modMgr.receptors[0];
		for (i in 0...PlayState.SONG.keys)
		{
			subMods.push('transform${i}X');
			subMods.push('transform${i}Y');
			subMods.push('transform${i}Z');
			subMods.push('transform${i}X-a');
			subMods.push('transform${i}Y-a');
			subMods.push('transform${i}Z-a');
			
			subMods.push('receptor${i}X');
			subMods.push('receptor${i}Y');
			subMods.push('receptor${i}Z');
			subMods.push('note${i}X');
			subMods.push('note${i}Y');
			subMods.push('note${i}Z');
		}
		return subMods;
	}
}
