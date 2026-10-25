package funkin.states;

import funkin.input.TurboControl;
import funkin.input.TurboControl.TurboControlGroup;
import funkin.backend.FallbackState;
import funkin.states.editors.ChartConverterState;
import funkin.data.Chart.ChartFormat;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

import funkin.backend.Difficulty;
import funkin.game.Rank;
import funkin.Mods;
import funkin.data.SongMetaData;
import funkin.states.editors.ChartEditorState;
import funkin.data.WeekData;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.data.*;
import funkin.objects.*;

// todo rewrite this its kinda messy and not that safe
class FreeplayState extends MusicBeatState
{
	public static var vocals:Null<FlxSound> = null;
	
	public var debugBG:FlxSprite;
	public var debugTxt:FlxText;
	
	public var songs:Array<FreeplaySong> = [];
	
	public var freeplayTabs:Array<FreeplayTab> = [];
	
	public static var currentTab:Int = 0;
	
	public var selector:FlxText;
	
	public static var curSelected:Int = 0;
	
	public var curDifficulty:Int = -1;
	
	public static var lastDifficultyName:String = '';
	
	public var scoreBG:FlxSprite;
	public var scoreText:FlxText;
	public var diffText:FlxText;
	public var tabText:FlxText;
	public var tabHint:FlxText;
	public var lerpScore:Int = 0;
	public var lerpRating:Float = 0;
	var rankTextFormat:Null<FlxTextFormat> = null;
	public var intendedScore:Int = 0;
	public var intendedRating:Float = 0;
	
	public var grpCards:FlxTypedGroup<FreeplayCard>;
	public var cardSelector:FlxSprite;
	public var diffSelectBox:FlxSprite;
	public var diffArrowLeft:FlxSprite;
	public var diffArrowRight:FlxSprite;
	public var sprDifficulty:FlxSprite;
	public var sprDifficultyOld:FlxSprite;
	public var diffTextOld:FlxText;
	var diffTweenIn:FlxTween;
	var diffTweenOut:FlxTween;
	var diffTextTweenIn:FlxTween;
	var diffTextTweenOut:FlxTween;
	public var grpSongs:FlxTypedGroup<Alphabet>;
	public var grpIcons:FlxTypedGroup<HealthIcon>;
	public var curPlaying:Bool = false;
	
	public var bg:FlxSprite;
	public var intendedColor:Int;
	public var rightPanel:FlxSprite;
	public var karidesDJ:FlxSprite;
	public var karidesOffsets:Map<String, Array<Float>> = [
		'intro' => [5, 424],
		'idle' => [0, 0],
		'confirm' => [18, -28]
	];
	public var karidesPos:Array<Float> = [875, 231];
	var busy:Bool = false;
	var songStarted:Bool = false;
	
	var mayGoToChartConverter:Bool = false;
	
	var turboGroup:TurboControlGroup;
	var turboDown:TurboControl;
	var turboUp:TurboControl;
	
	override function create()
	{
		FunkinAssets.cache.clearStoredMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);
		
		DiscordClient.changePresence("In the Menus");
		
		turboGroup = new TurboControlGroup();
		add(turboGroup);
		
		turboDown = TurboControl.fromAction('ui_down');
		turboGroup.add(turboDown);
		
		turboUp = TurboControl.fromAction('ui_up');
		turboGroup.add(turboUp);
		
		loadFreeplayData();
		
		if (freeplayTabs.length == 0)
		{
			CoolUtil.setTransSkip(true, false);
			persistentUpdate = false;
			FlxG.switchState(() -> new FallbackState('Cannot load Freeplay as there are no tabs loaded.', () -> FlxG.switchState(MainMenuState.new)));
			return;
		}
		
		initStateScript();
		
		scriptGroup.set('SongMetadata', FreeplaySong); // backwards compat bs ig
		scriptGroup.set('FreeplaySong', FreeplaySong);
		scriptGroup.set('WeekData', WeekData);
		
		bg = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		add(bg);
		bg.screenCenter();
		
		rightPanel = new FlxSprite();
		rightPanel.loadGraphic(Paths.image('menus/freeplay/rightpanel'));
		final panelWidth:Float = 615;
		rightPanel.scale.set(panelWidth / 712, FlxG.height / rightPanel.height);
		rightPanel.updateHitbox();
		rightPanel.x = FlxG.width - panelWidth;
		rightPanel.y = 0;
		rightPanel.antialiasing = ClientPrefs.globalAntialiasing;
		add(rightPanel);
		
