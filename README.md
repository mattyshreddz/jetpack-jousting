# Jetpack Jousting — Godot 4

This repository now contains the start of the Godot 4 project.

## Open in Godot
1. On GitHub, click **Code → Download ZIP** and extract the ZIP.
2. Open Godot 4.
3. In the Project Manager, choose **Import**.
4. Browse to the extracted folder and select `project.godot`.
5. Click **Import & Edit**, then press **F6** to run the current scene or **F5** to run the project.

## Current prototype
- Procedural 3D arena and simple knight/jetpack placeholders
- Portrait-oriented project settings
- Calibration button using the device gravity sensor
- Four touch controls: high/low block and high/low thrust
- Keyboard left/right fallback for desktop testing

## Motion sensor note
Godot exposes device sensors through `Input.get_gravity()`, `Input.get_gyroscope()`, and `Input.get_accelerometer()`. This prototype uses the gravity vector for tilt steering because it provides a stable tilt reference. Native iOS sensor testing requires an exported iOS app and Apple's build tools (macOS + Xcode). Desktop testing uses keyboard fallback.

This is an early blockout, not final art or finished combat balancing.