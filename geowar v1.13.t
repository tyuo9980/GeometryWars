% By Peter Li
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.13 - 3/30/12
% - Improved enemy spawns
% - Efficiency improvements:
% - Removed background grid
% - Removed image transparencies
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.12 - 5/31/11
% - Fixed sensitivity not saving in options
% - Fixed image transparency on most computers
% - Fixed music toggle
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.11 - 5/30/11
% - Reverted bar collision
% - Adjusted bar spawning
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.1 - 5/29/11
% - Added timed mode
% - Added leaderboard for timed mode
% - Added preliminary file protection
% - Added bar death collision
% - Changed bar collision
% - Various game tweaks
% - Various performance improvements
% - Various GUI improvements
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.01 - 5/28/11
% - Added explosion effects
% - Various game tweaks
% - Fixed save crash
% - Fixed leaderboard crash
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.0 - 5/27/11
% - Initial release
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import joystick

type joypad :                                                                           %creates joypad
    record
	button : array 1 .. 32 of boolean
	pos : joystick.PosRecord
	caps : joystick.CapsRecord
    end record

var joy : array 1 .. 2 of joypad

for i : 1 .. upper (joy)                                                                %assigns all values to false
    for ii : 1 .. upper (joy (i).button)
	joy (i).button (ii) := false
    end for
    joy (i).pos.POV := 66535
    joystick.Capabilities (i - 1, joy (i).caps)
end for

var enemynum : int                                                                      %total number of enemies
var multinum : int                                                                      %total number of multipliers
var barnum : int                                                                        %total number of bars
var lastenemynum : int                                                                  %for enemyspawn
var x, y : real := 0                                                                    %player coords
var ex : array 0 .. 1000 of real                                                        %enemy coords
var ey : array 0 .. 1000 of real
var enemii : array 1 .. 1000 of boolean                                                 %enemy filter
var barx : array 1 .. 1000 of real                                                      %bar center coords
var bary : array 1 .. 1000 of real
var barxt, baryt : int                                                                  %bar temp vars
var barii : array 1 .. 1000 of boolean                                                  %bar filter
var x1, x2, y1, y2 : array 1 .. 1000 of real                                            %two points of bar
var barpivotx : array 1 .. 1000 of int                                                  %bar pivot coords
var barpivoty : array 1 .. 1000 of int
var multx : array 1 .. 1000 of real                                                     %multi coords
var multy : array 1 .. 1000 of real
var multii : array 1 .. 1000 of boolean                                                 %multi filter
var b : int                                                                             %temp storage vars
var ta : int
var dx, dy : real
var rx, ry : int

var mx, my, button : int                                                                %for mouse.where
var deg : real                                                                          %player movement angle
var edeg : real                                                                         %enemy movement angle
var pdeg : int                                                                          %enemycollide angle
var bdeg : array 1 .. 1000 of int                                                       %bar movement angle
var bcdeg : int                                                                         %bar bounce angle
var brdeg : array 1 .. 1000 of int                                                      %bar rotate angle
var brdir : array 1 .. 1000 of int                                                      %bar rotate direction
var mdeg : real                                                                         %multiplier angle
var speed : real                                                                        %player movement speed
var rsens : int                                                                         %keyboard turning sensitivity
var multi : int                                                                         %multiplier
var spawnl : int                                                                        %bar spawn location
var spawnc : int                                                                        %bar spawn count

var timer : int                                                                         %time counter
var timenow, timelast : int                                                             %keeps track of time
var spawntimenow, spawntimelast : int
var barspawntimenow, barspawntimelast : int
var barrotatetimenow, barrotatetimelast : int
var barmovetimenow, barmovetimelast : int
var looptimenow, looptimelast : int
var multitimenow, multitimelast : array 1 .. 1000 of int

var music : boolean := true                                                             %mute/unmute music
var back2menu : boolean
var quitgame : boolean

var fnum : int := 1                                                                     %scoreboard vars
var text : string
var names : array 0 .. 21 of string
var scores : array 0 .. 21 of int
var score : int
var name : string
var swap : boolean

var settings : string                                                                   %game setting vars
var rsenst : int
var mkb : int
var pintro : int
var mkbstatus : string
var pintrostatus : string
var mouseinput : boolean
var keyinput : boolean
var joystickinput : boolean
var timed : boolean

var key : string (1)                                                                    %input vars
var chars : array char of boolean

