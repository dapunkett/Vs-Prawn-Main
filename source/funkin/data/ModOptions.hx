package funkin.data;

import flixel.util.FlxSave;

class ModOption implements flixel.util.FlxDestroyUtil.IFlxDestroyable
{
	public var idx:Int = -1;
	public var key:String;
	public var type:String;
	public var value:Dynamic;
	public var defaultValue:Dynamic;
	public var settings:OptionSettings;
	
	public function new(key:String, type:String, value:Dynamic, ?settings:OptionSettings)
	{
		this.key = key;
		this.type = type.toLowerCase();
		this.value = value;
		this.defaultValue = value;
		
		this.settings = settings;
		validateSettings();
	}
	
	public function validateSettings()
	{
		settings.description ??= 'No description provided.';
		
		settings.onChange ??= null;
		settings.callback ??= null;
		
		settings.options ??= ['Option 1', 'Option 2'];
		settings.displayFormat ??= '%v';
		
		settings.stepSize ??= 1;
		settings.minValue ??= null;
		settings.maxValue ??= null;
		settings.decimals ??= 1;
	}
	
	public function toString():String return '(key: $key, type: $type, value: $value, idx: $idx)';
	
	public function destroy()
	{
		key = '';
		value = null;
		defaultValue = null;
		type = '';
		idx = -1;
		
		settings = null;
	}
}

typedef OptionSettings =
{
	var description:String;
	var onChange:Void->Void;
	var callback:Void->Void;
	
	// for strings
	var options:Array<String>;
	var displayFormat:String;
	
	// for steppers
	var stepSize:Null<Float>;
	var minValue:Null<Float>;
	var maxValue:Null<Float>;
	var decimals:Null<Int>;
}

class ModOptionObject extends funkin.states.options.Option
{
	public function new(option:ModOption)
	{
		super(option.key, option.settings.description, option.key, option.type, option.defaultValue, option.settings.options);
		
		switch (this.type)
		{
			case 'int':
				this.minValue = option.settings.minValue;
				this.maxValue = option.settings.maxValue;
				this.changeValue = option.settings.stepSize;
			case 'float':
				this.minValue = option.settings.minValue;
				this.maxValue = option.settings.maxValue;
				this.changeValue = option.settings.stepSize;
				this.decimals = option.settings.decimals;
			case 'string':
				this.options = option.settings.options; // it's already set in super() but double assigning Juuusttt in case
				this.displayFormat = option.settings.displayFormat;
		}
	}
	
	override public function getValue():Dynamic
	{
		return ModOptions.getValue(variable);
	}
	
	override public function setValue(value:Dynamic)
	{
		ModOptions.setValue(variable, value);
	}
}

class ModOptions
{
	public static var currentMod:String = '';
	public static var options:Map<String, ModOption> = new Map();
	
	public static var list(get, never):Array<ModOption>;
	
	static function get_list()
	{
		var list = [for (option in options) option];
		list.sort(funkin.utils.SortUtil.idxSort);
		return list;
	}
	
	static function getSave(mod:String):FlxSave
	{
		var save = new FlxSave();
		save.bind('mods/$mod');
		return save;
	}
	
	public static function init(?modName:String = 'NMV-Base-Game')
	{
		if (currentMod != '' && currentMod != modName) flush();
		
		currentMod = modName;
		options.clear();
		
		var save = getSave(modName);
		var raw:Dynamic = save.data.optionData;
		
		if (raw != null)
		{
			for (key in Reflect.fields(raw))
			{
				var entry:Dynamic = Reflect.field(raw, key);
				
				var option = new ModOption(key, entry.type, entry.value, entry.settings);
				option.idx = (entry.idx != null) ? entry.idx : -1;
				options.set(key, option);
			}
		}
		save.close();
		
		validateOrder();
		
		trace('initialized mod [$currentMod] settings');
	}
	
	// in case your options, somehow, don't have an idx
	static function validateOrder()
	{
		var usedIDs:Array<Int> = [];
		var sorted = list;
		
		for (i in 0...sorted.length)
		{
			var option = sorted[i];
			if (option.idx == -1 || usedIDs.contains(option.idx)) option.idx = i;
			usedIDs.push(option.idx);
		}
	}
	
	public static function flush()
	{
		if (currentMod == '') return;
		
		var out:Dynamic = {};
		for (key => option in options)
		{
			Reflect.setField(out, key,
				{
					type: option.type,
					value: option.value,
					idx: option.idx,
					settings: option.settings
				});
		}
		
		var save = getSave(currentMod);
		save.data.optionData = out;
		save.flush();
		save.close();
	}
	
	public static function add(mod:String, key:String, type:String = 'string', defaultValue:Dynamic = 'null', ?settings:OptionSettings)
	{
		if (options.exists(key) || (currentMod != mod && !Mods.globalMods.contains(mod))) return;
		
		if (defaultValue == 'null')
		{
			switch (type.toLowerCase())
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'string':
					defaultValue = '';
				default:
					type = 'null';
			}
		}
		
		if (type == 'null')
		{
			Logger.log('Unable to create custom option [$key]. Is your option type incorrect / null?', ERROR);
			return;
		}
		
		var option = new ModOption(key, type, defaultValue, settings);
		option.idx = list.length;
		options.set(key, option);
		
		trace('new option $key value $defaultValue');
		flush();
	}
	
	public static function get(key:String):ModOption
	{
		var option = options.get(key);
		
		if (option == null || option.type == 'null')
		{
			Logger.log('Custom Option [$key] returned null. Does it exist / was it created properly?', ERROR);
			return null;
		}
		
		return option;
	}
	
	public static function setValue(key:String, value:Dynamic)
	{
		var option = get(key);
		if (option == null) return;
		
		option.value = value;
	}
	
	public static function getValue(key:String):Dynamic
	{
		var option = get(key);
		return (option != null) ? option.value : null;
	}
}
