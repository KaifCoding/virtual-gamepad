# Virtual Gamepad

Turn your phone into a real, game-compatible wireless controller for your PC.

- **Android app** (Flutter) — on-screen sticks, D-pad, face buttons, shoulder
  buttons, and analog triggers. Connects over WiFi.
- **Windows host app** (C#) — creates a genuine virtual **Xbox 360 controller**
  via [ViGEmBus](https://github.com/ViGEm/ViGEmBus), so it works in literally
  any game or app that supports a normal Xbox controller — no per-game
  integration needed.
- 100% free, MIT-licensed, no ads, no accounts, no telemetry.

## How the pieces fit together

```
[Phone: Flutter app]  --UDP, WiFi-->  [PC: Windows host app]  --ViGEmBus-->  [Virtual Xbox 360 controller]
```

Full wire format is documented in [PROTOCOL.md](PROTOCOL.md).

## Get the apps (no coding tools needed)

This repo is wired with **GitHub Actions** that build both apps for free.
To get real, installable files:

1. Create your own GitHub repository and push this project to it (see
   "Publishing this yourself" below) — or fork it if it's already hosted.
2. Go to the **Actions** tab of your repo. Two workflows run automatically
   on every push: *Build Android APK* and *Build Windows Host*.
3. Open a finished workflow run and download the artifact zip
   (`virtual-gamepad-android` or `virtual-gamepad-windows`) from the bottom
   of the run's summary page.
4. Unzip it — you'll have `app-release.apk` and/or `VirtualGamepadHost.exe`.

You can also trigger a build manually any time from Actions → the workflow
→ "Run workflow" (no code change needed).

### Installing on your phone
Copy the `.apk` to your phone (or download it there directly) and open it.
Android will ask you to allow installs from this source the first time —
that's expected for any app installed outside the Play Store.

### Running on your PC
1. Install **ViGEmBus** once: https://github.com/ViGEm/ViGEmBus/releases/latest
   (this is what lets Windows see the phone as a real Xbox controller).
2. Run `VirtualGamepadHost.exe`. It prints your PC's IP address.
3. Make sure Windows Firewall allows the app on your **private/home**
   network (Windows will prompt you the first time — click Allow).

### Connecting
Open the app on your phone (same WiFi network as the PC) — it auto-discovers
PCs running the host app, or you can type the IP shown in the console
window. Tap to connect, then play.

## Building it yourself locally (optional)

You don't need this if you're using the GitHub Actions builds above — it's
only for people who want to modify the code and test locally.

**Android app:**
```
cd android-app
flutter create --platforms=android --org com.virtualgamepad .
cp manifest-overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
flutter run          # with a device/emulator connected
# or: flutter build apk --release
```

**Windows app:**
```
cd windows-app
dotnet run
# or a distributable build:
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```
Requires the [.NET 8 SDK](https://dotnet.microsoft.com/download) and, to
actually drive a controller, ViGEmBus installed as above.

## Publishing this yourself

```
git init
git add .
git commit -m "Initial commit"
gh repo create virtual-gamepad --public --source=. --push
```
(or create the repo on github.com and follow its "push an existing
repository" instructions). Once pushed, the Actions tab will start
building automatically.

## Roadmap

- [x] WiFi transport (UDP), full Xbox 360 button/axis mapping
- [x] Auto-discovery of PCs on the local network
- [x] Multiple phones connecting simultaneously (each gets its own virtual controller)
- [ ] Bluetooth transport (fallback when there's no shared WiFi network)
- [ ] Customizable button layout / remapping in-app
- [ ] Rumble/vibration feedback from PC back to phone
- [ ] Windows tray icon + GUI (currently a console window)
- [ ] iOS build (Flutter already supports it; just needs a paid Apple
      developer account for signing, which the free CI can't do)

Contributions welcome — it's all MIT-licensed, do whatever you like with it.

## Troubleshooting

- **"Failed to create virtual controller"** on the PC → install ViGEmBus,
  then restart the host app.
- **Phone can't find the PC** → confirm both are on the *same* WiFi network
  (not phone hotspot + PC ethernet, etc.), and that Windows Firewall prompt
  was allowed. You can always fall back to typing the IP manually.
- **Input feels laggy** → this is UDP over WiFi, so it depends on your
  router; a 5GHz network or a router with fewer connected devices helps.

## License

MIT — see [LICENSE](LICENSE). Free for anyone to use, modify, and
redistribute, including commercially.