View.Set ("graphics:800;600, nobuttonbar, nocursor, offscreenonly")

var picon : array 0 .. 360 of int                                                       %picture vars
var pmulti : int
var penemy : int

picon (0) := Pic.FileNew ("pictures/playericon.bmp")
pmulti := Pic.FileNew ("pictures/multi.bmp")
penemy := Pic.FileNew ("pictures/enemy.bmp")

Pic.SetTransparentColor (pmulti, black)
Pic.SetTransparentColor (penemy, black)

for angle : 0 .. 360
    picon (angle) := Pic.Rotate (picon (0), angle, 17, 17)
    %Pic.SetTransparentColor (picon (angle), black)
end for

process musiclose                                                                       %music processes
    Music.PlayFile ("audio/lose.wav")
end musiclose

process musicintro
    Music.PlayFile ("audio/intro.wav")
end musicintro

process mainmusic
    Music.PlayFileLoop ("audio/main.mp3")
end mainmusic

process musicspawn
    Music.PlayFile ("audio/spawn.mp3")
end musicspawn

process musicbar
    Music.PlayFile ("audio/bar.wav")
end musicbar

procedure setjoystick %(joystickNO : int)                                               %reads joystick values
    %joystick.GetInfo (joystickNO, joy (joystickNO + 1).button)
    joystick.Read (joystick1, joy (1).pos)
end setjoystick

procedure readsettings
    open : fnum, "settings.ini", get
    get : fnum, settings : *
    close : fnum

    rsens := strint (settings (9))
    mkb := strint (settings (18))
    pintro := strint (settings (29))

    if mkb = 1 then                                                                     %sets as mouse controls
	mouseinput := true
	keyinput := false
	joystickinput := false
	mkbstatus := "Mouse"
    elsif mkb = 2 then                                                                  %sets as keyboard controls
	mouseinput := false
	keyinput := true
	joystickinput := false
	mkbstatus := "Keyboard"
    elsif mkb = 3 then                                                                  %sets as joystick controls
	mouseinput := false
	keyinput := false
	joystickinput := true
	mkbstatus := "Joystick"
    end if

    if pintro = 1 then                                                                  %intro
	pintrostatus := "On"
    elsif pintro = 0 then
	pintrostatus := "Off"
    end if
end readsettings

procedure setmap                                                                        %creates background
    Draw.FillBox (1, 1, 800, 600, black)
    colourback (black)
    colour (white)
end setmap

procedure reset
    x := 400
    y := 300
    deg := 0
    timer := 0
    score := 0
    speed := 0
    multi := 1
    barnum := 0
    enemynum := 0
    multinum := 0
    lastenemynum := 1
    spawnc := 0
    ex (enemynum + 1) := 0
    ey (enemynum + 1) := 0
    back2menu := false
    quitgame := false
end reset

procedure intro
    fork musicintro

    for a : 16 .. 31
	locatexy (230, 300)
	color (a)
	put "This pro Geometry Wars clone is by..."
	View.Update
	delay (50)
    end for

    for decreasing b : 31 .. 16
	locatexy (230, 300)
	color (b)
	put "This pro Geometry Wars clone is by..."
	View.Update
	delay (50)
    end for

    for c : 16 .. 31
	locatexy (435, 300)
	color (c)
	put "Peter Li"
	View.Update
	delay (100)
    end for

    delay (1250)
end intro

function slopeang (y : real, x : real) : real                                           %calculates degree of slope
    if y = 0 and x > 0 or x = 0 and y = 0 then                                          %upwards vertical
	result 0
    elsif y = 0 and x < 0 then                                                          %downwards vertical
	result 180
    elsif x = 0 and y > 0 then                                                          %right horizontal
	result 90
    elsif x = 0 and y < 0 then                                                          %left horizontal
	result 270
    elsif x < 0 then
	result (arctand (y / x) - 180) mod 360                                          %tan-1
    else
	result arctand (y / x) mod 360
    end if
end slopeang

function joyslopeang (y : real, x : real) : real                                        %slope angle for joystick
    if x > 32768 then
	result arctand (- (y - 32768) / (x - 32768)) mod 360
    else
	result (arctand ((y - 32768) / - (x - 32768)) - 180) mod 360
    end if
end joyslopeang

