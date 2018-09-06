
unit formabout;

interface

uses
  pngimage,
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, Buttons, StdCtrls,
  Actions, ActnList, ImageList, ImgList;

type
  TfrmPrefs = class(TForm)
    GrpExecutable: TGroupBox;
    lbIngress: TLabel;
    edPath: TEdit;
    btnSelectFile: TSpeedButton;
    lbStorageHeader: TLabel;
    lbRegStored: TLabel;
    lbRegLocation: TLabel;
    acActions: TActionList;
    acSave: TAction;
    acCancel: TAction;
    ImageList1: TImageList;
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    acSelect: TAction;
    FileOpenDialog1: TFileOpenDialog;
    procedure acCancelExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure acSaveUpdate(Sender: TObject);
    procedure acSelectExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function  ReadRegPath: string;
procedure WriteRegPath(FullPath: string);

implementation

{$R *.dfm}

uses registry;

function ReadRegPath: string;
var
  LReg: TRegistry;
  LText:  string;
begin
  // Create registry object in read mode
  result := '';
  try
    LReg := TRegistry.Create(KEY_ALL_ACCESS);
    LReg.RootKey:= HKEY_CURRENT_USER;
  except
    on e: exception do
    begin
      LText := 'Failed to access the registry: KEY_ALL_ACCESS' + #13
      + 'HKEY_CURRENT_USER\Software\HexLicense' + #13
      + Format('System threw exception %s with [%s]',[e.ClassName,e.Message]);
    end;
  end;

  try
    // Attemp to read, create if required
    try
      if LReg.OpenKey('Software\HexLicense', true) then
      begin
        try
          result := LReg.ReadString('keygen.path');
        finally
          LReg.CloseKey;
        end;
      end else
      raise Exception.Create('Key [Software\HexLicense] did not exist. Attempt to create failed');
    except
      on e: exception do
      begin
        LText := 'Failed to read from the registry:' + #13
        + 'HKEY_CURRENT_USER\Software\HexLicense\keygen.path' + #13
        + Format('System threw exception %s with [%s]',[e.ClassName,e.Message]);
        Showmessage(LText);
      end;
    end;
  finally
    // Release
    LReg.Free;
  end;
end;

procedure WriteRegPath(FullPath: string);
var
  LReg: TRegistry;
  LText:  string;
begin
  // Create registry object in write mode
  try
    LReg := TRegistry.Create(KEY_WRITE);
    LReg.RootKey := HKEY_CURRENT_USER;
  except
    on e: exception do
    begin
      LText := 'Failed to access the registry: KEY_WRITE' + #13
      + 'HKEY_CURRENT_USER\Software\HexLicense' + #13
      + Format('System threw exception %s with [%s]',[e.ClassName,e.Message]);
    end;
  end;

  try
    // Attempt to open key
    try
      if LReg.OpenKey('Software\HexLicense',true) then
      begin
        try
          LReg.WriteString('keygen.path',FullPath);
        finally
          LReg.CloseKey;
        end;
      end;
    except
      on e: exception do
      begin
        LText := 'Failed to write to the registry:' + #13
        + 'HKEY_CURRENT_USER\Software\HexLicense\keygen.path' + #13
        + Format('System threw exception %s with [%s]',[e.ClassName,e.Message]);
        Showmessage(LText);
      end;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TfrmPrefs.acCancelExecute(Sender: TObject);
begin
  modalresult := mrCancel;
end;

procedure TfrmPrefs.acSaveExecute(Sender: TObject);
begin
  WriteRegPath(trim(edPath.Text));
  modalresult := mrOK;
end;

procedure TfrmPrefs.acSaveUpdate(Sender: TObject);
var
  LText:  string;
begin
  if not (csDestroying in ComponentState)
  and not (csLoading in ComponentState) then
  begin
    LText := trim(edPath.Text);
    TAction(sender).Enabled := ( length(LText)>0 )
    and FileExists(LText);
  end;
end;

procedure TfrmPrefs.acSelectExecute(Sender: TObject);
begin
  if FileOpenDialog1.Execute then
  begin
    self.edPath.Text := FileOpenDialog1.FileName;
  end;
end;

procedure TfrmPrefs.FormCreate(Sender: TObject);
begin
  edPath.Text := ReadRegPath;
end;

end.
