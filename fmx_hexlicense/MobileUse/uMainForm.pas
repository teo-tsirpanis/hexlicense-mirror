unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.hexmgrlicense, FMX.ScrollBox,
  FMX.Memo;

type
  TMainForm = class(TForm)
    btnTestHexLicense: TButton;
    FMXHexLicense1: TFMXHexLicense;
    FMXHexOwnerLicenseStorage1: TFMXHexOwnerLicenseStorage;
    FMXHexSerialMatrix1: TFMXHexSerialMatrix;
    FMXHexSerialNumber1: TFMXHexSerialNumber;
    mnoLogOutput: TMemo;
    MainToolbar: TToolBar;
    lblAppTitle: TLabel;
    btnCloseApp: TButton;
    procedure btnTestHexLicenseClick(Sender: TObject);
    procedure HexOwnerLicenseStorage1DataExists(Sender: TObject;
      var Value: Boolean);
    procedure HexOwnerLicenseStorage1ReadData(Sender: TObject; Stream: TStream;
      var Failed: Boolean);
    procedure HexOwnerLicenseStorage1WriteData(sender: TObject; Stream: TStream;
      var Failed: Boolean);
    procedure HexLicense1LicenseBegins(Sender: TObject);
    procedure HexLicense1LicenseObtained(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FMXHexSerialMatrix1GetKeyMatrix(Sender: TObject;
      var Value: TFMXHexKeyMatrix);
    procedure FormCreate(Sender: TObject);
    procedure btnCloseAppClick(Sender: TObject);
  private
    { Private declarations }
    FData: TMemoryStream;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses FMX.HexTools;

procedure TMainForm.btnTestHexLicenseClick(Sender: TObject);
begin

  try
    if not FMXHexLicense1.Active then
    FMXHexLicense1.BeginSession;
  except
    on e: exception do
    begin
      showmessage('BeginSession: ' + e.Message);
    end;
  end;

  try
    FMXHexLicense1.Execute;
  except
    on e: exception do
    begin
      showmessage('Execute:' + e.Message);
    end;
  end;
end;

procedure TMainForm.FMXHexSerialMatrix1GetKeyMatrix(Sender: TObject;
  var Value: TFMXHexKeyMatrix);
const
  CNT_ROOTKEY: TFMXHexKeyMatrix = ($E0,$1A,$80,$99,$89,$1B,$49,$49,$64,$DA,$FE,$86);
begin
  Value := CNT_ROOTKEY;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LTools: THexTools;
begin
  if GetHexTools(LTools) then
  begin
    mnoLogOutput.Lines.Add( LTools.MacAddress );
    mnoLogOutput.GoToTextEnd;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //if not HexLicense1.Active then
  //HexLicense1.BeginSession;
end;

procedure TMainForm.HexLicense1LicenseBegins(Sender: TObject);
begin
  //showmessage('License begins');
end;

procedure TMainForm.HexLicense1LicenseObtained(Sender: TObject);
begin
  //showmessage('License obtained!');
end;

procedure TMainForm.HexOwnerLicenseStorage1DataExists(Sender: TObject;
  var Value: Boolean);
begin
  Value := FData <> nil;
end;

procedure TMainForm.HexOwnerLicenseStorage1ReadData(Sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  if FData = nil then
    FData := TMemoryStream.Create;

  Failed := FData.Size < 1;
  if not Failed then
  begin
    FData.Position := 0;
    Stream.CopyFrom(FData,FData.Size);
  end;
end;

procedure TMainForm.HexOwnerLicenseStorage1WriteData(sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  if FData = nil then
    FData := TMemoryStream.Create;

  failed := false;
  try
    FData.Size:=0;
    FData.CopyFrom(Stream,Stream.Size);
  except
    on exception do
    begin
      Failed := true;
    end;
  end;
end;

procedure TMainForm.btnCloseAppClick(Sender: TObject);
begin
  Close;
end;

end.