process explosion
    for e : 105 .. 135                                                                  %draws explosion ring
	delay (5)
	Draw.Oval (round (x1 (ta)), round (y1 (ta)), e, e, 44)
	Draw.Oval (round (x2 (ta)), round (y2 (ta)), e, e, 44)
	View.Update
    end for
end explosion

procedure leaderboard                                                                   %draws leaderboard
    put "[0] Return"
    put ""
    put "           Survival                                         Timed"

    open : fnum, "score.gwf", get, mod                                                  %retrieves data for survival
    for x : 1 .. 20
	exit when eof (fnum)
	get : fnum, names (x) : *
	get : fnum, scores (x)
    end for
    close : fnum

    for x : 1 .. 20
	put names (x) : 20, "   ", scores (x)
    end for

    open : fnum, "svlscore.gwf", get, mod                                               %retrieves data for timed
    for x : 1 .. 20
	exit when eof (fnum)
	get : fnum, names (x) : *
	get : fnum, scores (x)
    end for
    close : fnum

    for x : 1 .. 20                                                                     %outputs info
	locate (x + 3, 50)
	put names (x) : 20, "   ", scores (x)
    end for

    View.Update

    loop
	getch (key)
	if key = "0" then
	    exit
	end if
    end loop
end leaderboard

procedure savefile                                                                      %saves score if game is over
    Music.PlayFileStop
    fork musiclose

    View.Set ("graphics:800;600, nobuttonbar, nocursor, nooffscreenonly")
    cls
    locatexy (maxx div 2 - 25, maxy div 2)
    put "GAME OVER"
    locatexy (375, 500)
    put "Enter name"
    locatexy (375, 475)
    get name : *

    if name = "" then
	name := "player"
    end if

    if timed = false then
	open : fnum, "score.gwf", get, mod                                              %retrieves old data
    else
	open : fnum, "svlscore.gwf", get, mod
    end if
    for x : 1 .. 20
	exit when eof (fnum)
	get : fnum, names (x) : *
	get : fnum, scores (x)
    end for
    close : fnum

    names (21) := name                                                                  %temp storage
    if timed = false then
	scores (21) := score
    else
	scores (21) := timer
    end if

    for x : 1 .. 20                                                                     %bubblesort
	swap := false
	for y : 1 .. 21 - x
	    if scores (y) < scores (y + 1) then
		scores (0) := scores (y)
		names (0) := names (y)
		scores (y) := scores (y + 1)
		names (y) := names (y + 1)
		scores (y + 1) := scores (0)
		names (y + 1) := names (0)
		swap := true
	    end if
	end for
	exit when swap = false
    end for

    if timed = false then
	open : fnum, "score.gwf", put                                                   %saves sorted data
    else
	open : fnum, "svlscore.gwf", put
    end if
    for x : 1 .. 20
	put : fnum, names (x)
	put : fnum, scores (x)
    end for
    close : fnum

    View.Set ("graphics:800;600, nobuttonbar, nocursor, offscreenonly")

    loop                                                                                %prompts for retry
	cls
	setmap
	Input.KeyDown (chars)
	put "Do you want to retry? (Y/N)"
	locatexy (340, 400)
	if timed = false then
	    put "Your score: ", score
	else
	    put "Your time: ", timer
	end if
	locatexy (maxx div 2 - 25, maxy div 2)
	put "GAME OVER"
	if chars ('y') or chars ('Y') then
	    back2menu := true
	    exit
	elsif chars ('n') or chars ('N') then
	    quitgame := true
	    exit
	end if

	View.Update
    end loop
end savefile

