; Inno Setup script for Virtual Gamepad Host.
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
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
; Look up one level, then create a clean setup output folder
OutputDir=..\dist
OutputBaseFilename=VirtualGamepadHost-Setup
; Look up one level to find the publish folder for the icon
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
; Look up one level to grab files from the publish folder
Source: "..\publish\VirtualGamepadHost.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\publish\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{userprograms}\Uninstall Virtual Gamepad Host"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Virtual Gamepad Host now"; Flags: nowait postinstall skipifsilent