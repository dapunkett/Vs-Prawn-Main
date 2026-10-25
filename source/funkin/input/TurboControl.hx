package funkin.input;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.group.FlxGroup;
import flixel.FlxBasic;

// impsotors
// dat5 and emi

/**
 * group of `TurboControl` instances. If multiple `TurboControl` instances are to be used, adding them to a `TurboControlGroup` will prevent them conflicting with one another.
 */
class TurboControlGroup extends FlxTypedGroup<TurboControl>
{
	override function onMemberAdd(member:TurboControl):Void
	{
		if (member != null) member.turbos = members;
		
		super.onMemberAdd(member);
	}
}

/**
 * Helper class to simplify repeated pressing behavior.
 * 
 * When the tied inputs are pressed, `PRESSED` will be true. If the input continues to be held, `PRESSED` will be repeatedly be `true` after `initialDelay` and spaced between `rate`
 */
class TurboControl extends FlxBasic // very basic turbo control thingy
{
	/**
	 * The time inbetween repeats being fired.
	 */
	public var rate:Float = (1 / 12);
	
	/**
	 * The initial delay before beginning to check for repeat inputs.
	 */
	public var initialDelay:Float = (1 / 3);
	
	/**
	 * Array of `TurboControl` instances for handling conflicting inputs.
	 */
	public var turbos:Array<TurboControl> = [];
	
	/**
	 * Optional gamepad button ids for this to watch.
	 */
	public var buttons:Null<Array<Int>> = null;
	
	/**
	 * Key ids for this to watch.
	 */
	public var keys:Array<Int>;
	
	/**
	 * Whether the hooked inputs are being pressed.
	 */
	public var PRESSED(default, null):Bool = false;
	
	var holding:Bool = false;
	
	var _pressedElapsed:Float = 0;
	
	/**
	 * Creates a new `TurboControl` instance.
	 * @param keys The `FlxKey` ids.
	 * @param rate The time inbetween repeats being fired.
	 */
	public function new(keys:Array<Int>, rate:Float = 0.1)
	{
		super();
		this.keys = keys;
		this.rate = rate;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		var justPressed:Bool = false;
		var pressed:Bool = false;
		
		if (buttons != null)
		{
			for (button in buttons)
			{
				justPressed = FlxG.gamepads.anyJustPressed(button);
				pressed = FlxG.gamepads.anyPressed(button);
				
				if (pressed) break;
			}
		}
		
		justPressed = (justPressed || FlxG.keys.anyJustPressed(keys));
		pressed = (pressed || FlxG.keys.anyPressed(keys));
		
		if (!holding)
		{
			if (justPressed)
			{
				for (turbo in turbos)
				{
					turbo.holding = (turbo == this);
				}
			}
		}
		else if (!pressed)
		{
			holding = false;
		}
		
		if (holding)
		{
			if (_pressedElapsed == 0)
			{
				PRESSED = true;
			}
			else if (_pressedElapsed >= (initialDelay + rate))
			{
				PRESSED = true;
				_pressedElapsed -= rate;
			}
			else
			{
				PRESSED = false;
			}
			
			_pressedElapsed += elapsed;
		}
		else
		{
			_pressedElapsed = 0;
			PRESSED = false;
		}
	}
	
	/**
	 * Simplifies TurboControl creation. Creates a new instance and sets keys and buttons (if there is a action for them).
	 */
	public static function fromAction(action:String, rate:Float = 0.1):TurboControl
	{
		var keys = ClientPrefs.keyBinds.get(action);
		if (keys == null) throw 'what. $action keybinds doesnt exist.';
		
		var instance = new TurboControl(keys, rate);
		
		if (action.startsWith('ui_')) // hacky but im just porting this from something else //clean it up if ud like
		{
			instance.buttons = switch (action.split('_')[1])
			{
				case 'left': [FlxGamepadInputID.DPAD_LEFT, FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT];
				
				case 'right': [FlxGamepadInputID.DPAD_RIGHT, FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT];
				
				case 'down': [FlxGamepadInputID.DPAD_DOWN, FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN];
				
				case 'up': [FlxGamepadInputID.DPAD_UP, FlxGamepadInputID.LEFT_STICK_DIGITAL_UP];
				
				default: null;
			}
		}
		else
		{
			instance.buttons = ClientPrefs.gamepadBinds.get(action);
		}
		
		return instance;
	}
}