procedure getinput
    if hasch then
	getch (key)
	if key = "p" or key = "P" then                                                  %pause
	    cls
	    put "Enter any key to resume"
	    View.Update
	    getch (key)
	    View.Update
	elsif key = "m" or key = "M" then                                               %toggle music
	    if music then
		Music.PlayFileStop
		music := false
	    else
		music := true
		fork mainmusic
	    end if
	elsif key = "0" then                                                            %exit
	    loop
		cls
		put "Are you sure you want to quit? (Y/N)"
		Input.KeyDown (chars)
		if chars ('y') or chars ('Y') then
		    back2menu := true
		    exit
		elsif chars ('n') or chars ('N') then
		    exit
		end if
		View.Update
	    end loop
	end if
    end if

    if mouseinput then                                                                  %mouse input
	Mouse.Where (mx, my, button)
	if button = 1 then
	    speed += 0.2                                                                %slight accelleration
	    if speed > 2.8 then
		speed := 2.8
	    end if
	else
	    speed -= 0.2
	    if speed < 0 then
		speed := 0
	    end if
	end if
    elsif joystickinput then                                                            %joystick input
	%for i : joystick1 .. joystick2
	setjoystick %(joystick1)
	%end for

	if joy (1).pos.xpos > 25000 and joy (1).pos.xpos < 40000 and joy (1).pos.ypos > 25000 and joy (1).pos.ypos < 40000 then
	    speed -= 0.2                                                                %^sets deadzone^
	    if speed < 0 then
		speed := 0
	    end if
	else
	    speed += 0.2
	    if speed > 2.8 then
		speed := 2.8
	    end if
	end if
    else                                                                                %keyboard input
	Input.KeyDown (chars)
	if chars (KEY_UP_ARROW) then
	    speed += 0.2
	    if speed > 2.8 then
		speed := 2.8
	    end if
	else
	    speed -= 0.2
	    if speed < 0 then
		speed := 0
	    end if
	end if

	if chars (KEY_LEFT_ARROW) then                                                  %counter clockwise
	    deg += rsens
	elsif chars (KEY_RIGHT_ARROW) then                                              %clockwise
	    deg -= rsens
	end if
    end if
end getinput

procedure multitimer                                                                    %multi display time limit
    for timer : 1 .. multinum
	if multii (timer) then
	    if multitimenow (timer) - multitimelast (timer) > 4000 then                 %disappears after 4 seconds
		multitimelast (timer) := multitimenow (timer)
		multii (timer) := false
	    end if
	end if
    end for
end multitimer

procedure drawstats
    Draw.Text ("Press 0 to return to menu", 20, 585, defFontID, white)
    Draw.Text ("Press P to pause", 20, 570, defFontID, white)
    Draw.Text ("Press M to toggle music", 20, 555, defFontID, white)
    Draw.Text ("Time: " + intstr (floor (timer / 60)) + ":" + intstr (timer mod 60), 375, 585, defFontID, white)
    if timed = false then
	Draw.Text ("Score: " + intstr (score), 630, 585, defFontID, white)
	Draw.Text ("Multi: " + intstr (multi), 630, 570, defFontID, white)
    end if
end drawstats

procedure drawgrid                                                                      %for background
    for v : 0 .. 40 by 2
	Draw.Line (20 * v + 20, 1, 20 * v + 20, 600, 19)
    end for

    for h : 0 .. 30 by 2
	Draw.Line (1, 20 * h + 20, 800, 20 * h + 20, 19)
    end for

    for dv : 1 .. 20
	Draw.Line (40 * dv, 1, 40 * dv, 600, 23)
    end for

    for dh : 1 .. 15
	Draw.Line (1, 40 * dh, 800, 40 * dh, 23)
    end for
end drawgrid

procedure drawbar
    for draw : 1 .. barnum
	if barii (draw) then
	    if barrotatetimenow - barrotatetimelast > 50 then                           %rotation speed
		barrotatetimelast := barrotatetimenow
		for rot : 1 .. barnum
		    if barii (rot) then
			if brdir (rot) = 1 then                                         %clockwise
			    brdeg (rot) -= 1
			    if brdeg (rot) = 0 then
				brdeg (rot) := 360
			    end if
			else                                                            %counter clockwise
			    brdeg (rot) += 1
			    if brdeg (rot) = 360 then
				brdeg (rot) := 0
			    end if
			end if
		    end if
		end for
	    end if

	    if barmovetimenow - barmovetimelast > 35 then                               %movement speed
		barmovetimelast := barmovetimenow
		for move : 1 .. barnum
		    if barii (move) then
			barx (move) += cosd (bdeg (move))                               %calculates coords
			bary (move) += sind (bdeg (move))
		    end if
		end for
	    end if

	    x1 (draw) := barx (draw) + (60 * cosd (brdeg (draw)))                       %draws diverging lines from origin
	    y1 (draw) := bary (draw) + (60 * sind (brdeg (draw)))
	    x2 (draw) := barx (draw) + (60 * cosd (brdeg (draw) - 180))
	    y2 (draw) := bary (draw) + (60 * sind (brdeg (draw) - 180))

	    Draw.ThickLine (round (barx (draw)), round (bary (draw)), round (x1 (draw)), round (y1 (draw)), 5, 43)
	    Draw.ThickLine (round (barx (draw)), round (bary (draw)), round (x2 (draw)), round (y2 (draw)), 5, 43)
	    Draw.Oval (round (x1 (draw)), round (y1 (draw)), 4, 4, 31)
	    Draw.Oval (round (x2 (draw)), round (y2 (draw)), 4, 4, 31)
	end if
    end for
