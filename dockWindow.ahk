#SingleInstance force
;built for AutoHotkey v2 beta 11
;F10 will resize and move active window to next available slot (from left to right, top to bottom)
;F11 will move it to previous slot (even if another window is there)
;F12 will move it to next slot (even if another window is there)
;F9 to exit this script

;note:  processes such as hh.exe and explorer.exe sit at (0,0)

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


positionOccupied(windowsList, posX, posY) {
	for window in windowsList {
		WinGetPos(&X, &Y, &Width, &Height, "ahk_id " window)
		if (posX == X  and posY == Y and Width != 0 and Height != 0) { ;as precaution we ignore windows with zero dimensions
			if (WinExist("A") == window) { ;not optimal but this will prevent "moving" current window to another position if it's already sitting in a valid slot
				return false	;returning false here essentially moves this window back to its current location instead of having it moved else where next iteration
			}
			return true
		}
	}
	return false
}


cyclePositions(reverse := false, toNextOpen := false) {
	global positionIndex
	if (reverse) {
		positionIndex--
		if (positionIndex < 0) {
			positionIndex += rows * columns
		}
	} else {
		positionIndex++
	}
	positionIndex := Mod(positionIndex, rows * columns)
	
	if (toNextOpen) {
		;processName := WinGetProcessName("A") ;A more narrow search where we only build our list from processes of same .exe
		;windowList := WinGetList("ahk_exe " processName)
		windowList := WinGetList()
	}
	
	ActiveHwnd := WinExist("A")
	WinGetPos(&X, &Y, , , "ahk_id " ActiveHwnd)

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
					if (toNextOpen) {
						if (!positionOccupied(windowList, posX + WL - 8, posY + WT)) {
							WinMove(posX + WL - 8, posY + WT, width + 16, height + 8, "ahk_id " ActiveHwnd)
							return
						}
					} else if (j * columns + i == positionIndex) {
						WinMove(posX + WL - 8, posY + WT, width + 16, height + 8, "ahk_id " ActiveHwnd)
						return
					}
					i++
				}
				j++
			}
		}
	}
	lastWindowExe := WinGetProcessPath("A")
}


F12:: cyclePositions()
F11:: cyclePositions(reverse := true)
F10:: cyclePositions(reverse := false, toNextOpen := true)
F9:: {
	MsgBox("Exiting...")
	ExitApp()
}

;For debugging to list all windows at a certain position
; F8:: {
	; windowList := WinGetList()
	; for window in windowList {
		; WinGetPos(&X, &Y, &Width, &Height, "ahk_id " window)
		; if (X <= 0 and Y <= 0) {
			; ProcessPath := WinGetProcessPath("ahk_id " window)
			; MsgBox("X=" X ", Y=" Y ", " ProcessPath)
		; }
	; }
; }
