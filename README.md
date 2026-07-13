<div align="center">

# 🎮 Virtual Gamepad

**Turn your phone into a real wireless Xbox controller for your PC — free, open source, no accounts, no ads.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Android APK](https://img.shields.io/badge/CI-Android%20APK-3DDC84?logo=android&logoColor=white)](.github/workflows/build-android.yml)
[![Build Windows Host](https://img.shields.io/badge/CI-Windows%20Host-0078D6?logo=windows&logoColor=white)](.github/workflows/build-windows.yml)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Made with .NET](https://img.shields.io/badge/Made%20with-.NET%208-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20me%20a-coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/kaifcoding)

</div>

> **Created by [kaifcoding](https://github.com/kaifcoding)** · © 2026 **Atomprod**. Free forever, MIT licensed — see [Credits & License](#-credits--license) below.

---

## What is this?

Virtual Gamepad is a two-part open source project:

| | |
|---|---|
| 📱 **Android app** (Flutter) | On-screen dual analog sticks, D-pad, ABXY face buttons, shoulder buttons, and analog triggers. Auto-discovers your PC over WiFi. |
| 🖥️ **Windows host app** (C#) | Creates a genuine virtual **Xbox 360 controller** via [ViGEmBus](https://github.com/ViGEm/ViGEmBus), so it works in *any* game or app that supports a normal controller — zero per-game setup. |

No subscriptions, no in-app purchases, no telemetry, no accounts. Fork it, modify it, ship your own version — it's MIT licensed.

## How it works

```
📱 Phone (Flutter app)  --UDP over WiFi-->  🖥️ PC (Windows host)  --ViGEmBus-->  🎮 Virtual Xbox 360 controller
```

The wire format is fully documented in [`PROTOCOL.md`](PROTOCOL.md) if you want to build your own client or host.

## ✨ Features

- Dual analog sticks with full-range 16-bit precision
- Analog L2/R2 triggers (pressure slider, not just on/off)
- Full D-pad, ABXY, shoulder buttons, Start/Back
- Auto-discovery of PCs on your WiFi network — tap and play
- Manual IP entry fallback for tricky networks
- Multiple phones can connect at once, each gets its own virtual controller
- Keeps your phone screen awake and locked to landscape while playing

## 🚀 Get the apps

This repo builds both apps automatically and for free using GitHub Actions — you don't need Android Studio, Flutter, Visual Studio, or any SDK installed to just *use* it.

1. **Fork or clone this repo to your own GitHub account** (see [Publishing this yourself](#-publishing-this-yourself) below).
2. Open the **Actions** tab on your repo. Two workflows build automatically on every push:
   - *Build Android APK*
   - *Build Windows Host*
3. Click into a finished (green ✅) run and download the artifacts from the bottom of the page:
   - `virtual-gamepad-android.zip` → contains `app-release.apk`
   - `virtual-gamepad-windows-installer.zip` → contains `VirtualGamepadHost-Setup.exe` (**recommended** — proper install wizard, Start Menu + Desktop icons, uninstaller)
   - `virtual-gamepad-windows-exe.zip` → contains the raw `VirtualGamepadHost.exe` if you'd rather not install anything (no shortcuts, no uninstaller — just a file you double-click)
4. You can also trigger a build manually any time: **Actions → workflow name → Run workflow**.

### 📲 Install on your phone

Copy `app-release.apk` to your phone and tap it. Android will ask permission to install from this source the first time (expected for any app outside the Play Store) — allow it, then install.

### 🖥️ Set up your PC

1. Install **[ViGEmBus](https://github.com/ViGEm/ViGEmBus/releases/latest)** once — this is the driver that makes Windows see your phone as a real controller. Reboot if prompted.
2. Run `VirtualGamepadHost-Setup.exe` and follow the wizard (tick "Create a desktop icon" if you want one — it's on by default). No admin rights needed; it installs to your user profile.
3. **Windows SmartScreen will likely warn you** the first time — "Windows protected your PC." This is expected for any free/unsigned app (code-signing certificates cost money this project doesn't spend). Click **"More info" → "Run anyway"**. If it looked like the app "didn't open" before, this dismissed warning is almost always why — check you didn't just close the SmartScreen dialog itself.
4. Launch **Virtual Gamepad Host** from the Start Menu or the desktop icon. The window shows your PC's IP address(es) — that's what you'll enter (or auto-discover) from the phone. Click "Show connection log" to see live connection activity.
5. Allow the app through **Windows Firewall** when prompted (check all network types — Domain, Private, *and* Public). If the prompt never appears, run [`windows-app/open-firewall-port.ps1`](windows-app/open-firewall-port.ps1) as Administrator to open the port manually.

### 🔗 Connect

1. Make sure your phone and PC are on the **same WiFi network**.
2. Open the app — it searches automatically and lists your PC by name.
3. Tap it to connect. If nothing shows up after a few seconds (see [Troubleshooting](#-troubleshooting)), type the IP shown in the PC's window instead.

## 🛠️ Building it yourself locally

Only needed if you want to edit the source and test without pushing to GitHub each time.

**Android app** — needs the [Flutter SDK](https://docs.flutter.dev/get-started/install):
```bash
cd android-app
flutter create --platforms=android --org in.atomprod .
cp manifest-overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
dart run flutter_launcher_icons
flutter run              # with a device/emulator connected
# or: flutter build apk --release
```
The app ID Flutter derives by default is `in.atomprod.virtual_gamepad`; CI forces it to the exact `in.atomprod.vgamepad` afterward (see the workflow) — if you need that exact ID locally too, edit the `applicationId`/`namespace` line in `android/app/build.gradle` (or `build.gradle.kts`) to match.

**Windows app** — needs the [.NET 8 SDK](https://dotnet.microsoft.com/download):
```bash
cd windows-app
dotnet run
# distributable build:
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```
To build the installer locally instead of via CI, install [Inno Setup](https://jrsoftware.org/isinfo.php), copy `app_icon.ico` into `publish/`, then run `ISCC installer\setup.iss`.

## 📦 Publishing this yourself

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/virtual-gamepad.git
git push -u origin main
```
Once pushed, the Actions tab starts building automatically — no extra setup required.

## 🩺 Troubleshooting

**The Windows app seems to not open at all**
Almost always **Windows SmartScreen** silently blocking it (see step 3 in "Set up your PC" above) — look for a blue "Windows protected your PC" dialog, possibly behind other windows, and click "More info → Run anyway." If you truly see nothing at all, try running it from a terminal (`VirtualGamepadHost.exe`) so any startup error prints instead of failing silently, and check that you're on Windows 10/11 x64 (the self-contained build doesn't support other platforms).

**"Failed to create virtual controller" on the PC**
Install ViGEmBus, then restart the host app.

**Auto-discovery doesn't find the PC**
This is the most common issue and it's almost always the *network*, not the apps:
- Confirm phone and PC are on the exact same WiFi network (not phone hotspot + PC on ethernet from a different router, not a guest network for one and main for the other).
- Many routers — especially mesh systems (eero, Google Nest WiFi), guest networks, and public/hotel WiFi — enable **"AP isolation" / "client isolation"**, which blocks device-to-device traffic on purpose for security. This is a router setting, not something the apps can bypass. Check your router's admin settings, or connect both devices to a different network without isolation.
- Confirm Windows Firewall allowed `VirtualGamepadHost.exe` on **all** profiles — rerun [`open-firewall-port.ps1`](windows-app/open-firewall-port.ps1) as Administrator to be sure.
- Watch the PC app's log (click "Show connection log") while the phone searches — if you never see `Discovery request from ...` lines appear, the broadcast traffic isn't reaching the PC at all (network/firewall issue, not the app).
- **Manual IP entry always works** even when auto-discovery can't (e.g. with AP isolation off but broadcast blocked) — type the IP shown in the PC app into the phone app.

**"No response" after entering an IP manually**
- Double check the IP — it changes if you reconnect to WiFi or restart the PC.
- Confirm the Virtual Gamepad Host window is actually running.
- Port `47998/UDP` needs to be reachable — see the firewall steps above.

**Input feels laggy**
This runs over UDP on WiFi, so it depends on your router and network congestion. A 5GHz network with fewer connected devices helps a lot.

## 🗺️ Roadmap

- [x] WiFi transport (UDP), full Xbox 360 button/axis mapping
- [x] Auto-discovery of PCs on the local network
- [x] Multiple phones connecting simultaneously
- [x] Windows host with a proper branded GUI window (not just a console)
- [x] Windows installer with Start Menu + Desktop shortcuts and uninstaller
- [x] Custom app icon (Android + Windows), custom app ID (`in.atomprod.vgamepad`)
- [x] Portrait-locked menus, landscape-locked gamepad screen
- [ ] Bluetooth transport (fallback when there's no shared WiFi network)
- [ ] Customizable button layout / remapping in-app
- [ ] Rumble/vibration feedback from PC back to phone
- [ ] Windows tray icon (minimize-to-tray)
- [ ] iOS build (Flutter already supports it; needs a paid Apple developer account for signing, which free CI can't provide)

## 🤝 Contributing

Issues and pull requests welcome. It's all MIT licensed — use it, fork it, remix it, sell it, whatever helps you.

## ☕ Support this project

If Virtual Gamepad saved you the cost of a real controller, consider buying the maintainer a coffee:

<a href="https://buymeacoffee.com/kaifcoding" target="_blank"><img src="https://img.shields.io/badge/Buy%20me%20a-coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee"></a>

*(Points at `buymeacoffee.com/kaifcoding` as a placeholder — swap in the real page if that handle isn't yours.)* It's entirely optional and doesn't unlock anything — every feature stays free for everyone either way.

## 🙌 Credits

Created with ❤️ by [kaifcoding](https://github.com/kaifcoding) · © 2026 Atomprod. See [NOTICE](NOTICE) for attribution terms if you fork or redistribute this project.

## 📄 License

[MIT](LICENSE) — free for anyone to use, modify, and redistribute, including commercially.
