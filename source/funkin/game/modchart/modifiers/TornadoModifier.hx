package funkin.game.modchart.modifiers;

class TornadoModifier extends NoteModifier
{
	override function getName() return 'tornado';
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, column:Int, player:Int, obj:FlxSprite)
	{
		if (getPercent(player) == 0) return pos;
		
		var receptors = modMgr.receptors[player];
		var len = receptors.length;
		
		// thank you 4mbr0s3
		var playerColumn = column % receptors.length;
		var columnPhaseShift = playerColumn * Math.PI / 3;
		var phaseShift = visualDiff / 135;
		var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) / 2;
		var offsetX = (-Math.cos(phaseShift - columnPhaseShift) + 1) / 2 - returnReceptorToZeroOffsetX;
		var outPos = pos.clone();
		
		return outPos.add(Vector3.get(offsetX * getPercent(player)));
	}
}
