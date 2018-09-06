program keygen;

uses
  midaslib,
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  numberform in 'numberform.pas' {frmNumber},
  exportform in 'exportform.pas' {frmExport},
  aboutform in 'aboutform.pas' {frmAbout},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Smokey Quartz Kamri');
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
