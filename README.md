# Jetpack Jousting

A first playable mobile-web prototype for the portrait iPhone game.

## Run locally
Open `index.html` in a browser. Motion controls require HTTPS (a secure context) and a tap to grant iPhone motion permission.

## Publish for iPhone testing
In the repository, open **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, select **main** and **/(root)**, then Save. GitHub will show the published URL when deployment is ready.

**Private repository note:** GitHub Pages support for private repositories depends on the account plan. If Pages is unavailable, keep the repo private and use another HTTPS host; don't change visibility unless you want the source public.

## iPhone controls
Open the HTTPS site in Safari and tap **CALIBRATE & START**. Grant motion permission, then hold the phone in your normal playing position while calibration records neutral orientation.

- Upper-left: high block
- Lower-left: low block
- Upper-right: high thrust
- Lower-right: low thrust

This is an early playable prototype, not the finished 3D game. The arena and knights are currently rendered in 2D; the next milestone is the proper 3D scene and refined gyroscope steering/combat.
