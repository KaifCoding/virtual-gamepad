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
OutputDir=..\dist
OutputBaseFilename=VirtualGamepadHost-Setup
; Pulls the icon directly from the windows-app root directory
SetupIconFile=..\app_icon.ico
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
; Pulls the icon from the windows-app root directory to pack it into the installation package
Source: "..\app_icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{userprograms}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{userprograms}\Uninstall Virtual Gamepad Host"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Virtual Gamepad Host"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Virtual Gamepad Host now"; Flags: nowait postinstall skipifsilent