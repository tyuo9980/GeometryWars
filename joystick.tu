unit
module joystick
    export GetInfo,

    % Experimentals
	Read, Capabilities, GetDeadBand, SetDeadBand, PosRecord, CapsRecord,

	btn1, btn2, btn3, btn4, btn5, btn6, btn7, btn8,
	btn9, btn10, btn11, btn12, btn13, btn14, btn15, btn16,
	btn17, btn18, btn19, btn20, btn21, btn22, btn23, btn24,
	btn25, btn26, btn27, btn28, btn29, btn30, btn31, btn32,

	povBackward, povCentered, povForward, povLeft, povRight,

	capsHasZ, capsHasR, capsHasU, capsHasV, capsHasPOV,
	capsPOVdir, capsPOVcont

    % ------------------
    % Exported constants
    % ------------------

    const povBackward : nat := 18000
    const povCentered : nat := 99999
    const povForward : nat := 0
    const povLeft : nat := 27000
    const povRight : nat := 9000

    const btn1 : nat := 16#00000001
    const btn2 : nat := 16#00000002
    const btn3 : nat := 16#00000004
    const btn4 : nat := 16#00000008
    const btn5 : nat := 16#00000010
    const btn6 : nat := 16#00000020
    const btn7 : nat := 16#00000040
    const btn8 : nat := 16#00000080
    const btn9 : nat := 16#00000100
    const btn10 : nat := 16#00000200
    const btn11 : nat := 16#00000400
    const btn12 : nat := 16#00000800
    const btn13 : nat := 16#00001000
    const btn14 : nat := 16#00002000
    const btn15 : nat := 16#00004000
    const btn16 : nat := 16#00008000
    const btn17 : nat := 16#00010000
    const btn18 : nat := 16#00020000
    const btn19 : nat := 16#00040000
    const btn20 : nat := 16#00080000
    const btn21 : nat := 16#00100000
    const btn22 : nat := 16#00200000
    const btn23 : nat := 16#00400000
    const btn24 : nat := 16#00800000
    const btn25 : nat := 16#01000000
    const btn26 : nat := 16#02000000
    const btn27 : nat := 16#04000000
    const btn28 : nat := 16#08000000
    const btn29 : nat := 16#10000000
    const btn30 : nat := 16#20000000
    const btn31 : nat := 16#40000000
    const btn32 : nat := 16#80000000

    const capsHasZ : nat := 16#0001
    const capsHasR : nat := 16#0002
    const capsHasU : nat := 16#0004
    const capsHasV : nat := 16#0008
    const capsHasPOV : nat := 16#0010
    const capsPOVdir : nat := 16#0020
    const capsPOVcont : nat := 16#0040


    % -------------
    % Exported type
    % -------------

    type PosRecord :
	record
	    xpos : nat                  % x-axis position
	    ypos : nat                  % y-axis position
	    zpos : nat                  % z-axis position
	    rpos : nat                  % rudder (fourth axis) position
	    upos : nat                  % fifth axis position
	    vpos : nat                  % sixth axis position
	    buttons : nat4              % button states (32 buttons)
	    buttonNum : nat             % current button depressed
	    POV : nat                   % POV hat position
	end record


    type CapsRecord :
	record
	    caps : nat                  % capabilities
	    maxNumAxes : nat            % maximum number of axes
	    numAxes : nat               % axis in use
	    maxNumButtons : nat         % max number of buttons
	    numButtons : nat            % number of buttons in use
	    minX : nat                  % min axis position
	    maxX : nat                  % max axis position
	    minY : nat
	    maxY : nat
	    minZ : nat
	    maxZ : nat
	    minR : nat
	    maxR : nat
	    minU : nat
	    maxU : nat
	    minV : nat
	    maxV : nat
	end record


    % -----------------
    % Exported routines
    % -----------------

    external "joy_read" proc Read (joyNum : int, var info : PosRecord)
    external "joy_caps" proc Capabilities (joyNum : int, var info : CapsRecord)

    % Simplified API

    var fx1, fy1, fx2, fy2 : real

    begin
	fx1 := 0
	fx2 := 0
	fy1 := 0
	fy2 := 0

	var caps : CapsRecord

	Capabilities (joystick1, caps)

	if Error.Last = 0 then
	    const rx := caps.maxX - caps.minX
	    const ry := caps.maxY - caps.minY

	    if rx > 0 and ry > 0 then
		fx1 := (joyMax * 2.0) / rx
		fy1 := (joyMax * 2.0) / ry
	    end if
	end if

	Capabilities (joystick2, caps)

	if Error.Last = 0 then
	    const rx := caps.maxX - caps.minX
	    const ry := caps.maxY - caps.minY

	    if rx > 0 and ry > 0 then
		fx2 := (joyMax * 2.0) / rx
		fy2 := (joyMax * 2.0) / ry
	    end if
	end if
    end

    var deadBand : int := 600   % Default dead band value

    procedure GetInfo (jNum : int, var btnpressed : array 1 .. * of boolean)
	%Edited from origanal turing module
	%removed x and y and changed buttons 1 and 2 with an array

	const joyHalfMax := 5000

	var pr : PosRecord

	Read (jNum, pr)

	if Error.Last = 0 then

	    var x, y : int

	    if jNum = joystick1 then
		x := round (pr.xpos * fx1) - joyMax
		y := -1 * (round (pr.ypos * fy1) - joyMax)
	    else
		x := round (pr.xpos * fx2) - joyMax
		y := -1 * (round (pr.ypos * fy2) - joyMax)
	    end if

	    for i : 1 .. upper (btnpressed)
		exit when i > 32
		if i = 1 then
		    btnpressed (i) := (pr.buttons and btn1) not= 0
		elsif i = 2 then
		    btnpressed (i) := (pr.buttons and btn2) not= 0
		elsif i = 3 then
		    btnpressed (i) := (pr.buttons and btn3) not= 0
		elsif i = 4 then
		    btnpressed (i) := (pr.buttons and btn4) not= 0
		elsif i = 5 then
		    btnpressed (i) := (pr.buttons and btn5) not= 0
		elsif i = 6 then
		    btnpressed (i) := (pr.buttons and btn6) not= 0
		elsif i = 7 then
		    btnpressed (i) := (pr.buttons and btn7) not= 0
		elsif i = 8 then
		    btnpressed (i) := (pr.buttons and btn8) not= 0
		elsif i = 9 then
		    btnpressed (i) := (pr.buttons and btn9) not= 0
		elsif i = 10 then
		    btnpressed (i) := (pr.buttons and btn10) not= 0
		elsif i = 11 then
		    btnpressed (i) := (pr.buttons and btn11) not= 0
		elsif i = 12 then
		    btnpressed (i) := (pr.buttons and btn12) not= 0
		elsif i = 13 then
		    btnpressed (i) := (pr.buttons and btn13) not= 0
		elsif i = 14 then
		    btnpressed (i) := (pr.buttons and btn14) not= 0
		elsif i = 15 then
		    btnpressed (i) := (pr.buttons and btn15) not= 0
		elsif i = 16 then
		    btnpressed (i) := (pr.buttons and btn16) not= 0
		elsif i = 17 then
		    btnpressed (i) := (pr.buttons and btn17) not= 0
		elsif i = 18 then
		    btnpressed (i) := (pr.buttons and btn18) not= 0
		elsif i = 19 then
		    btnpressed (i) := (pr.buttons and btn19) not= 0
		elsif i = 20 then
		    btnpressed (i) := (pr.buttons and btn20) not= 0
		elsif i = 21 then
		    btnpressed (i) := (pr.buttons and btn21) not= 0
		elsif i = 22 then
		    btnpressed (i) := (pr.buttons and btn22) not= 0
		elsif i = 23 then
		    btnpressed (i) := (pr.buttons and btn23) not= 0
		elsif i = 24 then
		    btnpressed (i) := (pr.buttons and btn24) not= 0
		elsif i = 25 then
		    btnpressed (i) := (pr.buttons and btn25) not= 0
		elsif i = 26 then
		    btnpressed (i) := (pr.buttons and btn26) not= 0
		elsif i = 27 then
		    btnpressed (i) := (pr.buttons and btn27) not= 0
		elsif i = 28 then
		    btnpressed (i) := (pr.buttons and btn28) not= 0
		elsif i = 29 then
		    btnpressed (i) := (pr.buttons and btn29) not= 0
		elsif i = 30 then
		    btnpressed (i) := (pr.buttons and btn30) not= 0
		elsif i = 31 then
		    btnpressed (i) := (pr.buttons and btn31) not= 0
		elsif i = 32 then
		    btnpressed (i) := (pr.buttons and btn32) not= 0
		end if
	    end for
	    %Edited from origanal turing module
	    %changed code to allow for 32 buttons still hard coded

	else
	    for i : 1 .. upper (btnpressed)
		btnpressed (i) := false
	    end for
	end if
    end GetInfo


    function GetDeadBand : int
	result deadBand
    end GetDeadBand

    procedure SetDeadBand (val : int)
	deadBand := val
    end SetDeadBand
end joystick
