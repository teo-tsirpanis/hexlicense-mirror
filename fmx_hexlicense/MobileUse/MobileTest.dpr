program MobileTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  FMX.hexmgrlicense in '..\FMX.hexmgrlicense.pas',
  FMX.hextools in '..\FMX.hextools.pas',
  FMX.frmhexmgrlicense in '..\FMX.frmhexmgrlicense.pas' {frmLicenseProperties},
  FMX.Hex.Android.Tools in '..\FMX.Hex.Android.Tools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
