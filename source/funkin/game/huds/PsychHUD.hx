package funkin.game.huds;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxStringUtil;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.text.FlxText.FlxTextFormat;

import funkin.objects.Bar;
import funkin.objects.HealthIcon;
import funkin.objects.note.Note;
import funkin.game.modchart.ModManager;

// if the hud resembles psych u can just extend this instead of base
@:access(funkin.states.PlayState)
class PsychHUD extends BaseHUD
{
	var ratingGraphic:FlxSprite;
	var ratingNumGroup:FlxTypedGroup<FlxSprite>;
	
	var healthBar:Bar;
	var healthBarBG:FlxSprite;
	var iconP1:HealthIcon;
	var iconP2:HealthIcon;
	var scoreTxt:FlxText;
	
	var markupEnabled:Bool = true;
	var rankColors:Map<String, FlxColor> = [
		"KFC" => 0xFF54ff7c,
		"SFC" => 0xffffee56,
		"GFC" => 0xffffc156,
		"FC" => 0xfff16439,
		"SDCB" => 0xffff5959,
		"Clear" => 0xFFabfff4,
	];
	
	var timeTxt:FlxText;
	var timeBar:FlxSprite;
	var timeBarBG:FlxSprite;
	var timeBarUnder:FlxSprite;
	var timeBarFill:FlxSprite;
	var pixelZoom:Float = 6; // idgaf
	
	var ratingPrefix:String = "";
	var ratingSuffix:String = '';
	var comboPrefix:String = "";
	
	var comboTween:Bool = true;
	
	var textDivider = '•';
	var showRating:Bool = ClientPrefs.showRatings;
	var showRatingNum:Bool = ClientPrefs.showRatings;
	var showCombo:Bool = ClientPrefs.showRatings;
	var updateIconPos:Bool = true;
	var updateIconScale:Bool = true;
	var comboOffsets:Null<Array<Int>> = null; // So u can overwrite the users combo offset if needed without messing with clientprefs
	
