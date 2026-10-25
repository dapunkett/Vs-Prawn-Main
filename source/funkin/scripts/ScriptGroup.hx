package funkin.scripts;

import extensions.hscript.Sharables;
import extensions.hscript.InterpEx;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * Container of `FunkinScript` instances
 */
@:nullSafety(Strict)
class ScriptGroup implements IFlxDestroyable
{
	public var scriptShareables:Sharables = new Sharables();
	
	/**
	 * Global interp parent applied to all scripts in the group
	 */
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		if (value != null && value == parent)
		{
			return parent;
		}
		
		parent = value;
		@:privateAccess
		for (script in members)
		{
			copyGroup(script);
		}
		
		return parent;
	}
	
	/**
	 * array of all `FunkinScript` instances
	 */
	public var members:Array<FunkinScript> = [];
	
	public function new(?parent:Dynamic)
	{
		@:privateAccess
		if (FlxG.game != null)
		{
			parent ??= FlxG.state;
		}
		
		@:bypassAccessor this.parent = parent;
	}
	
	/**
	 * Adds a new script to the group.
	 * @param script 
	 */
	public function addScript(script:Null<FunkinScript>, allowDupeNames:Bool = false):Bool
	{
		if (script == null || (!allowDupeNames && exists(script.name))) return false;
		
		copyGroup(script);
		members.push(script);
		return true;
	}
	
	/**
	 * Removes a script from the group.
	 * @return Bool Whether it successfully removed.
	 */
	public function removeScript(script:FunkinScript):Bool
	{
		return members.remove(script);
	}
	
	/**
	 * Copys the groups `parent` and `scriptShareables` to the script.
	 */
	function copyGroup(script:FunkinScript)
	{
		@:privateAccess
		final interp:InterpEx = cast script.interp;
		if (interp.parent != parent) interp.parent = parent;
		interp.sharedFields = scriptShareables;
	}
	
	@:inheritDoc(funkin.scripts.FunkinScript.set)
	public function set(varName:String, arg:Dynamic)
	{
		for (i in members)
		{
			i.set(varName, arg);
		}
	}
	
	@:inheritDoc(funkin.scripts.FunkinScript.call)
	public function call(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>):Dynamic
	{
		exclusions ??= [];
		var returnVal:Dynamic = ScriptConstants.CONTINUE_FUNC;
		for (i in members)
		{
			if (i == null || !i.exists(event) || exclusions.contains(i.name))
			{
				continue;
			}
			
			var ret:Dynamic = i.call(event, args)?.returnValue;
			if (ret is Int)
			{
				if (ret == ScriptConstants.HALT_FUNC)
				{
					ret = returnVal;
					if (!ignoreStops) return returnVal;
				};
				
				if (ret != ScriptConstants.CONTINUE_FUNC) returnVal = ret;
			}
		}
		
		return returnVal;
	}
	
	/**
	 * returns a script by name. returns `null` if it cannot be found
	 */
	public function getScript(name:String):Null<FunkinScript>
	{
		for (script in members)
			if (script.name == name) return script;
			
		return null;
	}
	
	/**
	 * Is true if a script with the given name exists
	 */
	public function exists(name:String):Bool
	{
		for (script in members)
			if (script.name == name) return true;
		return false;
	}
	
	/**
	 * Destroys all members
	 */
	public function destroy()
	{
		scriptShareables.clear();
		@:nullSafety(Off)
		scriptShareables = null;
		members = FlxDestroyUtil.destroyArray(members);
		@:bypassAccessor parent = null;
	}
	
	public function clear(callOnDestroy:Bool = true)
	{
		if (callOnDestroy) call('onDestroy', null, true);
		for (i in 0...members.length)
		{
			var script = members[0];
			members.remove(script);
			script.destroy();
		}
	}
}
