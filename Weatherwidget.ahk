
#Requires AutoHotkey v2.0
#SingleInstance Force

; Weather Widget
; Left mouse button = Drag to move
; The menu scaling = Temporary scaling option
; Saved settings on closing
; F2 = Open menu again
; Rightclick on the text = Closing outside of menu
; https://open-meteo.com/en/docs/geocoding-api to find your own latitude and longitude based on City

city := "YourOwnCity" ; Replace YourOwnCity with the name of your city.
latitude := TheLattitudeNumber ; Replace TheLatitudeNumber with the code found by the link above.
longitude := TheLongtitudeNumber ; Replace TheLongitudeNumber with the code found by the link above.
refreshMinutes := 15
saveFile := A_ScriptDir "\weather-position.ini"
resizeMode := false

;Automatic temperature unit and location detection
cachedTemperatureUnit := ""
cachedTemperatureLocation := ""

; Recover size and position
x := IniRead(saveFile, "Window", "X", 80)
y := IniRead(saveFile, "Window", "Y", 80)
w := IniRead(saveFile, "Window", "W", 250)
h := IniRead(saveFile, "Window", "H", 115)

; Widget: standard no resize-edge
widget := Gui("-Caption +ToolWindow -AlwaysOnTop")
widget.BackColor := "FF00FF"
widget.MarginX := 0
widget.MarginY := 0

widget.SetFont("s15 Bold", "Segoe UI")
placeText := widget.AddText("Center cWhite x0 y4 w" w " h30", city)

widget.SetFont("s34 Bold", "Segoe UI")
tempText := widget.AddText("Center cWhite x0 y34 w" w " h75", "--°C")

WinSetTransColor("FF00FF", widget)

; Apart Settings
controls := Gui("+ToolWindow", "Settings")
controls.SetFont("s10", "Segoe UI")
controls.AddText("w230", "Weather widget")

resizeButton := controls.AddButton("w230 h30", "Resize")
saveButton := controls.AddButton("w230 h30", "Save placed position")
hideButton := controls.AddButton("w230 h30", "Hide this menu")
exitButton := controls.AddButton("w230 h30", "Shut down widget")

resizeButton.OnEvent("Click", ToggleResize)
saveButton.OnEvent("Click", SavePosition)
hideButton.OnEvent("Click", HideSettings)
exitButton.OnEvent("Click", (*) => ExitApp())

controls.OnEvent("Close", (*) => HideSettings())

; Events
widget.OnEvent("Size", ResizeWidget)
widget.OnEvent("Close", (*) => ExitApp())

OnMessage(0x0201, StartDrag)       ; left mouse button
OnMessage(0x0204, RightClick)      ; right mouse button
OnMessage(0x0232, SavePosition)    ; Saving position of the widget

widget.Show("x" x " y" y " w" w " h" h " NoActivate")
controls.Show()

; F2 opens settings
F2::ShowSettings()

UpdateWeather()
SetTimer(UpdateWeather, refreshMinutes * 60000)
OnExit(SaveOnExit)



; -------------------------
; Scaling on/off
; -------------------------

ToggleResize(*) {
    global widget, resizeMode, resizeButton

    resizeMode := !resizeMode

    if resizeMode {
        ; Showing temporary scaling edges
        WinSetStyle("+0x40000", "ahk_id " widget.Hwnd)
        resizeButton.Text := "Finished"
    } else {
        ; Remove the edge
        WinSetStyle("-0x40000", "ahk_id " widget.Hwnd)
        resizeButton.Text := "Rescale Size"
        SavePosition()
    }

    ; Let windows use the scaling again
    DllCall("SetWindowPos",
        "ptr", widget.Hwnd,
        "ptr", 0,
        "int", 0, "int", 0, "int", 0, "int", 0,
        "uint", 0x27)
}

; -------------------------
; Widget
; -------------------------

StartDrag(wParam, lParam, msg, hwnd) {
    global widget, resizeMode

    if (hwnd != widget.Hwnd)
        return

    ; Rezisable in editing mode
    if resizeMode
        return

    PostMessage(0x00A1, 2,,, "ahk_id " hwnd)
    SetTimer(SavePosition, -300)
}

; -------------------------
; Text automatic scaling
; -------------------------

