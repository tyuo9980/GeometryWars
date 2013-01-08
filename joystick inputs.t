import joystick
View.Set ("graphics:max;max,nobuttonbar,offscreenonly")

type joypad : % create a joypad type
    record
	button : array 1 .. 32 of boolean %create 32 instances of buttons
	pos : joystick.PosRecord /*used to find all joypad intake with
	 the exception of buttons*/
	caps : joystick.CapsRecord %used to find the max on joypad analog
    end record

var joy : array 1 .. 2 of joypad %create an array of joypad
/*set default joypad varibles*/
for i : 1 .. upper (joy)
    for ii : 1 .. upper (joy (i).button)
	joy (i).button (ii) := false
    end for
    joy (i).pos.POV := 66535
    joystick.Capabilities (i - 1, joy (i).caps)
end for

% create a procedure to get input from joypad
proc setJoyStick (joystickNO : int)

    joystick.GetInfo (joystickNO, joy (joystickNO + 1).button)
    joystick.Read (joystickNO, joy (joystickNO + 1).pos)

end setJoyStick

%show inital information
proc showID

    Text.Locate (1, 1)
    put "Joystick 1"
    put "buttons"
    Text.Locate (1, maxcol div 2)
    put "Joystick 2"
    Text.Locate (2, maxcol div 2)
    put "buttons"

end showID

%a function to detirmine which side to put to
fcn getCol (joystickNO : int) : int
    if joystickNO = joystick1 then
	result 1
    elsif joystickNO = joystick2 then
	result maxcol div 2
    end if
end getCol

%shows the user which buttons are down
proc showBut (joystickNO : int)

    for i : 3 .. 3 + 31
	Text.Locate (i, getCol (joystickNO))
	put i - (3 - 1), " - ", joy (joystickNO + 1).button (i - 3 + 1)
    end for

end showBut

%show the user what direction D-pad/POV is pressed
proc showPOV (joystickNO : int)

    Text.Locate (3 + 32, getCol (joystickNO))
    put "D-PAD (AKA POV) - " ..
    if joy (joystickNO + 1).pos.POV = 0 then
	put "up"
    elsif joy (joystickNO + 1).pos.POV = 4500 then
	put "up right"
    elsif joy (joystickNO + 1).pos.POV = 9000 then
	put "right"
    elsif joy (joystickNO + 1).pos.POV = 13500 then
	put "down right"
    elsif joy (joystickNO + 1).pos.POV = 18000 then
	put "down"
    elsif joy (joystickNO + 1).pos.POV = 22500 then
	put "down left"
    elsif joy (joystickNO + 1).pos.POV = 27000 then
	put "left"
    elsif joy (joystickNO + 1).pos.POV = 31500 then
	put "up left"
    else
	put "none"
    end if

end showPOV

%show the user where the analog is
proc showXY (joystickNO : int)

    Text.Locate (3 + 33, getCol (joystickNO))
    put "position on joypad"
    Text.Locate (3 + 34, getCol (joystickNO))
    put "analog 1 - x - ", joy (joystickNO + 1).pos.xpos
    Text.Locate (3 + 35, getCol (joystickNO))
    put "analog 1 - y - ", joy (joystickNO + 1).pos.ypos
    Text.Locate (3 + 36, getCol (joystickNO))
    put "analog 2 - x - ", joy (joystickNO + 1).pos.zpos
    Text.Locate (3 + 37, getCol (joystickNO))
    put "analog 2 - y - ", joy (joystickNO + 1).pos.rpos
    Text.Locate (3 + 38, getCol (joystickNO))
    put "position on screen"
    Text.Locate (3 + 39, getCol (joystickNO))
    if joy (joystickNO + 1).pos.xpos not= 0 then
	put "analog 1 - x - ", round (joy (joystickNO + 1).pos.xpos /
	    joy (joystickNO + 1).caps.maxX * maxx)
    else
	put "analog 1 - x - 0"
    end if
    Text.Locate (3 + 40, getCol (joystickNO))
    if joy (joystickNO + 1).pos.ypos not= 0 then
	put "analog 1 - y - ", round (joy (joystickNO + 1).pos.ypos /
	    joy (joystickNO + 1).caps.maxY * maxy)
    else
	put "analog 1 - y - 0"
    end if
    Text.Locate (3 + 41, getCol (joystickNO))
    if joy (joystickNO + 1).pos.zpos not= 0 then
	put "analog 2 - x - ", round (joy (joystickNO + 1).pos.zpos /
	    joy (joystickNO + 1).caps.maxZ * maxx)
    else
	put "analog 2 - x - 0"
    end if
    Text.Locate (3 + 42, getCol (joystickNO))
    if joy (joystickNO + 1).pos.rpos not= 0 then
	put "analog 2 - y - ", round (joy (joystickNO + 1).pos.rpos /
	    joy (joystickNO + 1).caps.maxR * maxy)
    else
	put "analog 2 - y - 0"
    end if

end showXY

%main loop
loop

    cls
    showID
    for i : joystick1 .. joystick2
	setJoyStick (i)
	showBut (i)
	showPOV (i)
	showXY (i)
    end for
    View.Update

end loop
