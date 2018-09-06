
unit hexmgr_ideutils_reg;

interface

uses ToolsAPI, Windows, Sysutils, classes, menus, forms, controls;

type

  THexWizard = class(TNotifierObject, IOTAMenuWizard, IOTAWizard)
  var
    FItem:  TMenuItem;
    Procedure HandleKeyGenClicked(Sender:TObject);
    Procedure HandleAboutClicked(Sender:TObject);
  public
	  function GetIDString: string;
	  function GetName: string;
	  function GetState: TWizardState;
	  procedure Execute;
	  function GetMenuText: string;
    Constructor Create;Virtual;
    Destructor  Destroy;Override;
  end;


procedure Register;

//function  ExecuteAndWait(const aApp, aCmdLine:string; aWait:boolean=true):DWORD;
function ExecuteAndWait(CommandLine: string): DWord;



implementation


uses formAbout;


Constructor THexWizard.Create;
Var
  NTAS : INTAServices;
  mTemp:  TMenuItem;
begin
  inherited;

  NTAS := (BorlandIDEServices As INTAServices);
  if assigned(NTAS) and (NTAS.MainMenu<>NIL) then
  Begin
    FItem:=TMenuItem.Create(NIL);
    FItem.Caption:='Hex License';
    NTAS.MainMenu.Items.Add(FItem);

    mTemp:=TMenuItem.Create(NIL);
    mtemp.Caption:='Key generator';
    mtemp.OnClick:=HandleKeyGenClicked;
    FItem.Add(mTemp);

    mTemp:=TMenuItem.Create(NIL);
    mtemp.Caption:='About this product';
    mtemp.OnClick:=HandleAboutClicked;
    FItem.Add(mTemp);
  end;
end;

Destructor THexWizard.Destroy;
Begin
  If FItem<>NIl then
  FItem.Free;
  inherited;
end;

procedure THexWizard.HandleKeyGenClicked(Sender:TObject);
(* var
  mForm:  TfrmMain; *)
var
  LForm: TfrmPrefs;
  LPath: string;
  LContinue: boolean;
begin
  LContinue := true;

  try
    LPath := ReadRegPath;
  except
    on e: exception do;
  end;

  LPath := trim(LPath);
  if (LPath = '')
  or (FileExists(LPath)=false) then
  begin
    LForm := TfrmPrefs.Create(NIL);
    LForm.Position:=TPosition.poMainFormCenter;
    try
      LContinue := (LForm.ShowModal = mrOK);
      if LContinue then
      LPath := trim(ReadRegPath);
    finally
      LForm.Free;
    end;
  end;

  if LContinue then
  begin
    ExecuteAndWait(LPath);
  end;
end;

Procedure THexWizard.HandleAboutClicked(Sender:TObject);
var
  mText:  String;
Begin
  mText:='HexLicense Components' + #13
    + 'Written by Jon Lennart Aasenden' + #13
    + 'Copyright Lauritz Computing LTD 2016' + #13
    + 'All rights reserved' + #13;
    application.MessageBox(PChar(mText),'Hex license manager',0);
end;

procedure THexWizard.Execute;
begin
  HandleAboutClicked(self);
end;

function THexWizard.GetIDString: string;
begin
  Result := 'Hex.Licence.Manager.IDEUtils';
end;

function THexWizard.GetMenuText: string;
begin
  Result := '&About License Manager components';
end;

function THexWizard.GetName: string;
begin
  Result := 'About.License.Manager.Components';
end;

function THexWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

function ExecuteAndWait(CommandLine: string): DWORD;
var
  si: TStartupInfo;
  pi: TProcessInformation;
  iRet: Integer;
begin
  UniqueString(CommandLine);
  si := Default(TStartupInfo);
  si.cb := SizeOf(si);
  Win32Check(CreateProcess(nil, PChar(CommandLine), nil, nil, False,
    NORMAL_PRIORITY_CLASS, nil, nil, si, pi));
  CloseHandle(pi.hThread);
  try
    while True do
    begin
      iRet := MsgWaitForMultipleObjects(1, pi.hProcess, False, INFINITE, QS_ALLINPUT);
      Win32Check(iRet <> WAIT_FAILED);
      case iRet of
      WAIT_OBJECT_0:
        break;
      WAIT_OBJECT_0+1:
        Application.ProcessMessages;
      end;
    end;
    Win32Check(GetExitCodeProcess(pi.hProcess, Result));
  finally
    CloseHandle(pi.hProcess);
  end;
end;

procedure Register;
begin
  RegisterPackageWizard(THexWizard.Create);
end;

end.
