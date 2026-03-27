[Setup]
AppId={{EA24-SERVER-UUID-1234}}
AppName=EA-24 Server
AppVersion=0.3.0
AppPublisher=Somkid2042
DefaultDirName={localappdata}\EA-24 Server
DisableProgramGroupPage=yes
; We don't want a loud wizard since the user wants it stealthy, but let's keep it simple
PrivilegesRequired=lowest
OutputDir=target\release
OutputBaseFilename=ea-server-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "target\release\ea-server.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Omitted desktop shortcut intentionally
Name: "{autoprograms}\EA-24 Server"; Filename: "{app}\ea-server.exe"

[Registry]
; Add to Windows Startup (Current User)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "EAServer"; ValueData: "{app}\ea-server.exe"; Flags: uninsdeletevalue

[Run]
; Run immediately after install in hidden mode
Filename: "{app}\ea-server.exe"; Description: "Launch EA-24 Server"; Flags: nowait postinstall runhidden
