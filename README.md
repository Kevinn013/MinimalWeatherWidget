# MinimalWeatherWidget

A lightweight, transparent and resizable weather widget for Windows, built with AutoHotkey v2 and the free Open-Meteo API.

**Features:**

- Displays the current temperature and a customizable city name.
- Transparent background with adjustable text size.
- Drag-and-drop positioning.
- Resizable widget with a temporary resize mode.
- Remembers window position and size between sessions.
- Saves the country code and used temperature unit.
- Refreshes weather data every 15 minutes.

No API key required.

**Requirements:**
- Windows
- AutoHotkey v2
- Internet connection

**Setup:**
- Download or clone this repository.
- Open Weatherwidget.ahk in a text editor.
- Set your city name, latitude and longitude as provided in the description.
- Run or Compile the script with AutoHotkey v2. If you compile it, you will get an .exe file. Optional step.
- Find your coordinates using the Open-Meteo Geocoding API.
Controls

**Hotkeys and settings:**
Left-click and drag: Move the widget.
F2: Open the settings menu.
Resize: Temporarily enable resizing.
Save placed position: Save the current position and size.
Hide this menu: Hide the settings menu.
Shut down widget: Close the widget.

Right-click the widget: Close the widget.
Press F2 to open the settings menu.

**Data**
Data and Settings
The widget retrieves weather data from Open-Meteo and uses OpenStreetMap's Nominatim service to determine the default temperature unit based on the configured coordinates.
Window position, size, and detected temperature settings are stored locally in weather-position.ini, next to the script.

**Credits and Links:**
- Weather data; (https://open-meteo.com/)
- The location data is from; (https://nominatim.openstreetmap.org/)
- Autohotkeyv2; (https://www.autohotkey.com/)

Created as a small personal project and shared for others to enjoy. As addition to Wallpaperengine which doesn't support weather assets.
