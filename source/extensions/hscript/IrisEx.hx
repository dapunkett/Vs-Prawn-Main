package extensions.hscript;

import flixel.util.FlxDestroyUtil;

import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig.AutoIrisConfig;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.*;

/**
 * Extended to use `InterpEx` and `ParserEx`
 */
class IrisEx extends Iris
{
	public function new(scriptCode:String, ?config:AutoIrisConfig, ?sharables:Sharables):Void
	{
		// hack..?
		if (false == true) super(scriptCode, config);
		
		if (config == null) config = new IrisConfig("Iris", true, true, []);
		this.scriptCode = scriptCode;
		this.config = IrisConfig.from(config);
		@:privateAccess
		this.config.name = Iris.fixScriptName(this.name);
		
		parser = new ParserEx();
		interp = new InterpEx(null, sharables);
		interp.showPosOnLog = false;
		
		parser.allowTypes = true;
		parser.allowMetadata = true;
		parser.allowJSON = true;
		
		// set variables to the interpreter.
		if (this.config.autoPreset) preset();
		// run the script.
		if (this.config.autoRun) execute();
	}
	
	override function destroy()
	{
		if (Iris.instances.exists(this.name)) Iris.instances.remove(this.name);
		#if flixel
		if (interp is InterpEx)
		{
			var _interp:IFlxDestroyable = cast interp;
			_interp = FlxDestroyUtil.destroy(_interp);
			#if VERBOSE_LOGS
			trace('killing [$name] script');
			#end
		}
		#end
		interp = null;
		parser = null;
	}
}