	// TODO: Make combo shit change for week 6, the ground work is already there so incase someone else wants to come on in and mess w it.
	override function init()
	{
		name = 'PSYCH';
		
		ratingPrefix = Paths.RATINGS_PREFIX;
		comboPrefix = Paths.COMBO_PREFIX;
		
		final healthGraphic = FunkinAssets.exists(Paths.mods('images/${Paths.UI_PREFIX}healthBar')) ? '${Paths.UI_PREFIX}healthBar' : 'UI/healthBar';
		
		// animated healthbar background, sits behind the bar / icons / score text
		healthBarBG = new FlxSprite();
		healthBarBG.frames = Paths.getSparrowAtlas('UI/healthbarbg');
		healthBarBG.animation.addByPrefix('idle', 'healthbarbg', 24, true);
		healthBarBG.animation.play('idle');
		healthBarBG.scale.set(728.25 / 964, 226.8 / 301); // final size, no extra scaling
		healthBarBG.updateHitbox();
		healthBarBG.setPosition((FlxG.width - 728.25) / 2, 475); // centered, mock layout
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		add(healthBarBG);
		
		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.downScroll ? 0.89 : 0.11), healthGraphic, function() return parent.health, parent.healthBounds.min, parent.healthBounds.max);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alphaMultipler = ClientPrefs.healthBarAlpha;
		
		reloadHealthBarColors();
		add(healthBar);
		
		iconP1 = new HealthIcon(parent.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alphaMultipler = ClientPrefs.healthBarAlpha;
		add(iconP1);
		
		iconP2 = new HealthIcon(parent.dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alphaMultipler = ClientPrefs.healthBarAlpha;
		add(iconP2);
		
		scoreTxt = new FlxText(0, healthBarBG.y + 80, FlxG.width, "", 20); // inside the waves band
		scoreTxt.setFormat(Paths.font('round'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		
		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		
		// animated timebar background, sits behind the bar
		timeBarBG = new FlxSprite();
		timeBarBG.frames = Paths.getSparrowAtlas('UI/timebarbg');
		timeBarBG.animation.addByPrefix('idle', 'timebarbg', 24, true);
		timeBarBG.animation.play('idle');
		timeBarBG.scale.set(506.70 / 506, 92.05 / 92);
		timeBarBG.updateHitbox();
		timeBarBG.screenCenter(X);
		timeBarBG.y = !ClientPrefs.downScroll ? -12 : (FlxG.height - timeBarBG.height + 12);
		timeBarBG.flipY = ClientPrefs.downScroll;
		timeBarBG.scrollFactor.set();
		timeBarBG.visible = showTime && !ClientPrefs.hideHud;
		timeBarBG.alpha = 0;
		add(timeBarBG);
		
		final timeGraphic = FunkinAssets.exists(Paths.mods('images/${Paths.UI_PREFIX}timeBar')) ? '${Paths.UI_PREFIX}timeBar' : 'UI/timeBar';
		timeBar = new FlxSprite().loadGraphic(Paths.image(timeGraphic));
		timeBar.screenCenter(X);
		timeBar.y = !ClientPrefs.downScroll ? (timeBarBG.y + 18) : (timeBarBG.y + timeBarBG.height - 18 - timeBar.height);
		timeBar.scrollFactor.set();
		timeBar.alpha = 0;
		timeBar.visible = showTime && !ClientPrefs.hideHud;
		
		timeBarUnder = new FlxSprite(timeBar.x + 3, timeBar.y + 3).makeGraphic(Std.int(timeBar.width - 6), Std.int(timeBar.height - 6), 0xFF2F422F);
		timeBarUnder.scrollFactor.set();
		timeBarUnder.alpha = 0;
		timeBarUnder.visible = showTime && !ClientPrefs.hideHud;
		add(timeBarUnder);
		
		timeBarFill = new FlxSprite(timeBarUnder.x, timeBarUnder.y).makeGraphic(Std.int(timeBar.width - 6), Std.int(timeBar.height - 6), 0xFF46D646);
		timeBarFill.scrollFactor.set();
		timeBarFill.origin.set(0, 0);
		timeBarFill.scale.x = 0;
		timeBarFill.alpha = 0;
		timeBarFill.visible = showTime && !ClientPrefs.hideHud;
		add(timeBarFill);
		
		add(timeBar); // frame on top of the colors
		
		timeTxt = new FlxText(timeBar.x, timeBar.y + 2, timeBar.width, PlayState.SONG.song.toUpperCase(), 14);
		timeTxt.setFormat(Paths.font('round'), 14, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 1;
		timeTxt.visible = parent.updateTime = (showTime && !ClientPrefs.hideHud);
		add(timeTxt);
		
		updateTimeTxt(0);
		
		ratingGraphic = new FlxSprite();
		ratingGraphic.alpha = 0;
		add(ratingGraphic);
		
		ratingNumGroup = new FlxTypedGroup();
		add(ratingNumGroup);
		
		onUpdateScore(0, 0, 0);
		
		parent.scripts.set('healthBar', healthBar);
		parent.scripts.set('healthBarBG', healthBarBG);
		parent.scripts.set('iconP1', iconP1);
		parent.scripts.set('iconP2', iconP2);
		parent.scripts.set('scoreTxt', scoreTxt);
		parent.scripts.set('timeBarBG', timeBarBG);
		parent.scripts.set('timeBar', timeBar);
		parent.scripts.set('timeTxt', timeTxt);
		parent.scripts.set('ratingPrefix', ratingPrefix);
		parent.scripts.set('ratingSuffix', ratingSuffix);
		parent.scripts.set('comboPrefix', comboPrefix);
		parent.scripts.set('comboOffsets', comboOffsets);
		
		if (comboOffsets == null)
		{
			comboOffsets = ClientPrefs.comboOffset;
		}
	}
	
	override function onSongStart()
	{
		for (spr in [timeBarBG, timeBar, timeBarUnder, timeBarFill])
			FlxTween.tween(spr, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	}
	
	override function onUpdateScore(score:Int = 0, accuracy:Float = 0, misses:Int = 0, missed:Bool = false, bop:Bool = true)
	{
		final tempScore:String = 'Score: ${FlxStringUtil.formatMoney(score, false)}'
			+ (!parent.instakillOnMiss ? ' $textDivider Misses: ${misses}' : "");
			
		if (!missed && bop && !parent.cpuControlled) doScoreBop();
		
		scoreTxt.text = '${tempScore}\n';
	}
	
	var scoreTxtFormat:Null<FlxTextFormat> = null;
	var rankTxtFormat:Null<FlxTextFormat> = null;
	
	inline function applyScoreMarkup()
	{
		@:privateAccess
		{
			if (scoreTxt._formatRanges[0] == null)
			{
				scoreTxtFormat ??= new FlxTextFormat();
				
				scoreTxt.addFormat(scoreTxtFormat);
			}
			
			if (scoreTxt._formatRanges[1] == null)
			{
				rankTxtFormat ??= new FlxTextFormat();
				
				scoreTxt.addFormat(rankTxtFormat);
			}
			
			final text = scoreTxt.text;
			final rankStart:Int = text.lastIndexOf('$textDivider Rank:');
			
			scoreTxtFormat.format.color = rankColors.get(parent.ratingFC) ?? FlxColor.WHITE;
			
			scoreTxt._formatRanges[0].range.start = text.indexOf(parent.ratingFC);
			
			if (rankStart >= 0)
			{
				rankTxtFormat.format.color = parent.rankColor;
				
				scoreTxt._formatRanges[0].range.end = Std.int(Math.max(text.indexOf(parent.ratingFC), rankStart - 2));
				scoreTxt._formatRanges[1].range.start = text.length - 2; // only the rank letter
				scoreTxt._formatRanges[1].range.end = text.length - 2;
			}
			else
			{
				scoreTxt._formatRanges[0].range.end = text.length - 2;
				scoreTxt._formatRanges[1].range.start = 0;
				scoreTxt._formatRanges[1].range.end = 0;
			}
		}
		
		// var formats = [
		// 	new FlxTextFormatMarkerPair(new FlxTextFormat(rankColors.get(parent.ratingFC)), "<r>")
		// ];
		
		// scoreTxt.applyMarkup(scoreTxt.text, formats);
	}
	
	var scoreTextTwn:Null<FlxTween> = null;
	
	public function doScoreBop():Void
	{
		if (!ClientPrefs.scoreZoom) return;
		
		scoreTextTwn?.cancel();
		scoreTxt.scale.set(1.075, 1.075);
		scoreTextTwn = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
	}
	
	public function updateIconsPosition()
	{
		if (!updateIconPos) return;
		
		final iconOffset:Int = 26;
		if (!healthBar.leftToRight)
		{
			iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else
		{
			iconP1.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			iconP2.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		}
	}
	
	public function updateIconsScale(elapsed:Float)
	{
		if (!updateIconScale) return;
		
		final mult:Float = MathUtil.decayLerp(iconP1.scale.x, 1, 9, elapsed);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();
		
		final mult:Float = MathUtil.decayLerp(iconP2.scale.x, 1, 9, elapsed);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}
	
	public function updateIconsAnimation()
	{
		iconP1.updateIconAnim(healthBar.percent * 0.01);
		iconP2.updateIconAnim((100 - healthBar.percent) * 0.01);
	}
	
	public function reloadHealthBarColors()
	{
		var dad = parent.dad;
		var boyfriend = parent.boyfriend;
		if (!healthBar.leftToRight)
		{
			healthBar.setColors(dad.healthColour, boyfriend.healthColour);
		}
		else
		{
			healthBar.setColors(boyfriend.healthColour, dad.healthColour);
		}
	}
	
	public function flipBar()
	{
		healthBar.leftToRight = !healthBar.leftToRight;
		iconP1.flipX = !iconP1.flipX;
		iconP2.flipX = !iconP2.flipX;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		updateIconsPosition();
		updateIconsScale(elapsed);
		updateIconsAnimation();
		
		if (!parent.startingSong && !parent.paused && parent.updateTime && !parent.endingSong)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
			parent.songPercent = (curTime / parent.songLength);
			
			if (!Math.isNaN(parent.songPercent))
			{
				timeBarFill.scale.x = FlxMath.bound(parent.songPercent, 0, 1);
				updateTimeTxt(curTime);
			}
		}
	}
	
	public function updateTimeTxt(curTime:Float = 0):Void
	{
		var songCalc:Float = (parent.songLength - curTime);
		if (ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;
		
		var secondsTotal:Int = Math.floor(songCalc / 1000);
		if (secondsTotal < 0) secondsTotal = 0;
		
		switch (ClientPrefs.timeBarType)
		{
			case 'Time Left', 'Time Elapsed':
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
			case 'Song Name':
				timeTxt.text = PlayState.SONG.song.toUpperCase();
		}
	}
	
	override function beatHit()
	{
		if (!updateIconScale) return;
		
		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}
	
	override function onCharacterChange()
	{
		reloadHealthBarColors();
		iconP1.changeIcon(parent.boyfriend.healthIcon);
		iconP2.changeIcon(parent.dad.healthIcon);
	}
	
	override function popUpScore(daRating:funkin.game.Rating, combo:Int, note:funkin.objects.note.Note)
	{
		final ratingImage = daRating.image;
		
		final posX = FlxG.width * 0.35;
		
		if (ClientPrefs.hideHud) return;
		
		parent.scripts.call('onPopUpScore', [note, daRating, ratingGraphic, ratingNumGroup]);
		
		if (showRating)
		{
			FlxTween.cancelTweensOf(ratingGraphic, ['scale.x', 'scale.y', 'alpha']);
			ratingGraphic.alpha = 1;
			ratingGraphic.loadGraphic(Paths.image(ratingPrefix + ratingImage + ratingSuffix));
			ratingGraphic.screenCenter();
			ratingGraphic.x = posX - 40;
			ratingGraphic.y -= 60;
			ratingGraphic.x += comboOffsets[0];
			ratingGraphic.y -= comboOffsets[1];
			
			if (comboTween)
			{
				ratingGraphic.scale.set(0.785, 0.785);
				FlxTween.tween(ratingGraphic.scale, {x: 0.7, y: 0.7}, 0.5, {ease: FlxEase.expoOut});
			}
			ratingGraphic.updateHitbox();
			FlxTween.tween(ratingGraphic, {alpha: 0}, 0.5, {startDelay: Conductor.stepCrotchet * 0.01, ease: FlxEase.expoOut});
		}
		
		if (showRatingNum)
		{
			for (i in ratingNumGroup)
			{
				if (i.alive)
				{
					i.kill();
				}
			}
			
			var seperatedScore:Array<Int> = [];
			
			if (combo >= 1000)
			{
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);
			
			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = ratingNumGroup.recycle(FlxSprite);
				FlxTween.cancelTweensOf(numScore);
				
				numScore.loadGraphic(Paths.image(comboPrefix + 'num' + Std.int(i) + ratingSuffix));
				numScore.alpha = 1;
				numScore.screenCenter();
				numScore.x = posX + (43 * daLoop) - 90;
				numScore.y += 80;
				numScore.x += comboOffsets[2];
				numScore.y -= comboOffsets[3];
				
				if (comboTween)
				{
					numScore.scale.set(0.6, 0.6);
					FlxTween.cancelTweensOf(numScore, ['scale.x', 'scale.y']);
					FlxTween.tween(numScore.scale, {x: 0.5, y: 0.5}, 0.5, {ease: FlxEase.expoOut});
				}
				numScore.updateHitbox();
				ratingNumGroup.add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.5, {startDelay: Conductor.stepCrotchet * 0.01, ease: FlxEase.expoOut});
				
				daLoop++;
			}
		}
		
		parent.scripts.call('onPopUpScorePost', [note, daRating, ratingGraphic, ratingNumGroup]);
	}
	
	override function cachePopUpScore()
	{
		var ratings = ["sick", "good", "bad", "shit"];
		if (ClientPrefs.useEpicRankings) ratings.push('epic');
		
		for (rating in ratings)
		{
			ratingGraphic.loadGraphic(Paths.image('$ratingPrefix$rating$ratingSuffix'));
		}
		
		for (i in 0...10)
		{
			Paths.image('${comboPrefix}num$i$ratingSuffix');
		}
	}
}
