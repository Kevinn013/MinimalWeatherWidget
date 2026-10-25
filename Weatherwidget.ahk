#Requires AutoHotkey v2.0
#SingleInstance Force

; Tilburg Weather Widget — AutoHotkey v2
; Middenklik + slepen = verplaatsen
; Hoeken/randen slepen = formaat aanpassen
; Positie en grootte worden bewaard in weather-position.ini
; Rechtsklik = afsluiten

city := "Tilburg"
latitude := 51.5555
longitude := 5.0913
refreshMinutes := 15
saveFile := A_ScriptDir "\weather-position.ini"

; Standaardpositie en -grootte
x := IniRead(saveFile, "Window", "X", 80)
y := IniRead(saveFile, "Window", "Y", 80)
w := IniRead(saveFile, "Window", "W", 250)
h := IniRead(saveFile, "Window", "H", 115)

; Een randloos venster dat wel schaalbaar is
widget := Gui("+Resize -Caption +ToolWindow -AlwaysOnTop")
widget.BackColor := "FF00FF"
widget.MarginX := 0
widget.MarginY := 0

widget.SetFont("s15 Bold", "Segoe UI")
placeText := widget.AddText("Center cWhite x0 y4 w" w " h30", city)
widget.SetFont("s34 Bold", "Segoe UI")
tempText := widget.AddText("Center cWhite x0 y34 w" w " h75", "--°C")

; Magenta wordt transparant
WinSetTransColor("FF00FF", widget)

; Venstergebeurtenissen
widget.OnEvent("Size", ResizeWidget)
widget.OnEvent("Close", (*) => ExitApp())
OnMessage(0x0201, StartDrag)       ; linkermuisknop om te slepen
OnMessage(0x0204, RightClick)      ; rechtsklik om af te sluiten
OnMessage(0x0232, SavePosition)    ; na verplaatsen/formaat aanpassen

widget.Show("x" x " y" y " w" w " h" h " NoActivate")

StartDrag(wParam, lParam, msg, hwnd) {
    global widget, saveFile
    if (hwnd != widget.Hwnd)
        return
    PostMessage(0x00A1, 2,,, "ahk_id " hwnd)
    SetTimer(SavePosition, -300)
}


UpdateWeather()
SetTimer(UpdateWeather, refreshMinutes * 60000)

ResizeWidget(guiObj, minMax, width, height) {
    global placeText, tempText

    if (width < 120)
        width := 120
    if (height < 65)
        height := 65

    cityHeight := Max(20, Round(height * 0.28))
    cityFont := Max(8, Min(30, Round(width / 15)))
    tempFont := Max(10, Min(100, Round(Min(width / 6.5, height / 2.5))))

    placeText.Move(0, 2, width, cityHeight)
    placeText.SetFont("s" cityFont " Bold", "Segoe UI")

    tempText.Move(0, cityHeight, width, height - cityHeight)
    tempText.SetFont("s" tempFont " Bold", "Segoe UI")
}

UpdateWeather() {
    global latitude, longitude, tempText

    url := "https://api.open-meteo.com/v1/forecast?latitude="
        . latitude . "&longitude=" . longitude
        . "&current=temperature_2m"

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, false)
        http.SetTimeouts(3000, 3000, 3000, 5000)
        http.Send()

        if (http.Status = 200) {
            data := http.ResponseText
            if RegExMatch(data, '"temperature_2m"\s*:\s*(-?\d+(?:\.\d+)?)', &m) {
                tempText.Text := Round(m[1]) "°C"
            }
        }
    }
}

StartMove(wParam, lParam, msg, hwnd) {
    global widget, placeText, tempText

    ; Middelklik op de widget of tekst verplaatst het hele venster.
    if (hwnd != widget.Hwnd && hwnd != placeText.Hwnd && hwnd != tempText.Hwnd)
        return

    PostMessage(0x00A1, 2, 0, , "ahk_id " widget.Hwnd)
}

SavePosition(wParam := 0, lParam := 0, msg := 0, hwnd := 0) {
    global widget, saveFile

    try {
        WinGetPos(&x, &y, &w, &h, widget)
        IniWrite(x, saveFile, "Window", "X")
        IniWrite(y, saveFile, "Window", "Y")
        IniWrite(w, saveFile, "Window", "W")
        IniWrite(h, saveFile, "Window", "H")
    }
}

RightClick(wParam, lParam, msg, hwnd) {
    global widget, placeText, tempText
    if (hwnd = widget.Hwnd || hwnd = placeText.Hwnd || hwnd = tempText.Hwnd)
        ExitApp()
}

SaveOnExit(exitReason, exitCode) {
    SavePosition()
}
OnExit(SaveOnExit)