end drawbar

procedure drawmulti
    multitimer

    for draw : 1 .. multinum
	if multii (draw) then
	    mdeg := slopeang (y - 8 - multy (draw), x - 8 - multx (draw))               %calculates slopeang of player xy to multi xy
	    if ((x - multx (draw)) ** 2) + ((y - multy (draw)) ** 2) < 5625 then        %calculates distance. 75x75 = 5625 to remove sqrt
		multx (draw) += 4 * cosd (mdeg)                                         %calculates coords
		multy (draw) += 4 * sind (mdeg)
		if ((x - multx (draw)) ** 2) + ((y - multy (draw)) ** 2) < 225 then     %collects multi
		    multi += 2
		    multii (draw) := false
		end if
	    end if
	    Pic.Draw (pmulti, round (multx (draw)), round (multy (draw)), picCopy)
	end if
    end for
end drawmulti

procedure drawplayer
    if mouseinput then
	deg := slopeang (my - y, mx - x)                                                %calculates slopeang of mouse xy to player xy
    elsif joystickinput then
	deg := joyslopeang (joy (1).pos.ypos, joy (1).pos.xpos)
    end if

    x += speed * cosd (deg)                                                             %calculates coords
    y += speed * sind (deg)
    pdeg := round (deg) mod 360
    Pic.Draw (picon (pdeg), round (x) - 17, round (y) - 17, picMerge)
end drawplayer

procedure drawenemy
    for draw : 1 .. enemynum
	if enemii (draw) then
	    edeg := slopeang (y - 10 - ey (draw), x - 10 - ex (draw))                   %calculates slopeang of player xy to enemy xy
	    ex (draw) += cosd (edeg)                                                    %calculates coords
	    ey (draw) += sind (edeg)
	    Pic.Draw (penemy, round (ex (draw)), round (ey (draw)), picCopy)
	end if
    end for
end drawenemy

procedure spawnenemy
    spawnc += 1
    randint (spawnl, 1, 4)
    enemynum += 3 + floor (spawnc / 4)

    if spawnl = 1 then                                                                  %top right corner
	for s : lastenemynum .. enemynum
	    randint (rx, 780, 800)
	    randint (ry, 580, 600)
	    ex (s) := rx
	    ey (s) := ry
	    enemii (s) := true
	end for
    elsif spawnl = 2 then                                                               %top left corner
	for s : lastenemynum .. enemynum
	    randint (rx, 1, 20)
	    randint (ry, 580, 600)
	    ex (s) := rx
	    ey (s) := ry
	    enemii (s) := true
	end for
    elsif spawnl = 3 then                                                               %bottom left corner
	for s : lastenemynum .. enemynum
	    randint (rx, 1, 20)
	    randint (ry, 1, 20)
	    ex (s) := rx
	    ey (s) := ry
	    enemii (s) := true
	end for
    else                                                                                %bottom right corner
	for s : lastenemynum .. enemynum
	    randint (rx, 780, 800)
	    randint (ry, 1, 20)
	    ex (s) := rx
	    ey (s) := ry
	    enemii (s) := true
	end for
    end if

    lastenemynum := enemynum + 1
end spawnenemy

procedure spawnbar
    barnum += 1                                                                         %sets spawned bar properties
    randint (bdeg (barnum), 1, 360)
    randint (brdir (barnum), 1, 2)
    randint (brdeg (barnum), 1, 360)
    barii (barnum) := true
    loop                                                                                %prevents spawning near player
	randint (barxt, 61, 739)
	randint (baryt, 61, 539)
	barx (barnum) := barxt
	bary (barnum) := baryt
	x1 (barnum) := barx (barnum) + (60 * cosd (brdeg (barnum)))
	y1 (barnum) := bary (barnum) + (60 * sind (brdeg (barnum)))
	x2 (barnum) := barx (barnum) + (60 * cosd (brdeg (barnum) - 180))
	y2 (barnum) := bary (barnum) + (60 * sind (brdeg (barnum) - 180))
	exit when ((x - x1 (barnum)) ** 2) + ((y - y1 (barnum)) ** 2) > 22500 and ((x - x2 (barnum)) ** 2) + ((y - y2 (barnum)) ** 2) > 22500
    end loop