ResizeWidget(guiObj, minMax, width, height) {
    global placeText, tempText

    if (minMax = -1)
        return

    width := Max(width, 120)
    height := Max(height, 65)

    cityHeight := Max(20, Round(height * 0.28))
    cityFont := Max(8, Min(30, Round(width / 15)))
    tempFont := Max(10, Min(100, Round(Min(width / 6.5, height / 2.5))))

    placeText.Move(0, 2, width, cityHeight)
    placeText.SetFont("s" cityFont " Bold", "Segoe UI")

    tempText.Move(0, cityHeight, width, height - cityHeight)
    tempText.SetFont("s" tempFont " Bold", "Segoe UI")
}

; -------------------------
; Weather refreshing
; -------------------------

UpdateWeather() {
    global latitude, longitude, tempText

    temperatureUnit := GetTemperatureUnit(latitude, longitude)
    unitSymbol := (temperatureUnit = "fahrenheit") ? "°F" : "°C"

    url := "https://api.open-meteo.com/v1/forecast?latitude="
        . latitude . "&longitude=" . longitude
        . "&current=temperature_2m"
        . "&temperature_unit=" . temperatureUnit

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, false)
        http.SetTimeouts(3000, 3000, 3000, 5000)
        http.Send()

        if (http.Status = 200) {
            data := http.ResponseText

            if RegExMatch(data, '"temperature_2m"\s*:\s*(-?\d+(?:\.\d+)?)', &m) {
                tempText.Text := Round(m[1]) unitSymbol
            }
        }
    }
}



GetTemperatureUnit(latitude, longitude) {
    global cachedTemperatureUnit, cachedTemperatureLocation, saveFile

    locationKey := latitude . "|" . longitude

    ; Reuse the result in memory if the location has not changed
    if (cachedTemperatureLocation = locationKey
        && cachedTemperatureUnit != "")
        return cachedTemperatureUnit

    ; Load a previously detected unit, but only for the same coordinates
    savedUnit := IniRead(saveFile, "Weather", "TemperatureUnit", "")
    savedLatitude := IniRead(saveFile, "Weather", "Latitude", "")
    savedLongitude := IniRead(saveFile, "Weather", "Longitude", "")

    if (savedLatitude = latitude
        && savedLongitude = longitude
        && (savedUnit = "celsius" || savedUnit = "fahrenheit")) {

        cachedTemperatureUnit := savedUnit
        cachedTemperatureLocation := locationKey
        return cachedTemperatureUnit
    }

    ; Detect the country using OpenStreetMap Nominatim
    url := "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat="
        . latitude . "&lon=" . longitude . "&zoom=3&addressdetails=1"

    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, false)
        http.SetTimeouts(3000, 3000, 3000, 5000)

        http.SetRequestHeader("User-Agent",
            "TinyWeatherWidget/1.0 (https://github.com/Kevinn013/MinimalWeatherWidget)")

        http.Send()

        if (http.Status = 200) {
            data := http.ResponseText

           if RegExMatch(data, '"country_code"\s*:\s*"([^"]+)"', &m) {
                countryCode := StrUpper(m[1])

                ; Choose the default unit based on country
                if (countryCode = "US"
                    || countryCode = "BS"
                    || countryCode = "BZ"
                    || countryCode = "KY"
                    || countryCode = "LR"
                    || countryCode = "PW"
                    || countryCode = "FM"
                    || countryCode = "MH") {
                    detectedUnit := "fahrenheit"
                } else {
                    detectedUnit := "celsius"
                }

                ; Save the detected unit and the coordinates
                IniWrite(detectedUnit, saveFile, "Weather", "TemperatureUnit")
                IniWrite(latitude, saveFile, "Weather", "Latitude")
                IniWrite(longitude, saveFile, "Weather", "Longitude")

                cachedTemperatureUnit := detectedUnit
                cachedTemperatureLocation := locationKey

                return detectedUnit
            }
        }
    }

    ; If detection fails, use Celsius temporarily.
    ; Do not save this fallback, so detection can be retried later.
    return "celsius"
}


; -------------------------
; Save last known position
; -------------------------

SavePosition(*) {
    global widget, saveFile

    try {
        WinGetPos(&x, &y, &w, &h, widget)
        IniWrite(x, saveFile, "Window", "X")
        IniWrite(y, saveFile, "Window", "Y")
        IniWrite(w, saveFile, "Window", "W")
        IniWrite(h, saveFile, "Window", "H")
    }
}

SaveOnExit(exitReason, exitCode) {
    SavePosition()
}

; -------------------------
; Settings menu
; -------------------------

ShowSettings(*) {
    global controls
    controls.Show()
}

HideSettings(*) {
    global controls
    controls.Hide()
}

RightClick(wParam, lParam, msg, hwnd) {
    global widget

    if (hwnd = widget.Hwnd)
        ExitApp()
}
