#SingleInstance force
;built for AutoHotkey v2 beta 11
;________________________________________________________________________________________________
;	Alt  + Up/Down/Left/Right 			=> move window (SAME row/column wrap around)
;	Ctrl + Up/Down/Left/Right 			=> move window (SAME row/column wrap around) 
;	Ctrl + Alt + Up/Down/Left/Right	=> move window (wrap around to NEXT row/column)  
;	F12 to quit
;	F11 to toggle Title Bar and Borders
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;
;
;______________________
;===== User Input =====
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
MyGui := Gui()
MyGui.Add("Text", "section", "Number of Rows:")  
MyGui.Add("Text", "y+16", "Number of Columns:")
MyGui.Add("Text", "y+16", "Apply Settings..............")
MyGui.Add("Text", "y+16", "Arrow Key Move..........")
MyGui.Add("Text", "y+16", "Stop Quick Mode........")
RowsEdit := MyGui.Add("Edit", "Number ys w80", "2")  
ColumnsEdit := MyGui.Add("Edit", "Number w80", "2")
MyBtn1 := MyGui.Add("Button", "Default w80", "Apply")
MyBtn1.OnEvent("Click", onButtonClick_Apply)  
MyBtn2 := MyGui.Add("Button", "Default w80", "Quick Mode")
MyBtn2.OnEvent("Click", onButtonClick_QuickMode) 
MyBtn3 := MyGui.Add("Button", "Default w80", "Stop")
MyBtn3.OnEvent("Click", onButtonClick_Stop) 
MyGui.OnEvent("Close", MyGui_Close)
MyGui.Show

MsgBox(	"Alt/Ctrl + Arrow Keys => move window (normal mode)`n" .
		"Alt + Ctrl + Arrow Keys => move window (alternate mode)`n" .
		"F11 to toggle Title Bar and Borders`n" .
		"F12 to quit`n" 
		"`n" . 
		"Hint: Quick Mode allows the use of arrow keys without modifiers.`n" .
		"         Spacebar will toggle Title Bar and Borders.", 
		"Helpful Hints", "T10"
		)

positionIndex := 0
rows := 0
columns := 0

MyGui_Close(*) {  
    ExitApp()
}

onButtonClick_Apply(*) {
	r := RowsEdit.Value
	c := ColumnsEdit.Value
	if (IsNumber(r) and r > 0 and r == Floor(r) and IsNumber(c) and c > 0 and c == Floor(c)) {
		global rows := r
		global columns := c
		return
	} else {
		MsgBox("Inputs must be positive integers!")
	}
}

showToolTip() {
	ToolTip("Click Stop or hit the Escape key to stop.", , , 1)
	sleep 1200
	ToolTip( , , , 1)
	sleep 400
}

onButtonClick_QuickMode(*) {
	onButtonClick_Apply()
	Hotkey "up", (*)=> cyclePositions("Up")
	Hotkey "down", (*)=> cyclePositions("Down")
	Hotkey "left", (*)=> cyclePositions("Left")
	Hotkey "right", (*)=> cyclePositions("Right")
	Hotkey "space", (*)=> toggleTitleBarBorders() 
	Hotkey "escape", (*)=> onButtonClick_Stop()
	Hotkey "up", "On"
	Hotkey "down", "On"
	Hotkey "left", "On"
	Hotkey "right", "On"
	Hotkey "space", "On"
	Hotkey "escape", "On"

	SetTimer showToolTip, 50
}