end spawnbar

procedure enemycollide
    for a : 1 .. enemynum - 1                                                           %enemy self collision
	if enemii (a) then
	    for b : a + 1 .. enemynum
		if enemii (b) then
		    dx := ex (b) - ex (a)
		    dy := ey (b) - ey (a)
		    if (dx ** 2) + (dy ** 2) < 900 then                                 %calculates distance to check collision. 30x30 = 900 to remove sqrt
			ex (b) += dx / 29
			ey (b) += dy / 29
		    end if
		end if
	    end for
	end if
    end for
end enemycollide

procedure boundarycollide
    if x < 15 then                                                                      %left side
	x := 15
    end if

    if x > 785 then                                                                     %right side
	x := 785
    end if

    if y < 15 then                                                                      %bottom
	y := 15
    end if

    if y > 585 then                                                                     %top
	y := 585
    end if
end boundarycollide

procedure deathcollide
    for a : 1 .. enemynum                                                               %if player hits enemy
	if enemii (a) then
	    if ((x - (ex (a) + 14)) ** 2) + ((y - (ey (a) + 14)) ** 2) < 500 then
		savefile
		exit
	    end if
	end if
    end for

    for b : 1 .. barnum                                                                 %if player hits bar tips
	if barii (b) then
	    if ((x - x1 (b)) ** 2) + ((y - y1 (b)) ** 2) < 225 or ((x - x2 (b)) ** 2) + ((y - y2 (b)) ** 2) < 225 then
		savefile
		exit
	    end if
	end if
    end for
end deathcollide

procedure barbcollide
    for a : 1 .. barnum                                                                 %bar boundary
	if barii (a) then
	    if barx (a) > 798 then                                                      %right wall
		barx (a) := 796
		bdeg (a) := -bdeg (a) - 180                                             %reverses direction (bounce)
	    elsif barx (a) < 2 then                                                     %left wall
		barx (a) := 4
		bdeg (a) := -bdeg (a) - 180
	    elsif bary (a) > 598 then                                                   %top wall
		bary (a) := 596
		bdeg (a) := -bdeg (a)
	    elsif bary (a) < 2 then                                                     %bottom wall
		bary (a) := 4
		bdeg (a) := -bdeg (a)
	    end if
	end if
    end for
end barbcollide

procedure barpcollide
    for a : 1 .. barnum                                                                 %if player hits bar
	if barii (a) then
	    if sqrt ((x1 (a) - x) ** 2 + (y1 (a) - y) ** 2) + sqrt ((x2 (a) - x) ** 2 + (y2 (a) - y) ** 2) < 132 then
		ta := a                                                                 %temp var for explosion
		fork musicbar
		fork explosion
		barii (a) := false                                                      %'kills' shape
		score += 50 * multi                                                     %adds score
		multi += 2                                                              %increases multiplier

		for b : 1 .. enemynum                                                   %enemy die if within bar explosion radius
		    if enemii (b) then
			if ((x1 (a) - (ex (b) + 14)) ** 2 + (y1 (a) - (ey (b) + 14)) ** 2) < 15625 or ((x2 (a) - (ex (b) + 14)) ** 2 + (y2 (a) - (ey (b) + 14)) ** 2) < 19600 then
			    enemii (b) := false
			    score += 50 * multi
			    multinum += 1                                               %spawns multi
			    multii (multinum) := true
			    multx (multinum) := ex (b)
			    multy (multinum) := ey (b)
			    multitimelast (multinum) := Time.Elapsed
			end if
		    end if
		end for
	    end if
	end if
    end for
end barpcollide

procedure collide
    boundarycollide
    enemycollide
    deathcollide
    barbcollide
    barpcollide
end collide

