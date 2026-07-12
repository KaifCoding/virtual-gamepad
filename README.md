<div align="center">

# 🎮 Virtual Gamepad

**Turn your phone into a real wireless Xbox controller for your PC — free, open source, no accounts, no ads.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Android APK](https://img.shields.io/badge/CI-Android%20APK-3DDC84?logo=android&logoColor=white)](.github/workflows/build-android.yml)
[![Build Windows Host](https://img.shields.io/badge/CI-Windows%20Host-0078D6?logo=windows&logoColor=white)](.github/workflows/build-windows.yml)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Made with .NET](https://img.shields.io/badge/Made%20with-.NET%208-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com)

</div>

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
3. Click into a finished (green ✅) run and download the artifact from the bottom of the page:
   - `virtual-gamepad-android.zip` → contains `app-release.apk`
   - `virtual-gamepad-windows.zip` → contains `VirtualGamepadHost.exe`
4. You can also trigger a build manually any time: **Actions → workflow name → Run workflow**.

### 📲 Install on your phone

Copy `app-release.apk` to your phone and tap it. Android will ask permission to install from this source the first time (expected for any app outside the Play Store) — allow it, then install.

### 🖥️ Set up your PC

1. Install **[ViGEmBus](https://github.com/ViGEm/ViGEmBus/releases/latest)** once — this is the driver that makes Windows see your phone as a real controller. Reboot if prompted.
2. Run `VirtualGamepadHost.exe`. A console window prints your PC's IP address.
3. Allow the app through **Windows Firewall** when prompted (check all network types — Domain, Private, *and* Public). If the prompt never appears, run [`windows-app/open-firewall-port.ps1`](windows-app/open-firewall-port.ps1) as Administrator to open the port manually.

### 🔗 Connect

1. Make sure your phone and PC are on the **same WiFi network**.
2. Open the app — it searches automatically and lists your PC by name.
3. Tap it to connect. If nothing shows up after a few seconds (see [Troubleshooting](#-troubleshooting)), type the IP shown in the PC's console window instead.

## 🛠️ Building it yourself locally

Only needed if you want to edit the source and test without pushing to GitHub each time.

**Android app** — needs the [Flutter SDK](https://docs.flutter.dev/get-started/install):
```bash
cd android-app
flutter create --platforms=android --org com.virtualgamepad .
cp manifest-overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
flutter run              # with a device/emulator connected
# or: flutter build apk --release
```

**Windows app** — needs the [.NET 8 SDK](https://dotnet.microsoft.com/download):
```bash
cd windows-app
dotnet run
# distributable build:
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

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

**"Failed to create virtual controller" on the PC**
Install ViGEmBus, then restart the host app.

**Auto-discovery doesn't find the PC**
This is the most common issue and it's almost always the *network*, not the apps:
- Confirm phone and PC are on the exact same WiFi network (not phone hotspot + PC on ethernet from a different router, not a guest network for one and main for the other).
- Many routers — especially mesh systems (eero, Google Nest WiFi), guest networks, and public/hotel WiFi — enable **"AP isolation" / "client isolation"**, which blocks device-to-device traffic on purpose for security. This is a router setting, not something the apps can bypass. Check your router's admin settings, or connect both devices to a different network without isolation.
- Confirm Windows Firewall allowed `VirtualGamepadHost.exe` on **all** profiles — rerun [`open-firewall-port.ps1`](windows-app/open-firewall-port.ps1) as Administrator to be sure.
- Watch the PC's console window while the phone searches — if you never see `Discovery request from ...` lines appear, the broadcast traffic isn't reaching the PC at all (network/firewall issue, not the app).
- **Manual IP entry always works** even when auto-discovery can't (e.g. with AP isolation off but broadcast blocked) — type the IP shown in the PC console into the app.

**"No response" after entering an IP manually**
- Double check the IP — it changes if you reconnect to WiFi or restart the PC.
- Confirm `VirtualGamepadHost.exe` is actually running (the console window should be open).
- Port `47998/UDP` needs to be reachable — see the firewall steps above.

**Input feels laggy**
This runs over UDP on WiFi, so it depends on your router and network congestion. A 5GHz network with fewer connected devices helps a lot.

## 🗺️ Roadmap

- [x] WiFi transport (UDP), full Xbox 360 button/axis mapping
- [x] Auto-discovery of PCs on the local network
- [x] Multiple phones connecting simultaneously
- [ ] Bluetooth transport (fallback when there's no shared WiFi network)
- [ ] Customizable button layout / remapping in-app
- [ ] Rumble/vibration feedback from PC back to phone
- [ ] Windows tray icon + proper GUI (currently a console window)
- [ ] iOS build (Flutter already supports it; needs a paid Apple developer account for signing, which free CI can't provide)

## 🤝 Contributing

Issues and pull requests welcome. It's all MIT licensed — use it, fork it, remix it, sell it, whatever helps you.

## 📄 License

[MIT](LICENSE) — free for anyone to use, modify, and redistribute, including commercially.
