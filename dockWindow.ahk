#SingleInstance force
;made to work with AutoHotkey v2 beta 11

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

cyclePositions(reverse := false) {
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
	
	ActiveHwnd := WinExist("A")
	WinGetPos(&X, &Y, &Width, &Height, "ahk_id " ActiveHwnd)

	Loop(MonitorGetCount()) {
		MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
		width := (WR - WL) / columns
		height := (WB - WT) / rows
		if (WL <= X and X <= WR and WT <= Y and Y <= WB){
			
			j := 0
			Loop(rows){
				i := 0
				Loop (columns) {
					if (j * columns + i == positionIndex) {
						
						posX := i * width
						posY := j * height
						WinMove(posX + WL, posY + WT, width, height, "ahk_id " ActiveHwnd)
						return
					}
					i++
				}
				j++
			}
		
		}
	}
}


F12:: cyclePositions()
F11:: cyclePositions(reverse := true)

F10:: {
	MsgBox("Exiting...")
	ExitApp()
}