procedure startgame
    if music then
	fork mainmusic
    end if
    fork musicspawn

    timelast := Time.Elapsed
    looptimelast := Time.Elapsed
    spawntimelast := Time.Elapsed
    barspawntimelast := Time.Elapsed
    barrotatetimelast := Time.Elapsed
    barmovetimelast := Time.Elapsed
    spawnenemy

    loop
	if quitgame or back2menu then
	    exit
	end if

	timenow := Time.Elapsed
	looptimenow := Time.Elapsed
	spawntimenow := Time.Elapsed
	barspawntimenow := Time.Elapsed
	barrotatetimenow := Time.Elapsed
	barmovetimenow := Time.Elapsed
	for i : 1 .. multinum
	    if multii (i) then
		multitimenow (i) := Time.Elapsed
	    end if
	end for

	if timenow - timelast > 999 then                                                %timer
	    timelast := timenow
	    timer += 1
	end if

	if looptimenow - looptimelast > 8.33 then                                       %limits to 120 fps
	    looptimelast := looptimenow

	    if spawntimenow - spawntimelast > 1750 then                                 %enemy spawn time
		spawntimelast := spawntimenow
		spawnenemy
	    end if

	    if barspawntimenow - barspawntimelast > 2000 then                           %bar spawn time
		barspawntimelast := barspawntimenow
		spawnbar
	    end if

	    cls
	    getinput
	    %drawgrid
	    drawplayer
	    drawenemy
	    drawbar
	    if timed = false then
		drawmulti
	    end if
	    drawstats
	    collide
	    View.Update
	end if
    end loop
end startgame

procedure options
    loop
	cls
	put "[1] Change Rotate Sensitivity (keyboard only)"
	put "[2] Toggle Intro: ", pintrostatus
	put "[3] Control Type: ", mkbstatus
	put ""
	put "[0] Menu"

	if hasch then
	    getch (key)
	    if key = "1" then
		open : fnum, "settings.ini", put
		loop
		    cls
		    put "Press 0 to save/exit"
		    put "Use up/down arrows"
		    put "Sensitivity: ", rsens
		    put "Default: 3"
		    View.Update
		    getch (key)
		    if key = chr (200) then                                             %up arrow
			rsens += 1
			if rsens > 9 then
			    rsens := 9
			end if
		    elsif key = chr (208) then                                          %down arrow
			rsens -= 1
			if rsens < 1 then
			    rsens := 1
			end if
		    elsif key = "0" then                                                %saves changed settings to file
			put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
			close : fnum
			exit
		    end if
		end loop
	    elsif key = "2" then                                                        %toggle intro
		open : fnum, "settings.ini", put
		if pintro = 1 then
		    pintro := 0
		    pintrostatus := "Off"
		    put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
		elsif pintro = 0 then
		    pintro := 1
		    pintrostatus := "On"
		    put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
		end if
		close : fnum
	    elsif key = "3" then                                                        %selects control scheme
		open : fnum, "settings.ini", put
		if mkb = 1 then                                                         %sets to keyboard
		    mkb := 2
		    mouseinput := false
		    keyinput := true
		    joystickinput := false
		    mkbstatus := "Keyboard"
		    put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
		elsif mkb = 2 then                                                      %sets to joystick
		    mkb := 3
		    mouseinput := false
		    keyinput := false
		    joystickinput := true
		    mkbstatus := "Joystick"
		    put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
		elsif mkb = 3 then                                                      %sets to mouse
		    mkb := 1
		    mouseinput := true
		    keyinput := false
		    joystickinput := false
		    mkbstatus := "Mouse"
		    put : fnum, settings (1 .. 8), rsens, settings (10 .. 17), mkb, settings (19 .. 28), pintro, ";"
		end if
		close : fnum
	    elsif key = "0" then
		exit
	    end if
	end if

	View.Update
    end loop
end options

setmap
readsettings
if pintro = 1 then
    intro
end if
reset

loop                                                                                    %main program/menu
    if quitgame then
	exit
    end if

    Music.PlayFileStop
    cls

    put "[1] Survival Mode"
    put "[2] Timed Mode"
    put "[3] Leaderboard"
    put "[4] Options"
    put ""
    put "[0] Exit"

    View.Update
    getch (key)
    if key = "1" then
	reset
	timed := false
	startgame
    elsif key = "2" then
	reset
	timed := true
	startgame
    elsif key = "3" then
	cls
	setmap
	leaderboard
    elsif key = "4" then
	options
    elsif key = "0" then
	loop
	    cls
	    put "Are you sure you want to quit? (Y/N)"
	    Input.KeyDown (chars)
	    if chars ('y') or chars ('Y') then
		quitgame := true
		exit
	    elsif chars ('n') or chars ('N') then
		exit
	    end if

	    View.Update
	end loop
    end if

    View.Update
end loop
