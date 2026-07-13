; Inno Setup script for Virtual Gamepad Host.
; Compiled by the "Build Windows Host" GitHub Actions workflow using the
; Inno Setup command-line compiler (ISCC), which the workflow installs via
; Chocolatey on the windows-latest runner. You can also compile it yourself
; locally with Inno Setup (https://jrsoftware.org/isinfo.php) if you'd
; rather build outside CI.
;
; Expects the published app (VirtualGamepadHost.exe + app_icon.ico) to
; already exist in ..\publish relative to this script.

#define MyAppName "Virtual Gamepad Host"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Atomprod"
#define MyAppURL "https://atomprod.in"
#define MyAppExeName "VirtualGamepadHost.exe"

[Setup]
AppId={{IN-ATOMPROD-VGAMEPAD-HOST-1A2B3C}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\VirtualGamepadHost
DefaultGroupName=Virtual Gamepad
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
OutputDir=..\..\dist
OutputBaseFilename=VirtualGamepadHost-Setup
SetupIconFile=..\publish\app_icon.ico
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: checkedonce

[Files]
Source: "..\publish\VirtualGamepadHost.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\publish\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Uninstall Virtual Gamepad Host"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Virtual Gamepad Host now"; Flags: nowait postinstall skipifsilent
