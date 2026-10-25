package funkin.backend.plugins;

import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.scripts.FunkinScript;
import funkin.scripts.ScriptGroup;

@:nullSafety
class ModPlugin extends FlxTypedGroup<FlxBasic>
{
	@:nullSafety(Off)
	public static var instance:ModPlugin;
	
	public static function init()
	{
		if (instance == null)
		{
			FlxG.plugins.addPlugin(instance = new ModPlugin());
			#if debug
			FlxG.console.registerClass(ModPlugin);
			#end
		}
	}
	
	public final scripts:ScriptGroup;
	
	public function new()
	{
		super();
		scripts = new ScriptGroup(this);
		
		if (!FlxG.signals.postStateSwitch.has(onStateSwitchPost)) FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		if (!FlxG.signals.preStateSwitch.has(onStateSwitch)) FlxG.signals.preStateSwitch.add(onStateSwitch);
	}
	
	override function update(elapsed:Float)
	{
		scripts.call('onUpdate', [elapsed]);
		super.update(elapsed);
	}
	
	override function destroy()
	{
		clearScripts();
		super.destroy();
	}
	
	public function clearScripts(callDestroy:Bool = true)
	{
		scripts.clear(callDestroy);
		
		forEach(member -> FlxDestroyUtil.destroy(member));
		clear();
	}
	
	public function getPlugin(key:String):Null<FunkinScript>
	{
		return scripts.getScript(key);
	}
	
	public function callOnPlugin(name:String, func:String, ?args:Array<Dynamic>):Null<Dynamic>
	{
		final script = getPlugin(name);
		
		if (script == null) return null;
		return script.call(func, args).returnValue;
	}
	
	public function callOnPlugins(func:String, ?args:Array<Dynamic>):Void
	{
		scripts.call(func, args);
	}
	
	public function populate()
	{
		clearScripts();
		
		for (file in Paths.listAllFilesInDirectory('scripts/plugins/'))
		{
			if (FunkinScript.isHxFile(file))
			{
				final scriptName = file.withoutDirectory().withoutExtension();
				
				var script = FunkinScript.fromFile(file, scriptName, false);
				
				scripts.addScript(script, true);
				script.execute();
				
				if (script.parsingFailed())
				{
					scripts.removeScript(script);
					script = FlxDestroyUtil.destroy(script);
					continue;
				}
				
				if (script.exists('onLoad')) script.call('onLoad');
			}
		}
	}
	
	public function onStateSwitchPost():Void
	{
		callOnPlugins('onStateSwitchPost', [FlxG.state]);
	}
	
	public function onStateSwitch():Void
	{
		callOnPlugins('onStateSwitch', [FlxG.state]);
	}
}
