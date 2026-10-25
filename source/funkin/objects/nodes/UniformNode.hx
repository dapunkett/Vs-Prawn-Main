package funkin.objects.nodes;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;

// potentially we can make this a macro

/**
 * Attaches to a FlxSprite and allows it to ignore all camera transformations.
 * 
 * Note: Visibility must be handled via the module.
 * Use case:
 * ```haxe
 * var mainSprite = new FlxSprite();
 * add(mainSprite);
 * 
 * var uniformModule = new UniformNode(mainSprite);
 * add(uniformModule);
 * ```
 */
class UniformNode extends FlxBasic
{
	public var root:Null<FlxSprite> = null;
	
	public function new(root:FlxSprite)
	{
		super();
		this.root = root;
		if (root != null) root.visible = false;
	}
	
	override function draw()
	{
		drawRootComplexUniform();
	}
	
	@:access(flixel.FlxSprite)
	public function drawRootComplexUniform() // custom ver of drawComplex
	{
		if (root != null)
		{
			if (root is FlxText)
			{
				(cast root : FlxText).regenGraphic();
			}
			root.visible = false;
			
			root._frame.prepareMatrix(root._matrix, FlxFrameAngle.ANGLE_0, root.checkFlipX(), root.checkFlipY());
			root._matrix.translate(-root.origin.x, -root.origin.y);
			root._matrix.scale(root.scale.x, root.scale.y);
			
			if (root.bakedRotationAngle <= 0)
			{
				root.updateTrig();
				if (root.angle != 0) root._matrix.rotateWithTrig(root._cosAngle, root._sinAngle);
			}
			
			root._point ??= FlxPoint.get();
			root._point.set(root.x, root.y);
			if (root.pixelPerfectPosition) root._point.floor();
			
			root._point.subtract(root.offset);
			root._point.add(root.origin.x, root.origin.y);
			root._matrix.translate(root._point.x, root._point.y);
			
			if (root.isPixelPerfectRender(root.camera))
			{
				root._matrix.tx = Math.floor(root._matrix.tx);
				root._matrix.ty = Math.floor(root._matrix.ty);
			}
			
			// borrowed method from cne
			var _rect = FlxRect.get()
				.set(root.camera.width * 0.5, root.camera.height * 0.5, (root.camera.scaleX > 0 ? Math.max : Math.min)(0, 1 / root.camera.scaleX),
					(root.camera.scaleY > 0 ? Math.max : Math.min)(0, 1 / root.camera.scaleY));
			root._matrix.setTo(root._matrix.a * _rect.width, root._matrix.b * _rect.height, root._matrix.c * _rect.width, root._matrix.d * _rect.height,
				(root._matrix.tx - _rect.x) * _rect.width + _rect.x, (root._matrix.ty - _rect.y) * _rect.height + _rect.y,);
				
			_rect.put();
			
			root.camera.drawPixels(root._frame, root.framePixels, root._matrix, root.colorTransform, root.blend, root.antialiasing, root.shader);
		}
	}
}