onButtonClick_Stop(*) {
	Hotkey "up", "Off"
	Hotkey "down", "Off"
	Hotkey "left", "Off"
	Hotkey "right", "Off"
	Hotkey "space", "Off"
	Hotkey "escape", "off"
	
	SetTimer showToolTip, 0
	ToolTip( , , , 1)
}
;
;
;_____________________
;===== Functions =====
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
positionOccupied(windowList, posX, posY, width_, height_, &occupyingHwnd := 0) { ;this doesn't check size of window
	occupyingHwnd := 0
	for window in windowList {
		WinGetPos(&X, &Y, &Width, &Height, "ahk_id " window)
		if ((posX == X or posX == X + 8 or posX == X - 8)  and posY == Y and (Width == width_ or Width == width_ + 16 or Width == width_ - 16) and (Height == height_ or Height == height_ + 8 or Height == height_ - 8)) { ;as precaution we ignore windows with zero dimensions
			if (WinExist("A") == window) { ;not optimal but this will prevent "moving" current window to another position if it's already sitting in a valid slot
				return false	;returning false here essentially moves this window back to its current location instead of having it moved else where next iteration
			}
			occupyingHwnd := window
			return true
		}
	}
	return false
}
;
;
;return positionIndex using the window's X, Y, dimensions and known user specified row and column counts
getPositionIndexFromCoordinates(X, Y, Width, Height, rows, columns) {
	Loop(MonitorGetCount()) {
		MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
		width_ := Floor((WR - WL) / columns)
		height_ := Floor((WB - WT) / rows)
		if (WL - 8 <= X and X <= WR + 8 and WT - 8 <= Y and Y <= WB + 8){		
			j := 0
			Loop(rows){
				i := 0
				Loop (columns) {
					posX := i * width_
					posY := j * height_
					if ((X == posX + WL - 8 or X == posX + WL) and Y == posY + WT and (width_ + 16 == Width or width_ == Width) and (height_ + 8 == Height or height_ == Height)) {
						return j * columns + i
					}
					i++
				}
				j++
			}
		}
	}
	return -1 ;failure
}
;
;
toggleTitleBarBorders() {
	ActiveHwnd := WinExist("A")
	titleBarBorders := (WinGetStyle("ahk_id " ActiveHwnd) & 0xC40000) ? 1 : 0
	WinSetStyle("^0xC40000", "ahk_id " ActiveHwnd)
	WinGetPos(&X, &Y, &width, &height, "ahk_id " ActiveHwnd)
	if (titleBarBorders) {
		WinMove(X + 8, Y, width - 16, height - 8, "ahk_id " ActiveHwnd)
	} else {	
		WinMove(X - 8, Y, width + 16, height + 8, "ahk_id " ActiveHwnd)
	}
}
;
;
;main function
cyclePositions(mode) {
	global positionIndex
	global rows
	global columns
	if (rows == 0 or columns == 0) {
		MsgBox("Positive integer inputs required!")
		return
	}
	
	ActiveHwnd := WinExist("A")
	BorderAndTitleBar := (WinGetStyle("A") & 0xC40000) ? 1 : 0
	
	WinGetPos(&X, &Y, &Width, &Height, "ahk_id " ActiveHwnd)
	
	if (mode != "FirstOpenSlot") { ;infinite recursion is bad!
		currentPosition := getPositionIndexFromCoordinates(X, Y, Width, Height, rows, columns)
		if (currentPosition == -1) { 
			cyclePositions("FirstOpenSlot") ;if active window is not sitting in a valid slot, move it to the first available slot
			return
		} else {
			positionIndex := currentPosition	;otherwise set positionIndex to active window's index
		}
	}
	
	;compute next positionIndex
	dim := rows * columns
	if (mode == "Left") {
		lowerBound := positionIndex // columns * columns
		upperBound := lowerBound + columns - 1
		positionIndex--
		if (positionIndex > upperbound) {
			positionIndex := lowerBound
		} else if (positionIndex < lowerBound) {
			positionIndex := upperBound
		}
		;positionIndex--	;this will not loop around on the same row
	} else if (mode == "Right") {
		lowerBound := positionIndex // columns * columns
		upperBound := lowerBound + columns - 1
		positionIndex++
		if (positionIndex > upperbound) {
			positionIndex := lowerBound
		} else if (positionIndex < lowerBound) {
			positionIndex := upperBound
		}
		;positionIndex++	;this is will not loop around on the same row, instead it will move to next row at the end of it
	} else if (mode == "Down") {
		positionIndex += columns
	} else if (mode == "Up") {
		positionIndex -= columns
	} else if (mode == "SequentialLeft") {
		positionIndex--
	} else if (mode == "SequentialRight") {
		positionIndex++
	} else if (mode == "SequentialUp") {
		currentRow := positionIndex // columns
		if (positionIndex == 0) {
			positionIndex := dim - 1
		} else if (currentRow == 0) {
			positionIndex := positionIndex - columns - 1
		} else if (currentRow == rows - 1) {
			positionIndex -= columns
		}
	} else if (mode == "SequentialDown") {
		currentRow := positionIndex // columns
		if (positionIndex == dim - 1) {
			positionIndex := 0
		} else if (currentRow == rows - 1) {
			positionIndex := positionIndex + columns + 1
		} else if (currentRow == 0) {
			positionIndex += columns
		}
	}
	
	positionIndex := Mod(positionIndex + dim, dim)
	windowList := WinGetList()

	;find next position's coordinate and take appropriate actions
	Loop(MonitorGetCount()) {
		MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
		width := Floor((WR - WL) / columns)
		height := Floor((WB - WT) / rows)
		if (WL - 8 <= X and X <= WR + 8 and WT - 8 <= Y and Y <= WB + 8){		
			j := 0
			Loop(rows){
				i := 0
				Loop (columns) {
					posX := i * width
					posY := j * height
					if (mode == "FirstOpenSlot") {
						if (!positionOccupied(windowList, posX + WL - 8*BorderAndTitleBar, posY + WT, width + 16*BorderAndTitleBar, height + 8*BorderAndTitleBar)) {
							WinMove(posX + WL - 8*BorderAndTitleBar, posY + WT, width + 16*BorderAndTitleBar, height + 8*BorderAndTitleBar, "ahk_id " ActiveHwnd)
							return
						}
					} else if (j * columns + i == positionIndex) {
						if (positionOccupied(windowList, posX + WL - 8*BorderAndTitleBar, posY + WT, width + 16*BorderAndTitleBar, height + 8*BorderAndTitleBar, &occupyingHwnd)) {
							occupyingHwndBandTStyle := (WinGetStyle("ahk_id " occupyingHwnd) & 0xC40000) ? 1 : 0
							if (BorderAndTitleBar and !occupyingHwndBandTStyle) {
								WinMove(X + 8, Y, width + 16*occupyingHwndBandTStyle, height + 8*occupyingHwndBandTStyle, "ahk_id " occupyingHwnd)
							} else if (BorderAndTitleBar and occupyingHwndBandTStyle) {
								WinMove(X, Y, width + 16*occupyingHwndBandTStyle, height + 8*occupyingHwndBandTStyle, "ahk_id " occupyingHwnd)
							} else if (!BorderAndTitleBar and !occupyingHwndBandTStyle) {
								WinMove(X, Y, width + 16*occupyingHwndBandTStyle, height + 8*occupyingHwndBandTStyle, "ahk_id " occupyingHwnd)
							} else if (!BorderAndTitleBar and occupyingHwndBandTStyle) {
								WinMove(X - 8, Y, width + 16*occupyingHwndBandTStyle, height + 8*occupyingHwndBandTStyle, "ahk_id " occupyingHwnd)
							}
						}
						WinMove(posX + WL - 8*BorderAndTitleBar, posY + WT, width + 16*BorderAndTitleBar, height + 8*BorderAndTitleBar, "ahk_id " ActiveHwnd)
						return
					}
					i++
				}
				j++
			}
		}
	}
}
;
;
;___________________
;===== Hotkeys =====
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
^Up:: 		cyclePositions("Up")
^Down:: 	cyclePositions("Down")
^Left:: 	cyclePositions("Left")
^Right:: 	cyclePositions("Right")
!Up:: 		cyclePositions("Up")	;holding down alt gives the same behavior as holding down ctrl
!Down:: 	cyclePositions("Down")	;holding down alt gives the same behavior as holding down ctrl
!Left:: 	cyclePositions("Left")	;holding down alt gives the same behavior as holding down ctrl
!Right:: 	cyclePositions("Right")	;holding down alt gives the same behavior as holding down ctrl
^!Left:: 	cyclePositions("SequentialLeft")
^!Right:: 	cyclePositions("SequentialRight")
^!Up:: 		cyclePositions("SequentialUp")
^!Down:: 	cyclePositions("SequentialDown")

F11:: toggleTitleBarBorders()

F12:: {
	MsgBox("Exiting...")
	ExitApp()
}
