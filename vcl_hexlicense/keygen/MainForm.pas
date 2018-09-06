
unit mainform;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ActnList,
  Vcl.StdCtrls, Vcl.ComCtrls, Data.DB, Datasnap.DBClient,
  clipbrd,
  numberform,
  exportform,
  aboutform,
  Vcl.Grids, Vcl.DBGrids, hexmgrlicense, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons,
  Vcl.ExtDlgs, Vcl.ExtCtrls, Vcl.ExtActns, System.Actions, System.ImageList;

type
  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    ActionList1: TActionList;
    acSaveRootKey: TAction;
    acLoadRootKey: TAction;
    acRandomizeRootKey: TAction;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Loadrootkey1: TMenuItem;
    Saverootkey1: TMenuItem;
    acQuit: TAction;
    N2: TMenuItem;
    Exit1: TMenuItem;
    HexSerialMatrix1: THexSerialMatrix;
    HexSerialGenerator1: THexSerialGenerator;
    edConst: TEdit;
    db: TClientDataSet;
    dbid: TAutoIncField;
    dbserial: TStringField;
    acGenerate: TAction;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Serialnumber1: TMenuItem;
    Generate1: TMenuItem;
    acNew: TAction;
    New1: TMenuItem;
    OpenDialog1: TOpenDialog;
    ImageList1: TImageList;
    acSaveSet: TAction;
    acAbout: TAction;
    About1: TMenuItem;
    About2: TMenuItem;
    acReset: TAction;
    N1: TMenuItem;
    Reset1: TMenuItem;
    Random1: TMenuItem;
    Exportkeyset1: TMenuItem;
    SaveText: TSaveTextFileDialog;
    SaveXML: TSaveDialog;
    SaveBin: TSaveDialog;
    Panel1: TPanel;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton5: TToolButton;
    ToolButton10: TToolButton;
    ToolButton4: TToolButton;
    ToolButton6: TToolButton;
    ToolButton8: TToolButton;
    ToolButton7: TToolButton;
    ToolButton9: TToolButton;
    Label1: TLabel;
    acBrowseToWebsite: TBrowseURL;
    PopupMenu1: TPopupMenu;
    acClearKeyset: TAction;
    acClearKeyset1: TMenuItem;
    Export1: TMenuItem;
    Resetkeyset1: TMenuItem;
    N3: TMenuItem;
    acToClipboard: TAction;
    Copytoclipboard1: TMenuItem;
    SaveJSON: TSaveTextFileDialog;
    SaveDialog2: TSaveDialog;
    Label2: TLabel;
    Image1: TImage;
    procedure acQuitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure acRandomizeRootKeyExecute(Sender: TObject);
    procedure HexSerialMatrix1GetKeyMatrix(Sender: TObject;
      var Value: THexKeyMatrix);
    procedure acGenerateExecute(Sender: TObject);
    procedure HexSerialGenerator1SerialnumberAvailable(Sender: TObject;
      Value: string; var Accepted: Boolean);
    procedure acNewExecute(Sender: TObject);
    procedure acLoadRootKeyExecute(Sender: TObject);
    procedure acSaveRootKeyExecute(Sender: TObject);
    procedure acSaveSetExecute(Sender: TObject);
    procedure acSaveSetUpdate(Sender: TObject);
    procedure acAboutExecute(Sender: TObject);
    procedure acSaveRootKeyUpdate(Sender: TObject);
    procedure acResetExecute(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure acRandomizeRootKeyUpdate(Sender: TObject);
    procedure acGenerateUpdate(Sender: TObject);
    procedure acClearKeysetExecute(Sender: TObject);
    procedure acClearKeysetUpdate(Sender: TObject);
    procedure acToClipboardExecute(Sender: TObject);
    procedure acToClipboardUpdate(Sender: TObject);
  private
    { Private declarations }
    FEdits: Array[0..11] of TEdit;
    FKeys:  THexKeyMatrix;
    FHasKey:  Boolean;
    procedure clearEditBoxes;
    Procedure LoadFromStream(aStream:TStream);
    procedure SaveToStream(aStream:TStream);
    Procedure LoadFromFile(aFilename:String);
    procedure SaveToFile(aFilename:String);
    Procedure ResetAll;
    function  makeConstString:String;
    function  validKeyBuffer:Boolean;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses shlobj;

function GetMyDocuments: string;
var
  path: array[0..Max_Path] of Char;
begin
  setLength(result,0);
  if ShGetSpecialFolderPath(0, path, CSIDL_Personal, False) then
  Result := Path;
end;

function  TfrmMain.validKeyBuffer:Boolean;
var
  x:  Integer;
  mValue: Integer;
Begin
  mvalue:=0;
  for x:=low(FKeys) to high(FKeys) do
  inc(mValue,FKeys[x]);
  result:=mValue>0;
end;


procedure TfrmMain.acAboutExecute(Sender: TObject);
var
  mForm:  TfrmAbout;
begin
  mForm:=TfrmAbout.Create(NIL);
  try
    mForm.ShowModal;
  finally
    mForm.Free;
  end;
end;

procedure TfrmMain.acClearKeysetExecute(Sender: TObject);
begin
  if db.Active then
  db.Close;
end;

procedure TfrmMain.acClearKeysetUpdate(Sender: TObject);
begin
  if not (csLoading in ComponentState)
  and not (csDestroying in ComponentState) then
  TAction(sender).Enabled:=FHasKey and db.Active and (db.RecordCount>0);
end;

procedure TfrmMain.acGenerateExecute(Sender: TObject);
var
  mForm:  TfrmNumber;
  mValue: Integer;
begin
  mForm:=TfrmNumber.Create(NIL);
  try
    if mForm.ShowModal=mrOK then
    begin

      if db.Active then
      db.Close;

      db.CreateDataSet;
      db.Active:=True;

      screen.Cursor:=crHourglass;
      db.DisableControls;
      try
        mValue:=100;
        tryStrToInt(mForm.Edit1.Text,mValue);
        self.HexSerialGenerator1.Generate(mValue);

        db.Last;
        db.First;
      finally
        db.EnableControls;
        screen.Cursor:=crDefault;
      end;
    end;
  finally
    mForm.Free;
  end;
end;


Procedure TfrmMain.ResetAll;
Begin
  if db.Active then
  db.Close;
  clearEditBoxes;
  edConst.Text:='';
  FHasKey:=False;
end;

procedure TfrmMain.Label1Click(Sender: TObject);
begin
  acBrowseToWebsite.Execute;
end;

Procedure TfrmMain.LoadFromFile(aFilename:String);
var
  mFile:  TFileStream;
Begin
  mFile:=TFilestream.Create(aFilename,fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(mFile);
  finally
    mFile.Free;
  end;
end;

procedure TfrmMain.SaveToFile(aFilename:String);
var
  mFile:  TFileStream;
Begin
  mFile:=TFileStream.Create(aFilename,fmCreate);
  try
    SaveToStream(mFile);
  finally
    mFile.Free;
  end;
end;

Procedure TfrmMain.LoadFromStream(aStream:TStream);
var
  mReader:  TReader;
  x:  Integer;
  mValue: Integer;
Begin
  mReader:=TReader.Create(aStream,1024);
  try
    for x:=low(FEdits) to high(FEdits) do
    Begin
      mValue:=mReader.ReadInteger;
      FEdits[x].Text:=IntToHex(mValue,2);
      FKeys[x]:=mValue;
    end;
  finally
    mReader.Free;
  end;
end;

procedure TfrmMain.SaveToStream(aStream:TStream);
var
  mWriter:  TWriter;
  x:  Integer;
  mText:  String;
  mValue: Integer;
Begin
  mWriter:=TWriter.Create(aStream,1024);
  try
    for x:=low(FEdits) to high(FEdits) do
    Begin
      mValue:=0;
      if Length(FEdits[x].text)=2 then
      Begin
        mText:='$' + FEdits[x].Text;
        tryStrToInt(mText,mValue);
      end;
      mWriter.WriteInteger(mValue);
    end;
  finally
    mWriter.FlushBuffer;
    mWriter.Free;
  end;
end;

procedure TfrmMain.acSaveRootKeyExecute(Sender: TObject);
begin
  if SaveDialog2.InitialDir='' then
  SaveDialog2.InitialDir:=GetMyDocuments;
  if self.SaveDialog2.Execute then
  begin
    try
      SaveToFile(SaveDialog2.FileName);
    except
      on e: exception do
      Begin
        showmessage('Failed to save serial-file:' + e.Message);
      end;
    end;
  end;
end;

procedure TfrmMain.acSaveRootKeyUpdate(Sender: TObject);
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState) then
  TAction(Sender).Enabled:=self.validKeyBuffer;
end;

procedure TfrmMain.acSaveSetExecute(Sender: TObject);
var
  mForm:  TfrmExport;

  procedure SaveTextFile;
  var
    mData:  TStringlist;
    mPos: Integer;
    mEncoding:  TEncoding;
    mEncName: String;
  begin
    mEncoding:=NIL;
    
    mData:=TStringlist.Create;
    try
      db.DisableControls;
      screen.Cursor:=crHourGlass;
      try
        mPos:=db.RecNo;
        db.First;
        Repeat
          mData.Add(db.FieldByName('serial').AsString);
          db.Next;
        until db.Eof;
        db.RecNo:=mPos;
      finally
        db.EnableControls;
        screen.Cursor:=crDefault;
      end;

      if SaveText.InitialDir='' then
      SaveText.InitialDir:=getMyDocuments;
      if SaveText.Execute then
      Begin
        mEncName:=SaveText.Encodings[SaveText.EncodingIndex];

        try
          mEncoding:=TEncoding.GetEncoding(mEncName);
        except
          on exception do;
        end;

        if mEncoding=NIL then
        mEncoding:=TEncoding.ANSI;
        mData.SaveToFile(SaveText.FileName,mEncoding);
      end;
    finally
      mData.Free;
    end;
  end;

  Procedure SaveXMLDataset;
  begin
    if SaveXML.InitialDir='' then
    SaveXML.InitialDir:=getMyDocuments;
    if SaveXML.Execute then
    Begin
      try
        db.SaveToFile(SaveXML.FileName,TDatapacketFormat.dfXMLUTF8);
      except
        on e: exception do
        Showmessage('Failed to save to XML:' + e.message);
      end;
    end;
  end;

  Procedure SaveBinaryDataset;
  begin
    if SaveBin.InitialDir='' then
    SaveBin.InitialDir:=getMyDocuments;
    if SaveBin.Execute then
    Begin
      try
        db.SaveToFile(SaveBin.FileName,TDatapacketFormat.dfBinary);
      except
        on e: exception do
        showmessage('Failed to save to binary:' + e.Message);
      end;
    end;
  end;

  Procedure SaveJSONDataset;
  var
    mData:  TStringlist;
    mPos: Integer;
    mEncoding:  TEncoding;
    mEncName: String;
    mCount: Integer;
    mFilename:  String;
    LText:  string;
  begin
    mEncoding:=NIL;
    
    mData:=TStringlist.Create;
    try
      db.DisableControls;
      screen.Cursor:=crHourGlass;
      try

        mData.Add('{');
        mData.Add(' "serialnumbers": [');
        mPos:=db.RecNo;
        mCount:=0;
        db.First;
        Repeat
          inc(mCount);
          (* Make sure GUI remains usable *)
          if (mCount mod 100)=99 then
          application.ProcessMessages;

          // URL Encode
          LText := db.FieldByName('serial').AsString;
          LText := stringreplace(LText,'-','%2d',[rfReplaceAll]);

          if db.RecNo < db.RecordCount then
          mData.Add(#9 + '"' + LText + '",') else
          mData.Add(#9 + '"' + LText + '"');

          db.Next;
        until db.Eof;
        db.RecNo:=mPos;
      finally
        db.EnableControls;
        screen.Cursor:=crDefault;
      end;
      mData.Add('  ]');
      mData.Add('}');

      if SaveJSON.InitialDir='' then
      SaveJSON.InitialDir:=getMyDocuments;
      if SaveJSON.Execute then
      Begin
        mEncName:=SaveJSON.Encodings[SaveJSON.EncodingIndex];

        if mEncName<>'ANSI' then
        Begin
          try
            mEncoding:=TEncoding.GetEncoding(mEncName);
          except
            on exception do;
          end;
        end;

        if mEncoding=NIL then
        mEncoding:=TEncoding.ANSI;

        mFilename:=SaveJSON.Filename;
        mData.SaveToFile(mFilename,mEncoding);
      end;
    finally
      mData.Free;
    end;
  end;


begin
  mForm:=TFrmExport.Create(NIL);
  try
    if mForm.ShowModal=mrOK then
    begin
      case mForm.RadioGroup1.ItemIndex of
      0:  SaveTextFile;
      1:  SaveXMLDataset;
      2:  SaveBinaryDataset;
      3:  SaveJSONDataset;
      end;
    end;
  finally
    mForm.Free;
  end;
end;

procedure TfrmMain.acSaveSetUpdate(Sender: TObject);
begin
  TAction(sender).Enabled:=db.Active and (db.RecordCount>0);
end;

procedure TfrmMain.acToClipboardExecute(Sender: TObject);
var
  mtext:  String;
begin
  mtext:=db.FieldByName('serial').AsString;
  Clipboard.asText:=mText;
end;

procedure TfrmMain.acToClipboardUpdate(Sender: TObject);
begin
  if not (csLoading in ComponentState)
  and not (csDestroying in ComponentState) then
  TAction(Sender).Enabled:=FHasKey and db.Active and (db.RecordCount>0)
    and (dbgrid1.SelectedIndex>=0)
end;

procedure TfrmMain.acLoadRootKeyExecute(Sender: TObject);
begin
  if opendialog1.InitialDir='' then
  opendialog1.InitialDir:=GetMyDocuments;
  if opendialog1.Execute then
  Begin
    ResetAll;

    try
      LoadFromFile(opendialog1.FileName);
    except
      on e: exception do
      begin
        if db.Active then
        self.db.Close;
        showmessage('Failed to load serial-file:' + e.Message);
      end;
    end;

    edConst.Text:=makeConstString;
    FHasKey:=True;

  end;
end;

procedure TfrmMain.acNewExecute(Sender: TObject);
Begin
  if db.Active and (db.RecordCount>0) then
  begin
    if MessageDlg('Are you sure you wish to create a new key?' + #13 +
    'This will erase your current keyset', mtConfirmation,[mbYes, mbNo], 0) = mrNO then
    exit;
  end;

  ResetAll;

  FHasKey:=True;
  acRandomizeRootKey.Execute;
end;

procedure TfrmMain.acQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FEdits[00]:=Edit1;
  FEdits[01]:=Edit2;
  FEdits[02]:=Edit3;
  FEdits[03]:=Edit4;
  FEdits[04]:=Edit5;
  FEdits[05]:=Edit6;
  FEdits[06]:=Edit7;
  FEdits[07]:=Edit8;
  FEdits[08]:=Edit9;
  FEdits[09]:=Edit10;
  FEdits[10]:=Edit11;
  FEdits[11]:=Edit12;
  clearEditBoxes;
end;

procedure TfrmMain.HexSerialGenerator1SerialnumberAvailable(Sender: TObject;
  Value: string; var Accepted: Boolean);
var
  mSerial:  THexSerialNumber;
begin
  db.IndexName:='nameIndex';
  try
    if not db.FindKey([Value]) then
    Begin

      mSerial:=THexSerialNumber.Create(NIL);
      try
        mSerial.SerialMatrix:=HexSerialMatrix1;
        if not mSerial.Validate(Value) then
        exit;
      finally
        mSerial.Free;
      end;

      db.Insert;
      db.FieldByName('serial').AsString:=Value;
      db.Post;
      Accepted:=True;
    end else
    accepted:=False;
  finally
    db.IndexName:='';
  end;
end;

procedure TfrmMain.HexSerialMatrix1GetKeyMatrix(Sender: TObject;
  var Value: THexKeyMatrix);
begin
  Value:=FKeys;
end;

procedure TfrmMain.acRandomizeRootKeyExecute(Sender: TObject);
var
  x:  Integer;
  mValue:Byte;
begin
  randomize;
  for x:=low(FEdits) to high(FEdits) do
  Begin
    mValue:=random(255);
    FKeys[x]:=mValue;
    FEdits[x].Text:=IntToHex(FKeys[x],2);
  end;
  edConst.Text:=makeConstString;
end;

procedure TfrmMain.acRandomizeRootKeyUpdate(Sender: TObject);
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState) then
  TAction(sender).Enabled:=FHasKey;
end;


procedure TfrmMain.acGenerateUpdate(Sender: TObject);
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState) then
  TAction(sender).Enabled:=FHasKey and validKeyBuffer;
end;


procedure TfrmMain.acResetExecute(Sender: TObject);
begin
  self.ResetAll;
end;

function  TfrmMain.makeConstString:String;
var
  mText:  String;
  x:  Integer;
Begin
  setLength(result,0);
  for x:=low(FKeys) to high(FKeys) do
  Begin
    mText:=mText + '$' + IntToHex(FKeys[x],2);
    if x<high(FEdits) then
    mText:=mtext + ',';
  end;
  result:=format('Const CNT_ROOTKEY:THexKeyMatrix = (%s);',[mText]);
end;

procedure TfrmMain.clearEditBoxes;
var
  x:  Integer;
Begin
  for x:=low(FEdits) to high(FEdits) do
  Begin
    FEdits[x].Text:='';
    FKeys[x]:=0;
  end;
end;



end.
