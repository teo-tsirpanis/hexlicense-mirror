
unit mainform;

interface


uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ActnList, hexmgrlicense, System.Actions;

type
  TForm1 = class(TForm)
    HexLicense1: THexLicense;
    HexSerialMatrix1: THexSerialMatrix;
    HexSerialNumber1: THexSerialNumber;
    HexOwnerLicenseStorage1: THexOwnerLicenseStorage;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Memo1: TMemo;
    ActionList1: TActionList;
    acStart: TAction;
    acAuth: TAction;
    procedure HexOwnerLicenseStorage1DataExists(Sender: TObject;
      var Value: Boolean);
    procedure HexOwnerLicenseStorage1WriteData(sender: TObject; Stream: TStream;
      var Failed: Boolean);
    procedure HexOwnerLicenseStorage1ReadData(Sender: TObject; Stream: TStream;
      var Failed: Boolean);
    procedure HexLicense1LicenseBegins(Sender: TObject);
    procedure HexLicense1LicenseObtained(Sender: TObject);
    procedure HexLicense1LicenseExpires(Sender: TObject);
    procedure HexSerialMatrix1GetKeyMatrix(Sender: TObject;
      var Value: THexKeyMatrix);
    procedure acStartExecute(Sender: TObject);
    procedure acAuthExecute(Sender: TObject);
    procedure acAuthUpdate(Sender: TObject);
    procedure acStartUpdate(Sender: TObject);
    procedure HexLicense1AfterLicenseLoaded(Sender: TObject);
  private
    (* Below is our temporary, in-memory only storage.
       In a real live application your would use either
       a filestream, or perhaps better: embed the stream
       inside a protected zipfile or some other mechanism which
       makes it harder for users to alter the data *)
    FStream:  TMemoryStream;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses dateutils;

//#######################################################################
// Delphi action handlers - these just handle button states
//#######################################################################

procedure TForm1.acStartExecute(Sender: TObject);
begin
  (* Start the license cycle *)
  HexLicense1.BeginSession;
end;

procedure TForm1.acStartUpdate(Sender: TObject);
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState)
  and not (csCreating in ControlState) then
  TAction(sender).Enabled:=hexlicense1.Active=False;
end;

procedure TForm1.acAuthExecute(Sender: TObject);
begin
  (* Display the serial dialog *)
  Hexlicense1.Execute;
end;

procedure TForm1.acAuthUpdate(Sender: TObject);
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState)
  and not (csCreating in ControlState) then
  TAction(sender).Enabled:=Hexlicense1.Active
  and (hexlicense1.LicenseState<>THexLicenseState.lsValid);
end;
//#######################################################################
// License component event handlers
//#######################################################################

procedure TForm1.HexLicense1AfterLicenseLoaded(Sender: TObject);
begin
  (* Check if the program is bought *)
  if hexlicense1.LicenseState=lsValid then
  Begin
    (* a year ago? Time to upgrade! *)
    if  dateutils.DaysBetween(now,hexlicense1.Bought)>365 then
    Begin
      showmessage('This license has expired (12 months have passed since you bought the program)');
    end;
  end;
end;

procedure TForm1.HexLicense1LicenseBegins(Sender: TObject);
const
  CNT_TEXT  = 'Welcome to your trial version of %s!%s'
    + 'This is the first time you run our product';
begin
  showmessage(Format(CNT_TEXT,[HexLicense1.Software,#13]));
end;

procedure TForm1.HexLicense1LicenseExpires(Sender: TObject);
const
  CNT_TEXT  = 'Your trial license has expired!%s'
    + 'Some functions will be disabled';
begin
  showmessage(Format(CNT_TEXT,[#13]));
end;

procedure TForm1.HexLicense1LicenseObtained(Sender: TObject);
const
  CNT_TEXT = 'Thank you for buying %s!';
begin
  showmessage(Format(CNT_TEXT,[HexLicense1.Software]));
end;

procedure TForm1.HexOwnerLicenseStorage1DataExists(Sender: TObject;
  var Value: Boolean);
begin
  (* If data cannot be found, a new license is created.
     So here we just check if we have stored anything.
     Since this is a "in memory" example, this event will always
     return false, and a new license is created every time you
     run the example.
     In a real application your would check if you have a license
     file (perhaps inside a protected space, or embedded inside
     a picture or something. Be clever where you store the data *)
  value:=assigned(FStream);
end;

procedure TForm1.HexOwnerLicenseStorage1ReadData(Sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  (* The components will read the license at different
     situations, including when the license is created.
     But writedata is always invoked before anthing is read
     in such a scenario (to initialize the session).
     In a real life example you would return the license-data
     from some other medium here, like a file - stored "somewhere" *)
  FStream.Position:=0;
  Stream.CopyFrom(FStream,FStream.Size);
end;

procedure TForm1.HexOwnerLicenseStorage1WriteData(sender: TObject;
  Stream: TStream; var Failed: Boolean);
begin
  (* Since this is an "in memory" example, we make sure we create
     our storage stream if it doesnt exist *)
  if FStream=NIL then
  FStream:=TMemoryStream.Create;

  (* Reset the size of the target, since we want to update the data *)
  FStream.Size:=0;

  (* now copy over the new license data to the target *)
  FStream.CopyFrom(Stream,Stream.Size);
end;

procedure TForm1.HexSerialMatrix1GetKeyMatrix(Sender: TObject;
  var Value: THexKeyMatrix);
Const
  AMatrix: THexKeyMatrix =
  ($4E,$FC,$DC,$93,$02,$5A,$BE,$EC,$9D,$D5,$53,$58);
begin
  (* This is where we return the key matrix generated
     by the keygen application *)
  Value:=AMatrix;
end;

end.
