package funkin.states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.Json;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import funkin.backend.MusicBeatState;
import funkin.states.MainMenuState;

typedef DJAnimData =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var offsets:Array<Float>;
}

typedef DJData =
{
	var position:Array<Float>;
	var scale:Float;
	var animations:Array<DJAnimData>;
}

class DJEditorState extends MusicBeatState
{
	public var djData:DJData;
	public var karidesDJ:FlxSprite;
	public var ghostDJ:FlxSprite;
	public var crosshair:FlxSprite;
	
	// Background layers
	public var gridBG:FlxBackdrop;
	public var beachBG:FlxSprite;
	public var rightPanel:FlxSprite;
	
	public var isBeachView:Bool = true;
	public var showGhost:Bool = true;
	
	// Animation state
	public var curSelected:Int = 1; // Start on idle
	public var animsList:Array<DJAnimData> = [];
	
	// Camera
	var camHUD:FlxCamera;
	var camFollow:FlxPoint;
	var draggingCam:Bool = false;
	var dragMouseStart:FlxPoint;
	var dragCamStart:FlxPoint;
	
	// Mouse tracking
	var lastMouseScreenX:Float = 0;
	var lastMouseScreenY:Float = 0;
	
	// UI overlay elements
	var hudGroup:FlxTypedGroup<FlxSprite>;
	var titleText:FlxText;
	var curAnimText:FlxText;
	var animListText:FlxText;
	var animBoxBG:FlxSprite;
	var helpText:FlxText;
	var noticeText:FlxText;
	var noticeTween:FlxTween;
	
	override function create()
	{
		DiscordClient.changePresence("In the DJ Offset Editor");
		FlxG.mouse.visible = true;
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		
		camFollow = new FlxPoint(FlxG.width / 2, FlxG.height / 2);
		dragMouseStart = new FlxPoint();
		dragCamStart = new FlxPoint();
		lastMouseScreenX = FlxG.mouse.screenX;
		lastMouseScreenY = FlxG.mouse.screenY;
		
		// 1. Grid Background
		var gridGraphic = FlxGridOverlay.create(24, 24, 48, 48, true, 0xFF181B22, 0xFF232834);
		gridBG = new FlxBackdrop(gridGraphic.graphic);
		gridBG.scrollFactor.set(0.5, 0.5);
		gridBG.visible = false;
		add(gridBG);
		
		// 2. Beach View Mockup
		beachBG = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		beachBG.screenCenter();
		add(beachBG);
		
		rightPanel = new FlxSprite();
		rightPanel.loadGraphic(Paths.image('menus/freeplay/rightpanel'));
		final panelWidth:Float = 615;
		rightPanel.scale.set(panelWidth / 712, FlxG.height / rightPanel.height);
		rightPanel.updateHitbox();
		rightPanel.x = FlxG.width - panelWidth;
		rightPanel.y = 0;
		rightPanel.antialiasing = ClientPrefs.globalAntialiasing;
		add(rightPanel);
		
		// 3. Crosshair / Reference Marker at DJ position
		crosshair = new FlxSprite().makeGraphic(20, 20, FlxColor.TRANSPARENT);
		for (i in 0...20)
		{
			crosshair.pixels.setPixel32(i, 10, 0x88FFCC00);
			crosshair.pixels.setPixel32(10, i, 0x88FFCC00);
		}
		add(crosshair);
		
		// 4. Load Data
		loadDJData();
		
		// 5. Ghost / Onion Skin DJ Sprite
		ghostDJ = new FlxSprite(djData.position[0], djData.position[1]);
		ghostDJ.frames = Paths.getSparrowAtlas('menus/freeplay/karidesdj');
		for (a in animsList)
		{
			ghostDJ.animation.addByPrefix(a.anim, a.name, a.fps, a.loop);
		}
		ghostDJ.antialiasing = ClientPrefs.globalAntialiasing;
		ghostDJ.alpha = 0.45;
		ghostDJ.color = 0xFF55DDFF; // Cyan silhouette tint
		add(ghostDJ);
		updateGhostAnim();
		
		// 6. Main Editable Karides DJ Sprite
		karidesDJ = new FlxSprite(djData.position[0], djData.position[1]);
		karidesDJ.frames = Paths.getSparrowAtlas('menus/freeplay/karidesdj');
		for (a in animsList)
		{
			karidesDJ.animation.addByPrefix(a.anim, a.name, a.fps, a.loop);
		}
		karidesDJ.antialiasing = ClientPrefs.globalAntialiasing;
		add(karidesDJ);
		
		crosshair.x = karidesDJ.x - 10;
		crosshair.y = karidesDJ.y - 10;
		
		// 7. Setup HUD / UI
		hudGroup = new FlxTypedGroup<FlxSprite>();
		hudGroup.cameras = [camHUD];
		add(hudGroup);
		
		createHUD();
		
		// Play initial animation
		playCurrentAnim(true);
		
		super.create();
	}
	
