#SingleInstance force
;written for AutoHotkey v2 beta 11
;_______________________________________________________________________________________________
;	Alt  + Up/Down/Left/Right 		=> move window (SAME row/column wrap around)
;	Ctrl + Up/Down/Left/Right 		=> move window (SAME row/column wrap around) 
;	Ctrl + Alt + Up/Down/Left/Right	=> move window (wrap around to NEXT row/column)
;	F12					=> Quit
;
;	To-Do: A proper GUI and optimizations
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
;
;
;______________________
;===== User Input =====
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
Loop {
	input := InputBox("Enter number of rows", "Window Docker")
	if (IsNumber(input.Value) and input.Value > 0 and input.Value == Floor(input.Value)) {
		break
	} else {
		MsgBox("Input must be a positive integer!")
	}
}
rows := input.Value

Loop {
	input := InputBox("Enter number of columns", "Window Docker")
	if (IsNumber(input.Value) and input.Value > 0 and input.Value == Floor(input.Value)) {
		break
	} else {
		MsgBox("Input must be a positive integer!")
	}
}
columns := input.Value
positionIndex := 0
MsgBox("Press F12/F11 while target window is active to cycle through positions.  When you are done, press F10 to terminate script.")
;
;
;_____________________
;===== Functions =====
;¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
positionOccupied(windowList, posX, posY, width_, height_, &occupyingHwnd := 0) { ;this doesn't check size of window
	occupyingHwnd := 0
	for window in windowList {
		WinGetPos(&X, &Y, &Width, &Height, "ahk_id " window)
		if (posX == X  and posY == Y and Width == width_ and Height == height_) { ;as precaution we ignore windows with zero dimensions
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
					if (X == posX + WL - 8 and Y == posY + WT and width_ + 16 == Width and height_ + 8 == Height) {
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
;main function
cyclePositions(mode) {
	global positionIndex
	
	ActiveHwnd := WinExist("A")
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
						if (!positionOccupied(windowList, posX + WL - 8, posY + WT, width + 16, height + 8)) {
							WinMove(posX + WL - 8, posY + WT, width + 16, height + 8, "ahk_id " ActiveHwnd)
							return
						}
					} else if (j * columns + i == positionIndex) {
						if (positionOccupied(windowList, posX + WL - 8, posY + WT, width + 16, height + 8, &occupyingHwnd)) {
							WinMove(X, Y, width + 16, height + 8, "ahk_id " occupyingHwnd)
						}
						WinMove(posX + WL - 8, posY + WT, width + 16, height + 8, "ahk_id " ActiveHwnd)
						return
					}
					i++
				}
				j++
			}
		}
	}
}

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
F12:: {
	MsgBox("Exiting...")
	ExitApp()
}