		loadDJConfig();
		karidesDJ = new FlxSprite(karidesPos[0], karidesPos[1]);
		karidesDJ.frames = Paths.getSparrowAtlas('menus/freeplay/karidesdj');
		karidesDJ.animation.addByPrefix('intro', 'boyfriend dj intro', 24, false);
		karidesDJ.animation.addByPrefix('idle', 'Boyfriend DJ idle', 24, true);
		karidesDJ.animation.addByPrefix('confirm', 'Boyfriend DJ confirm', 24, false);
		karidesDJ.antialiasing = ClientPrefs.globalAntialiasing;
		karidesDJ.animation.finishCallback = (name:String) -> {
			if (name == 'intro')
			{
				playKaridesDJAnim('idle');
			}
			else if (name == 'confirm')
			{
				startSelectedSong();
			}
		};
		playKaridesDJAnim('intro', true);
		add(karidesDJ);
		
		grpCards = new FlxTypedGroup<FreeplayCard>();
		add(grpCards);
		
		cardSelector = new FlxSprite();
		cardSelector.frames = Paths.getSparrowAtlas('menus/freeplay/selector');
		cardSelector.animation.addByIndices('idle', 'selector', [0], '', 0, false);
		cardSelector.animation.addByPrefix('press', 'selector', 24, false);
		cardSelector.animation.play('idle');
		cardSelector.animation.finishCallback = (name:String) -> {
			if (name == 'press')
				cardSelector.animation.play('idle');
		};
		cardSelector.antialiasing = ClientPrefs.globalAntialiasing;
		cardSelector.x = 85 + 534 + 12;
		cardSelector.y = (FlxG.height - cardSelector.height) / 2;
		add(cardSelector);
		
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);
		
		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);
		
		diffSelectBox = new FlxSprite().loadGraphic(Paths.image('menus/freeplay/diffselectbox'));
		diffSelectBox.scale.set(0.84, 0.84);
		diffSelectBox.updateHitbox();
		diffSelectBox.x = FlxG.width - diffSelectBox.width + 35;
		diffSelectBox.y = -5;
		diffSelectBox.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffSelectBox);
		
		final darkCenterX:Float = diffSelectBox.x + (296.5 * diffSelectBox.scale.x);
		final darkCenterY:Float = diffSelectBox.y + (89.5 * diffSelectBox.scale.y);
		final darkRectW:Float = 342 * diffSelectBox.scale.x;
		final darkRectLeft:Float = diffSelectBox.x + (126 * diffSelectBox.scale.x);
		final darkRectRight:Float = diffSelectBox.x + (467 * diffSelectBox.scale.x);
		
		sprDifficultyOld = new FlxSprite();
		sprDifficultyOld.antialiasing = ClientPrefs.globalAntialiasing;
		sprDifficultyOld.visible = false;
		add(sprDifficultyOld);
		
		diffTextOld = new FlxText(darkRectLeft, 0, darkRectW, "", 34);
		diffTextOld.setFormat(Paths.font('round'), 34, FlxColor.WHITE, CENTER, OUTLINE, 0xFF2A1505);
		diffTextOld.antialiasing = ClientPrefs.globalAntialiasing;
		diffTextOld.visible = false;
		add(diffTextOld);

		sprDifficulty = new FlxSprite();
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		add(sprDifficulty);
		
		diffText = new FlxText(darkRectLeft, 0, darkRectW, "", 34);
		diffText.setFormat(Paths.font('round'), 34, FlxColor.WHITE, CENTER, OUTLINE, 0xFF2A1505);
		diffText.antialiasing = ClientPrefs.globalAntialiasing;
		diffText.y = darkCenterY - (diffText.height / 2);
		add(diffText);
		
		diffArrowLeft = new FlxSprite();
		diffArrowLeft.frames = Paths.getSparrowAtlas('menus/freeplay/diffselector');
		diffArrowLeft.animation.addByIndices('idle', 'Symbol 3', [0], '', 0, false);
		diffArrowLeft.animation.addByPrefix('press', 'Symbol 3', 24, false);
		diffArrowLeft.animation.play('idle');
		diffArrowLeft.animation.finishCallback = (name:String) -> {
			if (name == 'press')
				diffArrowLeft.animation.play('idle');
		};
		diffArrowLeft.scale.set(0.72, 0.72);
		diffArrowLeft.updateHitbox();
		diffArrowLeft.x = darkRectLeft - diffArrowLeft.width - 10;
		diffArrowLeft.y = darkCenterY - (diffArrowLeft.height / 2);
		diffArrowLeft.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffArrowLeft);
		
		diffArrowRight = new FlxSprite();
		diffArrowRight.frames = Paths.getSparrowAtlas('menus/freeplay/diffselector');
		diffArrowRight.animation.addByIndices('idle', 'Symbol 3', [0], '', 0, false);
		diffArrowRight.animation.addByPrefix('press', 'Symbol 3', 24, false);
		diffArrowRight.animation.play('idle');
		diffArrowRight.animation.finishCallback = (name:String) -> {
			if (name == 'press')
				diffArrowRight.animation.play('idle');
		};
		diffArrowRight.flipX = true;
		diffArrowRight.scale.set(0.72, 0.72);
		diffArrowRight.updateHitbox();
		diffArrowRight.x = darkRectRight + 10;
		diffArrowRight.y = diffArrowLeft.y;
		diffArrowRight.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffArrowRight);
		
		scoreBG = new FlxSprite();
		scoreBG.visible = false;
		add(scoreBG);
		
		final infoWidth:Float = 480;
		scoreText = new FlxText(FlxG.width - infoWidth - 25, diffSelectBox.y + diffSelectBox.height + 8, infoWidth, "", 22);
		scoreText.setFormat(Paths.font('round'), 22, FlxColor.WHITE, RIGHT, OUTLINE, 0xFF2A1505);
		scoreText.borderSize = 2;
		scoreText.antialiasing = ClientPrefs.globalAntialiasing;
		add(scoreText);
		
		tabText = new FlxText(scoreText.x, scoreText.y + 26, infoWidth, "", 18);
		tabText.setFormat(Paths.font('round'), 18, 0xFFFFE599, RIGHT, OUTLINE, 0xFF2A1505);
		tabText.borderSize = 1.5;
		tabText.antialiasing = ClientPrefs.globalAntialiasing;
		add(tabText);
		
		tabHint = new FlxText(scoreText.x, tabText.y + 22, infoWidth, "Press TAB to switch tabs.", 15);
		tabHint.setFormat(Paths.font('round'), 15, 0xFFE0E0E0, RIGHT, OUTLINE, 0xFF2A1505);
		tabHint.borderSize = 1.5;
		tabHint.antialiasing = ClientPrefs.globalAntialiasing;
		add(tabHint);
		
		if (freeplayTabs.length <= 1) tabHint.kill();
		
		if (freeplayTabs.length == 0) tabText.kill();
		
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);
		
		final leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		final size:Int = 16;
		
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.DEFAULT_FONT, size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		
		debugBG = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		debugBG.alpha = 0;
		add(debugBG);
		
		debugTxt = new FlxText(25, 0, FlxG.width - 50, '', 32);
		debugTxt.setFormat(Paths.DEFAULT_FONT, 32, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		debugTxt.borderSize = 2;
		debugTxt.screenCenter(Y);
		add(debugTxt);
		
		WeekData.setDirectoryFromWeek();
		
		if (lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeTab();
		
		super.create();
		scriptGroup.call('onCreate', []);
	}
	
	override function closeSubState()
	{
		changeSelection();
		persistentUpdate = true;
		super.closeSubState();
	}
	
	function createSongs()
	{
		grpSongs.clear();
		grpIcons.clear();
		grpCards.clear();
		
		final centerY:Float = (FlxG.height - 183) / 2; // 268.5
		final cardSpacing:Float = 215;
		
		if (cardSelector != null) cardSelector.alpha = 0;
		
		for (i in 0...songs.length)
		{
			var card:FreeplayCard = new FreeplayCard(35, -450 - (i * 90), songs[i].displayName);
			card.targetYIndex = i - curSelected;
			card.targetY = centerY + (card.targetYIndex * cardSpacing);
			if (card.targetYIndex == 0)
				card.targetX = 85;
			else if (card.targetYIndex < 0)
				card.targetX = 85 + (card.targetYIndex * 50);
			else
				card.targetX = 85 + (card.targetYIndex * 70);
			card.targetAlpha = (card.targetYIndex == 0 ? 1.0 : 0.55);
			card.targetScale = (card.targetYIndex == 0 ? 1.05 : 0.88);
			card.targetColor = (card.targetYIndex == 0 ? FlxColor.WHITE : 0xFF888899);
			card.bg.color = card.targetColor;
			card.alpha = 0;
			grpCards.add(card);
		}
		
		changeSelection();
	}
	
	public function addSong(songName:String, ?info:Array<Dynamic>, weekName:String = "")
	{
		var displayName:String = songName;
		var icon:String = "face";
		var color:String = "#8DA399";
		
		final meta = getSongMeta(songName);
		
		if (meta == null && info != null)
		{
			if (info[0] != null) displayName = info[0];
			if (info[1] != null) icon = info[1];
			if (info[2] != null) color = FlxColor.fromRGB(info[2][0], info[2][1], info[2][2]).toHexString();
		}
		else if (meta != null)
		{
			if (meta.displayName != null) displayName = meta.displayName;
			if (meta.freeplayIcon != null) icon = meta.freeplayIcon;
			if (meta.freeplayColor != null) color = meta.freeplayColor;
		}
		
		songs.push(new FreeplaySong(songName, displayName, weekName, icon, FlxColor.fromString(color)));
	}
	
	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null) return false;
		
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	
	var instPlaying:Int = -1;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		if (freeplayTabs.length == 0) return;
		
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));
		
		if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;
		
		var ratingSplit:Array<String> = Std.string(funkin.utils.MathUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2)
		{ // No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while (ratingSplit[1].length < 2)
		{ // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}
		
		final bestRank:String = Highscore.getRank(songs[curSelected].songName, curDifficulty);
		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)' + (bestRank != '' ? ' [$bestRank]' : '');
		
		@:privateAccess
		{
			if (scoreText._formatRanges.length == 0)
			{
				rankTextFormat = new FlxTextFormat();
				scoreText.addFormat(rankTextFormat);
			}
			
			final rankTagStart:Int = scoreText.text.lastIndexOf('[');
			if (bestRank != '' && rankTagStart >= 0)
			{
				rankTextFormat.format.color = Rank.getColor(bestRank);
				scoreText._formatRanges[0].range.start = rankTagStart + 1; // only the rank letter
				scoreText._formatRanges[0].range.end = rankTagStart + 1;
			}
			else
			{
				scoreText._formatRanges[0].range.start = 0;
				scoreText._formatRanges[0].range.end = 0;
			}
		}
		positionHighscore();
		
		if (cardSelector != null && grpCards != null && grpCards.members.length > curSelected && grpCards.members[curSelected] != null)
		{
			var selectedCard = grpCards.members[curSelected];
			final lerpRate:Float = FlxMath.getElapsedLerp(0.20, elapsed);
			final cardRight:Float = selectedCard.x + selectedCard.width + (selectedCard.width * (selectedCard.scale.x - 1) / 2);
			final targetSelX:Float = cardRight + 12;
			
			cardSelector.x = FlxMath.lerp(cardSelector.x, targetSelX, lerpRate);
			// Always lock cardSelector to the vertical center of the screen
			cardSelector.y = (FlxG.height - cardSelector.height) / 2;
			
			cardSelector.scale.x = FlxMath.lerp(cardSelector.scale.x, 1.0, lerpRate);
			cardSelector.scale.y = cardSelector.scale.x;
			cardSelector.alpha = FlxMath.lerp(cardSelector.alpha, selectedCard.alpha, lerpRate);
			
			if (cardSelector.animation.finished && cardSelector.animation.curAnim?.name == 'press')
				cardSelector.animation.play('idle');
		}
		
		if (diffArrowLeft != null && diffArrowRight != null)
		{
			final lerpRate:Float = FlxMath.getElapsedLerp(0.20, elapsed);
			diffArrowLeft.scale.x = FlxMath.lerp(diffArrowLeft.scale.x, 0.72, lerpRate);
			diffArrowLeft.scale.y = diffArrowLeft.scale.x;
			diffArrowRight.scale.x = FlxMath.lerp(diffArrowRight.scale.x, 0.72, lerpRate);
			diffArrowRight.scale.y = diffArrowRight.scale.x;
			
			if (diffArrowLeft.animation.finished && diffArrowLeft.animation.curAnim?.name == 'press')
				diffArrowLeft.animation.play('idle');
			if (diffArrowRight.animation.finished && diffArrowRight.animation.curAnim?.name == 'press')
				diffArrowRight.animation.play('idle');
		}
		
		if (busy)
		{
			super.update(elapsed);
			return;
		}
		
		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT) shiftMult = 3;
		
		if (freeplayTabs.length > 1)
		{
			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT) changeTab(-1);
				else changeTab(1);
				
				changeDiff();
				changeSelection();
			}
		}
		
		if (songs.length > 1)
		{
			if (turboDown.PRESSED || turboUp.PRESSED)
			{
				changeSelection((controls.UI_UP ? -shiftMult : shiftMult));
				changeDiff();
			}
		}
		
		if (mayGoToChartConverter)
		{
			if (controls.ACCEPT)
			{
				FlxG.switchState(() -> new funkin.states.editors.ChartConverterState());
				ChartConverterState.goToFreeplay = true;
			}
			if (controls.BACK)
			{
				mayGoToChartConverter = false;
				changeSelection();
			}
			
			super.update(elapsed);
			return;
		}
		
		if (FlxG.keys.justPressed.SEVEN)
		{
			persistentUpdate = false;
			openSubState(new funkin.states.editors.SongMetaEditor(songs[curSelected].songName));
			return;
		}
		
		if (FlxG.mouse.justPressed)
		{
			if (diffArrowLeft != null && FlxG.mouse.overlaps(diffArrowLeft)) changeDiff(-1);
			else if (diffArrowRight != null && FlxG.mouse.overlaps(diffArrowRight)) changeDiff(1);
		}
		
		if (controls.UI_LEFT_P) changeDiff(-1);
		else if (controls.UI_RIGHT_P) changeDiff(1);
		else if (controls.UI_UP_P || controls.UI_DOWN_P) changeDiff();
		
		if (controls.BACK)
		{
			persistentUpdate = false;
			
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(MainMenuState.new);
		}
		
		if (FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			if (instPlaying != curSelected)
			{
				destroyFreeplayVocals();
				if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
				Mods.currentModDirectory = songs[curSelected].folder;
				PlayState.SONG = Chart.fromSong(songs[curSelected].songName, curDifficulty);
				
				// ??? why would you ever to do rewrite this
				if (PlayState.SONG.needsVoices) vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else vocals = new FlxSound();
				
				FlxG.sound.list.add(vocals);
				FunkinSound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
			}
		}
		else if (controls.ACCEPT)
		{
			if (busy) return;
			busy = true;
			
			if (cardSelector != null)
			{
				cardSelector.animation.play('press', true);
				cardSelector.scale.set(1.25, 1.25);
			}
			
			FunkinSound.play(Paths.sound('confirmMenu'));
			
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.fadeOut(1.2, 0);
			}
			if (vocals != null)
			{
				vocals.fadeOut(1.2, 0);
			}
			
			if (karidesDJ != null)
			{
				playKaridesDJAnim('confirm', true);
				new flixel.util.FlxTimer().start(1.4, (tmr) -> {
					startSelectedSong();
				});
			}
			else
			{
				startSelectedSong();
			}
		}
		else if (controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		
		super.update(elapsed);
	}
	
	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}
	
	function loadDJConfig()
	{
		final jsonPath = "assets/game/data/dj/karides.json";
		#if sys
		if (sys.FileSystem.exists(jsonPath))
		{
			try
			{
				var content = sys.io.File.getContent(jsonPath);
				var data:Dynamic = haxe.Json.parse(content);
				if (data.position != null)
				{
					karidesPos[0] = data.position[0];
					karidesPos[1] = data.position[1];
				}
				if (data.animations != null)
				{
					var anims:Array<Dynamic> = data.animations;
					for (a in anims)
					{
						if (a.anim != null && a.offsets != null)
						{
							karidesOffsets.set(a.anim, [a.offsets[0], a.offsets[1]]);
						}
					}
				}
			}
			catch (e:Dynamic)
			{
				trace('Could not parse $jsonPath: $e');
			}
		}
		#end
	}
	
	public function playKaridesDJAnim(name:String, forced:Bool = false)
	{
		if (karidesDJ == null) return;
		karidesDJ.animation.play(name, forced);
		final off = karidesOffsets.get(name);
		if (off != null)
			karidesDJ.offset.set(off[0], off[1]);
		else
			karidesDJ.offset.set(0, 0);
	}
	
	function startSelectedSong()
	{
		if (songStarted) return;
		songStarted = true;
		
		persistentUpdate = false;
		
		final songName = Paths.sanitize(songs[curSelected].songName.toLowerCase());
		final songRet = PlayState.prepareForSong(songName, curDifficulty, false);
		
		if (songRet != null)
		{
			var error = songRet.toString();
			
			if (error.contains('incompatible format') && !error.contains(ChartFormat.UNKNOWN)) // scuffed method...
			{
				error += "\n\nIf you'd like to enter the chart converter press Accept.\nOtherwise, press Cancel to go back";
				mayGoToChartConverter = true;
			}
			
			final message = 'Failed to load song.\nException: $error';
			debugBG.alpha = 0.7;
			debugTxt.text = message;
			debugTxt.screenCenter(Y);
			
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			busy = false;
			songStarted = false;
			playKaridesDJAnim('idle');
			return;
		}
		
		if (FlxG.keys.pressed.SHIFT)
		{
			FlxG.switchState(ChartEditorState.new);
		}
		else
		{
			FlxG.switchState(PlayState.new);
		}
		
		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
		destroyFreeplayVocals();
	}
	
	function loadFreeplayData()
	{
		var mods:Array<{folder:String, enabled:Bool}> = Mods.getListAsArray();
		
		for (i in mods)
		{
			if (!i.enabled) continue;
			
			var freeplayData = getFreeplayData(i.folder);
			Mods.currentModDirectory = i.folder;
			
			var tabs = freeplayData?.tabs ?? null;
			
			if (tabs == null)
			{
				var dir = FunkinAssets.readDirectory('content/${i.folder}/data/weeks');
				
				var fromWeeks = [];
				for (week in dir)
				{
					final sanitizedWeek = Paths.sanitize(week).replace('.json', '');
					fromWeeks.push(sanitizedWeek);
				}
				
				tabs = [];
				tabs.push(
					{
						title: i.folder,
						directory: i.folder,
						fromWeeks: fromWeeks,
						songs: [],
					});
			}
			
			for (tab in tabs)
			{
				tab.directory = i.folder;
				freeplayTabs.push(tab);
			}
		}
	}
	
	function getSongMeta(song:String):Null<SongMetaData>
	{
		var path = SongMeta.getFromPath(Paths.json('$song/data/meta'));
		
		if (path == null) path = SongMeta.getFromPath(Paths.json('$song/meta'));
		
		return path;
	}
	
	function getFreeplayData(modFolder:String):Null<FreeplayData>
	{
		final freeplayDataPath = Paths.getPath('data/freeplay.json', modFolder, true);
		
		return FunkinAssets.exists(freeplayDataPath) ? FunkinAssets.parseJson5(FunkinAssets.getContent(freeplayDataPath)) : null;
	}
	
	function loadTab(tab:Int):Void
	{
		var tab = freeplayTabs[tab];
		if (tab.songs == null) tab.songs = [];
		
		if (tab.fromWeeks != null)
		{
			for (weekName in tab.fromWeeks)
			{
				if (weekIsLocked(weekName)) continue;
				
				var week:WeekData = WeekData.weeksLoaded[weekName];
				
				WeekData.setDirectoryFromWeek(week);
				
				// if week is null go to next item in loop
				if (week == null || (week.songs == null || week.songs.length <= 0)) continue;
				
				for (song in week.songs)
				{
					final name = Paths.sanitize(song[0]);
					final icon = song[1];
					final color = song[2];
					
					addSong(name, [name, icon, color]);
				}
			}
		}
		else Mods.currentModDirectory = tab.directory;
		for (song in tab.songs)
			addSong(song);
	}
	
	function changeDiff(change:Int = 0)
	{
		debugBG.alpha = 0;
		debugTxt.text = '';
		
		if (change < 0 && diffArrowLeft != null)
		{
			diffArrowLeft.animation.play('press', true);
			diffArrowLeft.scale.set(0.85, 0.85);
		}
		else if (change > 0 && diffArrowRight != null)
		{
			diffArrowRight.animation.play('press', true);
			diffArrowRight.scale.set(0.85, 0.85);
		}
		
		var hadOldGraphic:Bool = false;
		var hadOldText:Bool = false;
		
		if (change != 0)
		{
			if (diffTweenIn != null) { diffTweenIn.cancel(); diffTweenIn = null; }
			if (diffTweenOut != null) { diffTweenOut.cancel(); diffTweenOut = null; }
			if (diffTextTweenIn != null) { diffTextTweenIn.cancel(); diffTextTweenIn = null; }
			if (diffTextTweenOut != null) { diffTextTweenOut.cancel(); diffTextTweenOut = null; }
			
			if (sprDifficulty != null && sprDifficulty.visible && sprDifficulty.graphic != null)
			{
				sprDifficultyOld.loadGraphic(sprDifficulty.graphic);
				sprDifficultyOld.scale.set(sprDifficulty.scale.x, sprDifficulty.scale.y);
				sprDifficultyOld.updateHitbox();
				sprDifficultyOld.x = sprDifficulty.x;
				sprDifficultyOld.y = sprDifficulty.y;
				sprDifficultyOld.alpha = sprDifficulty.alpha;
				sprDifficultyOld.visible = true;
				hadOldGraphic = true;
			}
			else if (diffText != null && diffText.visible)
			{
				diffTextOld.text = diffText.text;
				diffTextOld.fieldWidth = diffText.fieldWidth;
				diffTextOld.x = diffText.x;
				diffTextOld.y = diffText.y;
				diffTextOld.alpha = diffText.alpha;
				diffTextOld.visible = true;
				hadOldText = true;
			}
		}
		else
		{
			if (sprDifficultyOld != null) sprDifficultyOld.visible = false;
			if (diffTextOld != null) diffTextOld.visible = false;
		}
		
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.difficulties.length - 1);
		
		lastDifficultyName = Difficulty.difficulties[curDifficulty];
		
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		
		PlayState.storyMeta.difficulty = curDifficulty;
		
		var diff:String = Difficulty.difficulties[curDifficulty];
		var sanitizedDiff:String = Paths.sanitize(diff);
		var hasDiffGraphic:Bool = Paths.fileExists('images/menus/story/difficulties/' + sanitizedDiff + '.png');
		
		final darkCenterX:Float = diffSelectBox.x + (296.5 * diffSelectBox.scale.x);
		final darkCenterY:Float = diffSelectBox.y + (89.5 * diffSelectBox.scale.y);
		final slideDist:Float = 55.0;
		final slideDir:Float = (change > 0) ? 1.0 : -1.0;
		final animDuration:Float = 0.15;
		
		if (hasDiffGraphic && sprDifficulty != null)
		{
			sprDifficulty.visible = true;
			if (diffText != null) diffText.visible = false;
			sprDifficulty.loadGraphic(Paths.image('menus/story/difficulties/' + sanitizedDiff));
			sprDifficulty.scale.set(0.85, 0.85);
			sprDifficulty.updateHitbox();
			
			final targetX:Float = darkCenterX - (sprDifficulty.width / 2);
			final targetY:Float = darkCenterY - (sprDifficulty.height / 2);
			sprDifficulty.y = targetY;
			
			if (change != 0)
			{
				sprDifficulty.x = targetX - (slideDir * slideDist);
				sprDifficulty.alpha = 0;
				diffTweenIn = FlxTween.tween(sprDifficulty, {x: targetX, alpha: 1}, animDuration, {
					ease: FlxEase.cubeOut,
					onComplete: (_) -> {
						diffTweenIn = null;
					}
				});
			}
			else
			{
				sprDifficulty.x = targetX;
				sprDifficulty.alpha = 1;
			}
		}
		else
		{
			if (sprDifficulty != null) sprDifficulty.visible = false;
			if (diffText != null)
			{
				diffText.visible = true;
				diffText.text = Difficulty.getCurrentDifficultyString().toUpperCase();
				diffText.fieldWidth = 342 * diffSelectBox.scale.x;
				diffText.updateHitbox();
				
				final targetX:Float = diffSelectBox.x + (126 * diffSelectBox.scale.x);
				final targetY:Float = darkCenterY - (diffText.height / 2);
				diffText.y = targetY;
				
				if (change != 0)
				{
					diffText.x = targetX - (slideDir * slideDist);
					diffText.alpha = 0;
					diffTextTweenIn = FlxTween.tween(diffText, {x: targetX, alpha: 1}, animDuration, {
						ease: FlxEase.cubeOut,
						onComplete: (_) -> {
							diffTextTweenIn = null;
						}
					});
				}
				else
				{
					diffText.x = targetX;
					diffText.alpha = 1;
				}
			}
		}
		
		if (change != 0)
		{
			if (hadOldGraphic && sprDifficultyOld != null)
			{
				final oldTargetX:Float = sprDifficultyOld.x + (slideDir * slideDist);
				diffTweenOut = FlxTween.tween(sprDifficultyOld, {x: oldTargetX, alpha: 0}, animDuration, {
					ease: FlxEase.cubeOut,
					onComplete: (_) -> {
						sprDifficultyOld.visible = false;
						diffTweenOut = null;
					}
				});
			}
			if (hadOldText && diffTextOld != null)
			{
				final oldTextTargetX:Float = diffTextOld.x + (slideDir * slideDist);
				diffTextTweenOut = FlxTween.tween(diffTextOld, {x: oldTextTargetX, alpha: 0}, animDuration, {
					ease: FlxEase.cubeOut,
					onComplete: (_) -> {
						diffTextOld.visible = false;
						diffTextTweenOut = null;
					}
				});
			}
		}
		
		positionHighscore();
	}
	
	function changeSelection(diff:Int = 0)
	{
		debugBG.alpha = 0;
		debugTxt.text = '';
		
		if (diff != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected = FlxMath.wrap(curSelected + diff, 0, songs.length - 1);
		
		
		if (grpIcons.members.length > 0)
		{
			grpIcons.forEach((icon) -> icon.alpha = 0.6);
			if (grpIcons.members[curSelected] != null) grpIcons.members[curSelected].alpha = 1;
		}
		
		final centerY:Float = (FlxG.height - 183) / 2; // 268.5
		final cardSpacing:Float = 215;
		
		for (idx => card in grpCards.members)
		{
			card.targetYIndex = idx - curSelected;
			card.targetY = centerY + (card.targetYIndex * cardSpacing);
			
			if (card.targetYIndex == 0)
			{
				card.targetX = 85;
				card.targetAlpha = 1.0;
				card.targetScale = 1.05;
				card.targetColor = FlxColor.WHITE;
				if (diff != 0) card.bounce();
			}
			else
			{
				if (card.targetYIndex < 0)
					card.targetX = 85 + (card.targetYIndex * 50);
				else
					card.targetX = 85 + (card.targetYIndex * 70);
				
				card.targetAlpha = 0.55;
				card.targetScale = 0.88;
				card.targetColor = 0xFF888899;
			}
		}
		
		if (cardSelector != null)
		{
			cardSelector.alpha = 1.0;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		
		Difficulty.reset();
		
		var songMeta = getSongMeta(songs[curSelected].songName);
		
		var weekDiffs:Array<String> = [];
		var songWeek = WeekData.weeksLoaded[songs[curSelected].week];
		if (songWeek != null) weekDiffs = songWeek.difficulties;
		
		if (songMeta != null && songMeta.difficulties != null)
		{
			Difficulty.difficulties = songMeta.difficulties;
		}
		else if (weekDiffs != null && weekDiffs.length > 0)
		{
			Difficulty.difficulties = weekDiffs;
		}
		
		if (Difficulty.difficulties.contains(Difficulty.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultDifficulties.indexOf(Difficulty.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}
		
		var newPos:Int = Difficulty.difficulties.indexOf(lastDifficultyName);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		changeDiff(0);
	}
	
	function changeTab(diff:Int = 0)
	{
		if (diff != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		var len = freeplayTabs.length - 1;
		if (len < 0) len = 0;
		
		currentTab = FlxMath.wrap(currentTab + diff, 0, len);
		tabText.text = "[ " + (freeplayTabs[currentTab].title ?? 'Unknown') + " ]";
		
		clearSongs();
		
		loadTab(currentTab);
		
		createSongs();
	}
	
	function clearSongs()
	{
		songs = [];
		
		if (grpCards != null)
		{
			grpCards.forEach(card -> card?.destroy());
			grpCards.clear();
		}
		
		if (grpSongs != null)
		{
			grpSongs.forEach(song -> song?.destroy());
			
			grpSongs.clear();
		}
		
		if (grpIcons != null)
		{
			grpIcons.forEach(icon -> icon?.destroy());
			
			grpIcons.clear();
		}
	}
	
	private function positionHighscore()
	{
		if (diffSelectBox != null)
		{
			final darkCenterX:Float = diffSelectBox.x + (296.5 * diffSelectBox.scale.x);
			final darkCenterY:Float = diffSelectBox.y + (89.5 * diffSelectBox.scale.y);

			if (sprDifficulty != null && sprDifficulty.visible)
			{
				if (diffTweenIn == null || !diffTweenIn.active)
				{
					sprDifficulty.x = darkCenterX - (sprDifficulty.width / 2);
					sprDifficulty.y = darkCenterY - (sprDifficulty.height / 2);
				}
			}
			else if (diffText != null)
			{
				if (diffTextTweenIn == null || !diffTextTweenIn.active)
				{
					diffText.fieldWidth = 342 * diffSelectBox.scale.x;
					diffText.x = diffSelectBox.x + (126 * diffSelectBox.scale.x);
					diffText.y = darkCenterY - (diffText.height / 2);
				}
			}
			
			if (scoreText != null)
			{
				scoreText.x = FlxG.width - scoreText.width - 25;
				scoreText.y = diffSelectBox.y + diffSelectBox.height + 8;
				if (tabText != null)
				{
					tabText.x = scoreText.x;
					tabText.y = scoreText.y + 26;
				}
				if (tabHint != null)
				{
					tabHint.x = scoreText.x;
					tabHint.y = tabText.y + 22;
				}
			}
		}
	}
}

class FreeplaySong
{
	public var displayName:String = "";
	public var songName:String = "";
	public var week:String = "";
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	
	public function new(song:String, displayName:String, week:String, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.displayName = displayName;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null) this.folder = '';
	}
}

typedef FreeplayData =
{
	var tabs:Array<FreeplayTab>;
}

typedef FreeplayTab =
{
	var title:String;
	
	// if you load a mod freshly without any week jsons the currentModDirectory isn't set
	// you dont have to define this in the mod folder but like you can i guess
	var directory:String;
	
	var ?fromWeeks:Array<String>;
	var ?songs:Array<String>;
}
