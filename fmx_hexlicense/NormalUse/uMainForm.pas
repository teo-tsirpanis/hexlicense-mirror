unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,

  FMX.hexmgrlicense,
  FMX.HexBuffers,
  FMX.HexTools, FMX.Layouts, FMX.ListBox;

type

  //981BA5-E7FFB1-2CC6E1-907E60
  //5F6CA5-BDBB72-2C36D2-7E7ED0

  TMainForm = class(TForm)
    btnInvokeLicensePropertiesDialog: TButton;
    btnStartLicenseSession: TButton;
    btnTestByteRage: TButton;
    FMXHexLicense1: TFMXHexLicense;
    FMXHexOwnerLicenseStorage1: TFMXHexOwnerLicenseStorage;
    FMXHexSerialMatrix1: TFMXHexSerialMatrix;
    FMXHexSerialNumber1: TFMXHexSerialNumber;
    ListBox1: TListBox;
    procedure btnInvokeLicensePropertiesDialogClick(Sender: TObject);
    procedure btnStartLicenseSessionClick(Sender: TObject);
    procedure btnTestByteRageClick(Sender: TObject);
    procedure FMXHexSerialMatrix1GetKeyMatrix(Sender: TObject;
      var Value: TFMXHexKeyMatrix);
    procedure FMXHexOwnerLicenseStorage1DataExists(Sender: TObject;
      var Value: Boolean);
    procedure FMXHexOwnerLicenseStorage1ReadData(Sender: TObject;
      Stream: TStream; var Failed: Boolean);
    procedure FMXHexOwnerLicenseStorage1WriteData(sender: TObject;
      Stream: TStream; var Failed: Boolean);
    procedure FMXHexLicense1AfterLicenseLoaded(Sender: TObject);
    procedure FMXHexLicense1LicenseBegins(Sender: TObject);
    procedure FMXHexLicense1LicenseExpires(Sender: TObject);
    procedure FMXHexLicense1LicenseObtained(Sender: TObject);
  private
    { Private declarations }
    FStream:  TMemoryStream;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.NetEncoding,
  dateutils;

{$R *.fmx}

procedure TMainForm.btnInvokeLicensePropertiesDialogClick(Sender: TObject);
begin
  FMXHexLicense1.Execute;
end;

procedure TMainForm.btnStartLicenseSessionClick(Sender: TObject);
begin
  FMXHexLicense1.BeginSession;
end;

procedure TMainForm.btnTestByteRageClick(Sender: TObject);
var
  LTools: THexTools;
begin
  if FMX.HexTools.GetHexTools(LTools) then
  begin
    try
      listbox1.Items.Add('Serial: ' + LTools.DiskSerial);
      listbox1.Items.Add('IP: ' + LTools.IPAddress);
      listbox1.Items.Add('MAC: ' + LTools.MacAddress);

      if LTools.Failed then
        showmessage(LTools.LastError);

    finally
      LTools := nil;
    end;
  end;
  //With TBRSize do
  //showmessage( TBRSize.Asstring( Gigabyte + MegabytesOf(122) + KiloBytesOf(400) + 94) );
end;

procedure TMainForm.FMXHexLicense1AfterLicenseLoaded(Sender: TObject);
begin
  if FMXHexLicense1.LicenseState=lsValid then
  Begin
    // a year ago? Time to upgrade!
    if  dateutils.DaysBetween(now,FMXHexLicense1.Bought)>365 then
    Begin
      showmessage('This license has expired (12 months have passed since you bought the program)');
    end;
  end;
end;

procedure TMainForm.FMXHexLicense1LicenseBegins(Sender: TObject);
const
  CNT_TEXT  = 'Welcome to your trial version of %s!%s'
    + 'This is the first time you run our product';
begin
  showmessage(Format(CNT_TEXT,[FMXHexLicense1.Software,#13]));
end;

procedure TMainForm.FMXHexLicense1LicenseExpires(Sender: TObject);
const
  CNT_TEXT  = 'Your trial license has expired!%s'
    + 'Some functions will be disabled';
begin
  showmessage(Format(CNT_TEXT,[#13]));
end;

procedure TMainForm.FMXHexLicense1LicenseObtained(Sender: TObject);
const
  CNT_TEXT = 'Thank you for buying %s!';
begin
  showmessage(Format(CNT_TEXT,[FMXHexLicense1.Software]));
end;

procedure TMainForm.FMXHexOwnerLicenseStorage1DataExists(Sender: TObject;
  var Value: Boolean);
begin
  value:=assigned(FStream);
end;

procedure TMainForm.FMXHexOwnerLicenseStorage1ReadData(Sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  FStream.Position:=0;
  Stream.CopyFrom(FStream,FStream.Size);
end;

procedure TMainForm.FMXHexOwnerLicenseStorage1WriteData(sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  if FStream=NIL then
  FStream:=TMemoryStream.Create;
  FStream.Size:=0;
  FStream.CopyFrom(Stream,Stream.Size);
end;

procedure TMainForm.FMXHexSerialMatrix1GetKeyMatrix(Sender: TObject;
  var Value: TFMXHexKeyMatrix);
const
  CNT_ROOTKEY: TFMXHexKeyMatrix = ($C7,$54,$4B,$6F,$5C,$21,$9D,$D5,$E1,$4E,$E7,$E2);
begin
  value := CNT_ROOTKEY;
end;

end.