	function createHUD()
	{
		// Top header bar
		var topBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 42, 0xCC0D1117);
		hudGroup.add(topBar);
		
		titleText = new FlxText(16, 8, 0, "🦐 VS PRAWN — DJ OFFSET & ANIMATION EDITOR", 20);
		titleText.setFormat(Paths.DEFAULT_FONT, 20, 0xFF58A6FF, LEFT, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 1.5;
		hudGroup.add(titleText);
		
		// Current animation & offset info
		curAnimText = new FlxText(16, 52, 600, "", 20);
		curAnimText.setFormat(Paths.DEFAULT_FONT, 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		curAnimText.borderSize = 1.5;
		hudGroup.add(curAnimText);
		
		// Animation list box (Top-Right)
		final boxW:Int = 290;
		final boxH:Int = 175;
		animBoxBG = new FlxSprite(FlxG.width - boxW - 16, 52).makeGraphic(boxW, boxH, 0xDD0D1117);
		hudGroup.add(animBoxBG);
		
		animListText = new FlxText(animBoxBG.x + 12, animBoxBG.y + 10, boxW - 24, "", 16);
		animListText.setFormat(Paths.DEFAULT_FONT, 16, FlxColor.WHITE, LEFT);
		hudGroup.add(animListText);
		
		// Bottom controls legend bar
		var bottomBar = new FlxSprite(0, FlxG.height - 36).makeGraphic(FlxG.width, 36, 0xDD0D1117);
		hudGroup.add(bottomBar);
		
		final legendStr = "[SOL / SAĞ TIKLA SÜRÜKLE]: Karidesi Taşı | [ORTA TIK]: Kamerayı Kaydır | [W/S]: Anim | [OKLAR]: İnce Ayar | [SPACE]: Oynat | [G]: Ghost | [CTRL+S]: Kaydet";
		helpText = new FlxText(0, FlxG.height - 28, FlxG.width, legendStr, 14);
		helpText.setFormat(Paths.DEFAULT_FONT, 14, 0xFFE6EDF3, CENTER);
		hudGroup.add(helpText);
		
		// Save Notification popup
		noticeText = new FlxText(0, 100, FlxG.width, "", 22);
		noticeText.setFormat(Paths.DEFAULT_FONT, 22, 0xFF3FB950, CENTER, OUTLINE, 0xFF0D1117);
		noticeText.borderSize = 2;
		noticeText.alpha = 0;
		hudGroup.add(noticeText);
		
		updateHUD();
	}
	
	function loadDJData()
	{
		var defaultData:DJData = {
			position: [875, 231],
			scale: 1.0,
			animations: [
				{anim: "intro", name: "boyfriend dj intro", fps: 24, loop: false, offsets: [5, 424]},
				{anim: "idle", name: "Boyfriend DJ idle", fps: 24, loop: true, offsets: [0, 0]},
				{anim: "confirm", name: "Boyfriend DJ confirm", fps: 24, loop: false, offsets: [18, -28]}
			]
		};
		
		var jsonPath:String = "assets/game/data/dj/karides.json";
		#if sys
		if (FileSystem.exists(jsonPath))
		{
			try
			{
				var content = File.getContent(jsonPath);
				djData = cast Json.parse(content);
			}
			catch (e:Dynamic)
			{
				trace('Error loading $jsonPath: $e. Using defaults.');
				djData = defaultData;
			}
		}
		else
		#end
		{
			djData = defaultData;
		}
		
		animsList = djData.animations;
	}
	
	public function saveDJData()
	{
		#if sys
		try
		{
			var jsonString = Json.stringify(djData, "\t");
			
			// 1. Save to assets/game/data/dj/karides.json
			var path1 = "assets/game/data/dj/karides.json";
			var dir1 = haxe.io.Path.directory(path1);
			if (!FileSystem.exists(dir1)) FileSystem.createDirectory(dir1);
			File.saveContent(path1, jsonString);
			
			// 2. Save to export bin assets if running in bin
			var path2 = "export/release/windows/bin/assets/data/dj/karides.json";
			var dir2 = haxe.io.Path.directory(path2);
			if (FileSystem.exists(dir2)) File.saveContent(path2, jsonString);
			
			showNotice("✓ Saved to data/dj/karides.json successfully!");
			FlxG.sound.play(Paths.sound('confirmMenu'));
		}
		catch (e:Dynamic)
		{
			showNotice("Error saving: " + e, FlxColor.RED);
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		#else
		showNotice("Saving not supported on this platform.", FlxColor.RED);
		#end
	}
	
	function showNotice(text:String, color:FlxColor = 0xFF3FB950)
	{
		noticeText.text = text;
		noticeText.color = color;
		noticeText.alpha = 1;
		noticeText.y = 100;
		
		if (noticeTween != null) noticeTween.cancel();
		noticeTween = FlxTween.tween(noticeText, {alpha: 0, y: 70}, 2.5, {
			ease: FlxEase.quintOut,
			startDelay: 0.8
		});
	}
	
	function playCurrentAnim(forced:Bool = true)
	{
		if (curSelected < 0) curSelected = animsList.length - 1;
		if (curSelected >= animsList.length) curSelected = 0;
		
		final cur = animsList[curSelected];
		karidesDJ.animation.play(cur.anim, forced);
		karidesDJ.offset.set(cur.offsets[0], cur.offsets[1]);
		
		updateGhostAnim();
		updateHUD();
	}
	
	function updateGhostAnim()
	{
		if (ghostDJ == null) return;
		ghostDJ.visible = showGhost;
		
		// Ghost displays the idle animation as reference point
		var idleData = getAnimData('idle');
		if (idleData != null)
		{
			ghostDJ.animation.play('idle', false);
			ghostDJ.offset.set(idleData.offsets[0], idleData.offsets[1]);
		}
	}
	
	function getAnimData(anim:String):Null<DJAnimData>
	{
		for (a in animsList)
		{
			if (a.anim == anim) return a;
		}
		return null;
	}
	
	function updateHUD()
	{
		if (curAnimText == null) return;
		
		final cur = animsList[curSelected];
		curAnimText.text = 'Animation: [${cur.anim}] (${curSelected + 1}/${animsList.length})\n'
			+ 'Offset: [X: ${cur.offsets[0]}, Y: ${cur.offsets[1]}]\n'
			+ 'XML Prefix: "${cur.name}" | FPS: ${cur.fps} | Loop: ${cur.loop}';
		
		var listStr = "ANIMATIONS:\n";
		for (i in 0...animsList.length)
		{
			var a = animsList[i];
			var arrow = (i == curSelected ? "> " : "  ");
			var mark = (i == curSelected ? " <" : "");
			listStr += '$arrow${a.anim}: [${a.offsets[0]}, ${a.offsets[1]}]$mark\n';
		}
		listStr += '\nGhost (G): ${showGhost ? "ON" : "OFF"}\n';
		listStr += 'View (B): ${isBeachView ? "Beach/Panel" : "Grid"}';
		
		animListText.text = listStr;
	}
	
	override function update(elapsed:Float)
	{
		// 1. Navigation / Animation selection
		if (controls.UI_UP_P || FlxG.keys.justPressed.W)
		{
			curSelected--;
			if (curSelected < 0) curSelected = animsList.length - 1;
			playCurrentAnim(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		else if (controls.UI_DOWN_P || FlxG.keys.justPressed.S && !FlxG.keys.pressed.CONTROL)
		{
			curSelected++;
			if (curSelected >= animsList.length) curSelected = 0;
			playCurrentAnim(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		
		// 2. Replay animation
		if (FlxG.keys.justPressed.SPACE)
		{
			playCurrentAnim(true);
		}
		
		// 3. Mouse dragging for DJ offset (Left Click OR Right Click - exactly like Character Editor)
		var isOverAnimBox:Bool = (animBoxBG != null
			&& FlxG.mouse.screenX >= animBoxBG.x && FlxG.mouse.screenX <= animBoxBG.x + animBoxBG.width
			&& FlxG.mouse.screenY >= animBoxBG.y && FlxG.mouse.screenY <= animBoxBG.y + animBoxBG.height);
			
		if (FlxG.mouse.justPressed && isOverAnimBox)
		{
			var relY = FlxG.mouse.screenY - (animBoxBG.y + 26);
			var clickedIdx = Math.floor(relY / 20);
			if (clickedIdx >= 0 && clickedIdx < animsList.length)
			{
				curSelected = clickedIdx;
				playCurrentAnim(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
		}
		else if ((FlxG.mouse.pressed || FlxG.mouse.pressedRight) && !FlxG.mouse.pressedMiddle)
		{
			var dx:Float = FlxG.mouse.deltaViewX;
			var dy:Float = FlxG.mouse.deltaViewY;
			
			if (dx == 0 && dy == 0)
			{
				dx = (FlxG.mouse.screenX - lastMouseScreenX) / FlxG.camera.zoom;
				dy = (FlxG.mouse.screenY - lastMouseScreenY) / FlxG.camera.zoom;
			}
			
			if (dx != 0 || dy != 0)
			{
				animsList[curSelected].offsets[0] = Math.round(animsList[curSelected].offsets[0] - dx);
				animsList[curSelected].offsets[1] = Math.round(animsList[curSelected].offsets[1] - dy);
				karidesDJ.offset.set(animsList[curSelected].offsets[0], animsList[curSelected].offsets[1]);
				updateHUD();
			}
			
			karidesDJ.color = 0xFFFFFFAA;
		}
		else
		{
			karidesDJ.color = FlxColor.WHITE;
		}
		
		lastMouseScreenX = FlxG.mouse.screenX;
		lastMouseScreenY = FlxG.mouse.screenY;
		
		// 4. Keyboard Offset manipulation
		var shiftMult:Float = 1;
		if (FlxG.keys.pressed.SHIFT) shiftMult = 10;
		if (FlxG.keys.pressed.ALT) shiftMult = 50;
		
		var xNudge:Float = 0;
		var yNudge:Float = 0;
		
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.J) xNudge += shiftMult;
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.L) xNudge -= shiftMult;
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.I) yNudge += shiftMult;
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.K) yNudge -= shiftMult;
		
		if (xNudge != 0 || yNudge != 0)
		{
			animsList[curSelected].offsets[0] += xNudge;
			animsList[curSelected].offsets[1] += yNudge;
			karidesDJ.offset.set(animsList[curSelected].offsets[0], animsList[curSelected].offsets[1]);
			updateHUD();
		}
		
		// 4. Reset offset
		if (FlxG.keys.justPressed.R)
		{
			animsList[curSelected].offsets[0] = 0;
			animsList[curSelected].offsets[1] = 0;
			karidesDJ.offset.set(0, 0);
			updateHUD();
			showNotice('Reset offset for [${animsList[curSelected].anim}] to [0, 0]', 0xFFE0E0E0);
		}
		
		// 5. Toggle Ghost / Onion skin
		if (FlxG.keys.justPressed.G)
		{
			showGhost = !showGhost;
			updateGhostAnim();
			updateHUD();
		}
		
		// 6. Toggle Background
		if (FlxG.keys.justPressed.B)
		{
			isBeachView = !isBeachView;
			beachBG.visible = isBeachView;
			rightPanel.visible = isBeachView;
			gridBG.visible = !isBeachView;
			updateHUD();
		}
		
		// 7. Save
		if ((FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) || (!FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S && !controls.UI_DOWN))
		{
			saveDJData();
		}
		
		// 8. Camera Controls (Zoom & Pan)
		if (FlxG.mouse.wheel != 0)
		{
			FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom + (FlxG.mouse.wheel * 0.1), 0.4, 3.0);
		}
		
		if (FlxG.mouse.justPressedMiddle)
		{
			draggingCam = true;
			dragMouseStart.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
			dragCamStart.set(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
		}
		
		if (draggingCam)
		{
			if (FlxG.mouse.pressedMiddle)
			{
				var dx = (dragMouseStart.x - FlxG.mouse.screenX) / FlxG.camera.zoom;
				var dy = (dragMouseStart.y - FlxG.mouse.screenY) / FlxG.camera.zoom;
				FlxG.camera.scroll.set(dragCamStart.x + dx, dragCamStart.y + dy);
			}
			else
			{
				draggingCam = false;
			}
		}
		
		// Camera Reset
		if (FlxG.keys.justPressed.C)
		{
			FlxG.camera.zoom = 1.0;
			FlxG.camera.scroll.set(0, 0);
		}
		
		// 9. Exit back to MasterEditorMenu
		if (controls.BACK)
		{
			FlxG.mouse.visible = false;
			FlxG.switchState(() -> new MasterEditorMenu());
		}
		
		super.update(elapsed);
	}
	
	override function destroy()
	{
		FlxG.cameras.remove(camHUD);
		super.destroy();
	}
}
