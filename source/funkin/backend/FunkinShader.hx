package funkin.backend;

import Type.ValueType;

import flixel.system.FlxAssets.FlxShader;
import flixel.addons.system.macros.FlxRuntimeShaderMacro;
import flixel.util.FlxStringUtil;

/**
 * Modified runtime shader to prevent crashes.
 */
class FunkinRuntimeShader extends flixel.addons.display.FlxRuntimeShader
{
	/**
	 * Creates a new `FunkinRuntimeShader` using the path to a external frag and vert file.
	 */
	public static function fromPath(?fragFile:String, ?vertFile:String)
	{
		var fragPath = fragFile != null ? Paths.fragment(fragFile) : null;
		var vertPath = vertFile != null ? Paths.vertex(vertFile) : null;
		
		if (fragPath != null)
		{
			if (FunkinAssets.exists(fragPath)) fragPath = FunkinAssets.getContent(fragPath);
		}
		
		if (vertPath != null)
		{
			if (FunkinAssets.exists(vertPath)) vertPath = FunkinAssets.getContent(vertPath);
		}
		
		return new FunkinRuntimeShader(fragPath, vertPath);
	}
	
	override function __createGLProgram(vertexSource:String, fragmentSource:String):lime.graphics.opengl.GLProgram
	{
		try
		{
			return super.__createGLProgram(vertexSource, fragmentSource);
		}
		catch (error)
		{
			Logger.log('Shader Crashed! check the console or crash_dump/shader_error for more information', ERROR, true);
			Logger.log('Crash Log ->: "${error.toString()}"', ERROR);
			Logger.writeDump(error.toString(), 'crash_dump', 'shader_error');
			
			@:privateAccess return super.__createGLProgram(vertexSource, FunkinShader._templateFrag);
		}
	}
	
	override function toString():String
	{
		return 'FunkinRuntimeShader';
	}
}

/**
 * Modified runtime shader to prevent crashes.
 */
class FunkinShader extends flixel.graphics.tile.FlxGraphicsShader
{
	override function __createGLProgram(vertexSource:String, fragmentSource:String):lime.graphics.opengl.GLProgram
	{
		try
		{
			return super.__createGLProgram(vertexSource, fragmentSource);
		}
		catch (error)
		{
			Logger.log('Shader Crashed! check the console or crash_dump/shader_error for more information', ERROR, true);
			Logger.log('Crash Log ->: "${error.toString()}"', ERROR);
			Logger.writeDump(error.toString(), 'crash_dump', 'shader_error');
			
			return super.__createGLProgram(vertexSource, _templateFrag);
		}
	}
	
	public function toString()
	{
		return 'FunkinShader';
	}
	
	/**
		fallback fragment shader to be used in case of error
	**/
	static final _templateFrag:String = FlxRuntimeShaderMacro.retrieveMetadata('glFragmentHeader')
		+ "
		void main() 
        {
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}

    ";
}
