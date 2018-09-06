program HexLicenseCheck;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  FMX.frmhexmgrlicense in '..\FMX.frmhexmgrlicense.pas' {frmLicenseProperties};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  //Application.CreateForm(TfrmLicenseProperties, frmLicenseProperties);
  Application.Run;
end.
