# Jetpack Jousting — Godot 4

A portrait first-person jetpack jousting prototype built in Godot 4.

## Open on Windows
1. On GitHub, click **Code → Download ZIP** and extract it.
2. Open Godot 4.
3. In the Project Manager, choose **Import**.
4. Select the extracted folder's `project.godot`.
5. Click **Import & Edit**, wait for the assets to import, then press **F5**.

## Art pass in this prototype
- Clearer daylight lighting with glow disabled
- Rounded capsule-based rival armor and spectator silhouettes
- Custom SVG royal banner and shield artwork in `assets/`
- Reduced visual clutter and stronger blue, crimson, steel, and gold palette

These are still prototype-quality assets and geometry, not final production character models or animation.

## Controls
- Phone tilt: steering after calibration (hold the phone in your natural playing position and tap **Calibrate Phone**).
- Four invisible touch zones in the lower half of the screen:
  - upper-left: high block
  - lower-left: low block
  - upper-right: high thrust
  - lower-right: low thrust
- Desktop fallback: A/D or left/right arrows.

## Test on iPhone with Xogot
Xogot is a native Godot editor/runtime for iPhone and iPad, and it can work with standard Godot projects.

1. Download the repository ZIP on your iPhone from GitHub.
2. In the Files app, tap the ZIP once to extract it.
3. Open Xogot and use its project/file browser to open the extracted folder's `project.godot`.
4. Let the project import, then run the project from Xogot.
5. Grant Local Network or sensor permissions if iOS asks. Hold the phone steady in your normal playing position and tap **Calibrate Phone** before testing tilt.

If you want to run the project from Godot on your Windows PC and send it wirelessly to Xogot, the optional **Xogot Connect** add-on supports remote deploy/debug. It requires a paid Xogot subscription or license on the iPhone; it is not required for opening and running a project directly in Xogot.

## Native iOS app export
A standalone iOS app export still requires macOS and Xcode. Xogot is the easiest route for an early on-device prototype test.

## Status
Early gameplay and art prototype. Sensor steering, combat timing, touch feel, performance, and visual quality still need real-device testing and iteration.
