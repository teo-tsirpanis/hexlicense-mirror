unit hexmgrlicense;

{$I vcl.hexlicense.inc}

interface

uses
  {$IFDEF USE_NEW_UNITNAMES}
  hexbuffers,
  Winapi.Windows, System.SysUtils, System.classes, System.Variants,
  Vcl.Controls, System.dateutils, VCL.graphics, System.Win.Registry;
  {$ELSE}
  hexbuffers,
  sysutils, classes, variants, controls, dateutils, graphics, windows, registry;
  {$ENDIF}

const
  CNT_HEXLICENSE_MAJOR    = 1;
  CNT_HEXLICENSE_MINOR    = 0;
  CNT_HEXLICENSE_REVISION = 1;

  {$IFDEF SUPPORT_PIDS}
  CNT_ALL_PLATFORMS = 0
    {$IFDEF SUPPORT_WIN32} + pidWin32 {$ENDIF}
    {$IFDEF SUPPORT_WIN64} + pidWin64 {$ENDIF}
    ;
  {$ENDIF}

type

  //###########################################################################
  // Forward declarations
  //###########################################################################

  THexCustomLicenseStorage    = class;
  THexOwnerLicenseStorage     = class;
  THexNumberSequence          = class;
  THexFileLicenseStorage      = class;
  THexSerialGenerator         = class;
  THexSerialMatrix            = class;
  THexSerialNumber            = class;

  //###########################################################################
  // Exception classes
  //###########################################################################

  EHexLicense                         = class(Exception);          (* License *)
  EHexLIcenseSerializationState       = class(EHexLicense);        (* License *)
  EHexLicenseEditingOnlyInDesignMode  = class(EHexLicense);        (* License *)
  EHexLicenseEditingOnlyRuntime       = class(EHexLicense);        (* License *)
  EHexLicenseDurationInvalid          = class(EHexLicense);        (* License *)
  EHexLicenseSessionNotActive         = class(EHexLicense);        (* License *)
  EHexLicenseDataIONotReady           = class(EHexLicense);        (* License *)
  EHexLicenseAlreadyRegistered        = class(EHexLicense);        (* License *)
  EHexLicenseSerialDecoderNotAssigned = class(EHexLicense);        (* License *)
  EHexLicenseInvalidSerialNumber      = class(EHexLicense);        (* License *)

  EHexLicenceStorage                  = class(EHexLicense);        (* Storage *)
  EHexLicenseWriteFailed              = class(EHexLicenceStorage); (* Storage *)
  EHexLicenseReadFailed               = class(EHexLicenceStorage); (* Storage *)
  EHexLicenseMatrixNotReady           = class(EHexLicenceStorage); (* Storage *)
  EHexLicenseMatrixFailed             = class(EHexLicenceStorage); (* Storage *)
  EHexLicenseVerifyFailed             = class(EHexLicenceStorage);

  EHexSerialNumber                    = class(EHexLicense);        (* Serial *)
  EHexSerialMatrixNotReady            = class(EHexSerialNumber);   (* Serial *)
  EHexSerialMatrixFailed              = class(EHexSerialNumber);   (* Serial *)

  //###########################################################################
  // Datatypes
  //###########################################################################

  THEXLicenseType   = (ltDayTrial,ltRunTrial,ltFixed);
  THexLicenseState  = (lsPending,lsExpired,lsValid,lsError);
  THexKeyMatrix     = packed Array[0..11] of byte;

  { Data record }
  THexLicenseRecord = packed record
    Magic:        LONGWORD;
    { defined when first created }
    lrLicBuildt:    TDateTime;
    lrBought:       TDateTime;

    { Definable properties }
    lrKind:         THexLicenseType;
    lrDuration:     integer;
    lrUsed:         integer;
    lrProvider:     string;
    lrSoftware:     string;
    lrFixedStart:   TDateTime;
    lrFixedEnd:     TDateTime;

    { Runtime properties }
    lrLastRun:      TDateTime;
    lrState:        THexLicenseState;
    lrSerialnumber: string;
  End;

  //###########################################################################
  // Event declarations
  //###########################################################################

  { Events for license }
  THexBeforeLicenseLoadedEvent   =  procedure (Sender: TObject) of object;
  THexAfterLicenseLoadedEvent    =  procedure (Sender: TObject) of object;
  THexBeforeLicenseUnLoadedEvent =  procedure (Sender: TObject) of object;
  THexAfterLicenseUnloadedEvent  =  procedure (Sender: TObject) of object;
  THexLicenseExpiredEvent        =  procedure (Sender: TObject) of object;
  THexLicenseBeginsEvent         =  procedure (Sender: TObject) of object;
  THexLicenseObtainedEvent       =  procedure (Sender: TObject) of object;
  THexLicenseCountdownEvent      =  procedure (Sender: TObject; Value: integer) of object;
  THexWarnDebuggerEvent          =  procedure (sender: TObject) of object;

  { Events for storage }
  THexWriteLicenseEvent          =  procedure (sender: TObject; Stream: TStream; var Failed: boolean) of object;
  THexReadLicenseEvent           =  procedure (Sender: TObject; Stream: TStream; var Failed: boolean) of object;
  THexDataExistsEvent            =  procedure (Sender: TObject; var Value:boolean) of object;
  { Events for KeyMatrix }
  THexGetKeyMatrixEvent          =  procedure (Sender: TObject; var Value: THexKeyMatrix) of object;
  { Events for serialnumber }
  THexSerialNumberAvailableEvent =  procedure (Sender: TObject; Value: string; var Accepted: boolean) of object;

  //###########################################################################
  // Interface declarations
  //###########################################################################

  { Access interface for THexLicense }
  IHexLicenseStorage = Interface
    ['{894A9A51-6287-48BB-B6B3-6B195123DB02}']
    procedure ReadData(Stream: TStream; var Failed: boolean);
    procedure WriteData(Stream: TStream; var Failed: boolean);
    function  DataExists: boolean;
    function  Ready: boolean;
  end;

  { Access interface for THexCustomLicenseStorage}
  IHexSerialMatrix = Interface
    ['{D562EC1E-6254-45E6-87C7-18CF16CF84B3}']
    function GetSerialMatrix(var Value: THexKeyMatrix): boolean;
  end;

  //###########################################################################
  // Components
  //###########################################################################

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexLicense = class(TComponent)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FActive:          boolean;
    FDurationLeft:    integer;
    FData:            THexLicenseRecord;
    FStorage:         THexCustomLicenseStorage;
    FSerial:          THexSerialNumber;

    FOnBeforeUnload:  THexBeforeLicenseUnLoadedEvent;
    FOnAfterUnLoad:   THexAfterLicenseUnloadedEvent;
    FOnCountDown:     THexLicenseCountdownEvent;
    FOnObtained:      THexLicenseObtainedEvent;
    FOnBefore:        THexBeforeLicenseLoadedEvent;
    FOnBegins:        THexLicenseBeginsEvent;
    FOnAfter:         THexAfterLicenseLoadedEvent;
    FOnEnds:          THexLicenseExpiredEvent;
    FOnWarning:       THexWarnDebuggerEvent;

    function    LicenseDataExists: boolean;
    procedure   ReadLicenseData;
    procedure   WriteLicenseData;
    function    CanReadWrite: boolean;
    procedure   StoreLicenseType(value: THexLicenseType);
    procedure   StoreDuration(Value: integer);
    procedure   SetFixedStartDate(Value: TDateTime);
    procedure   SetFixedEndDate(Value: TDateTime);
    procedure   ResetLicenseInformation;
    function    GetSerialNumber: string;
    procedure   UpdateSession;

    procedure   SetStorage(Value: THexCustomLicenseStorage);
    procedure   SetSerialnrclass(Value: THexSerialNumber);
    procedure   CheckSerialNumber(Const Value: string);

    function    GetProvider: string;
    procedure   SetProvider(Value: string);
    function    GetSoftware: string;
    procedure   SetSoftware(Value: string);
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    procedure   DoLicenseBegins;virtual;
    procedure   DoLicenseExpired;virtual;
    procedure   DoBeforeLoaded;virtual;
    procedure   DoAfterLoaded;virtual;
    procedure   DoCountDown;virtual;
    procedure   DoBeforeUnLoaded;virtual;
    procedure   DoAfterUnloaded;virtual;
    procedure   BootFirstTime;virtual;
    procedure   BootContinued;virtual;
  public
    property    Active: boolean read FActive;
    property    Serialkey: string read GetSerialNumber;
    property    LicenseState: THexLicenseState read FData.lrState;
    property    LastExecuted: TDateTime read FData.lrLastRun;
    property    DurationLeft: integer read FDurationLeft;
    property    Bought:TDateTime read FData.lrBought;

    procedure   BeginSession;
    procedure   EndSession;

    class function GetVersionText: string;

    function    Execute: boolean;
    procedure   Buy(const aSerialNumber: string);

    procedure   Notification(AComponent: TComponent; Operation: TOperation);override;
    procedure   BeforeDestruction;override;
    procedure   Loaded;override;
    Constructor Create(AOwner: TComponent);override;
  published
    property Storage: THexCustomLicenseStorage read FStorage write SetStorage;
    property SerialNumber: THexSerialNumber read FSerial write SetSerialnrclass;
    property License: THexLicenseType read FData.lrKind write StoreLicenseType stored true;
    property Duration: integer read FData.lrDuration write StoreDuration stored true;
    property Provider: string read Getprovider write SetProvider stored true;
    property FixedStart: TDateTime read FData.lrFixedStart write SetFixedStartDate stored true;
    property FixedEnd: TDateTime read FData.lrFixedEnd write SetFixedEndDate stored true;
    property Software: string read GetSoftware write SetSoftware stored true;

    property WarnDebugger: THexWarnDebuggerEvent read FOnWarning write FOnWarning;

    property OnLicenseObtained: THexLicenseObtainedEvent read FOnObtained write FOnObtained;
    property OnBeforeLicenseLoaded: THexBeforeLicenseLoadedEvent read FOnBefore write FOnBefore;
    property OnAfterLicenseLoaded: THexAfterLicenseLoadedEvent read FOnAfter write FOnAfter;
    property OnLicenseBegins: THexLicenseBeginsEvent read FOnBegins write FOnBegins;
    property OnLicenseExpires: THexLicenseExpiredEvent read FOnEnds write FOnEnds;
    property OnBeforeLicenseUnLoaded: THexBeforeLicenseUnLoadedEvent read FOnBeforeUnload write FOnBeforeUnload;
    property OnAfterLicenseUnLoaded: THexAfterLicenseUnloadedEvent read FOnAfterUnLoad write FOnAfterUnLoad;
    property OnLicenseCountDown: THexLicenseCountdownEvent read FOnCountDown write FOnCountDown;
  End;

  THexNumberSequence = class
  {$IFDEF SUPPORT_SEALED} sealed {$ENDIF} (TObject)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FValue:   Byte;
    FKey:     Byte;
    FValues:  Array[0..63] of Byte;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    procedure SetKey(Value: Byte);
    function  GetLockToQuadrant: boolean;
  public
    property  MatrixElement: Byte read FKey write SetKey;
    property  Lock: boolean read GetLockToQuadrant;
    procedure AlignToLock;
    procedure Grow(Value: Byte);
    function  Validate(Value: Byte): boolean;
    function  Value: Byte;
  End;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexSerialNumber = class(TComponent)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FMatrix:  THexSerialMatrix;
    FGrowthRings: Array[0..11] of THexNumberSequence;
    procedure SetMatrix(Value: THexSerialMatrix);
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    procedure   LoadMatrix;
  public
    procedure   Spin;
    function    GetSerial:string;
    function    Validate(Serial:string):boolean;
    procedure   Clear;
    procedure   Notification(AComponent:TComponent;Operation:TOperation);override;
    constructor Create(AOwner:TComponent);override;
    destructor  Destroy;override;
  published
    property    SerialMatrix: THexSerialMatrix read FMatrix write SetMatrix;
  End;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexSerialGenerator = class(THexSerialNumber)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnAvailable: THexSerialNumberAvailableEvent;
  public
    procedure Generate(Count:integer); virtual;
  published
    property OnSerialnumberAvailable: THexSerialNumberAvailableEvent
      read FOnAvailable write FOnAvailable;
  End;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexSerialMatrix = class(TComponent,IHexSerialMatrix)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnGetMatrix: THexGetKeyMatrixEvent;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    function  GetSerialMatrix(var Value:THexKeyMatrix):boolean;
  published
    property  OnGetKeyMatrix:THexGetKeyMatrixEvent
              read FOnGetMatrix write FOnGetMatrix;
  end;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexCustomLicenseStorage = class(TComponent, IHexLicenseStorage)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnRead:  THexReadLicenseEvent;
    FOnWrite: THexWriteLicenseEvent;
    FOnExists:  THexDataExistsEvent;
    FMatrix:  THexSerialMatrix;
    FEncryption: THexEncoder;

    procedure SetMatrix(Value:THexSerialMatrix);
    procedure SetEncryption(NewEncoder: THexEncoder);
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    function CanEncode:boolean;

    (* IMPLEMENTS: IHexLicenseStorage *)
    procedure ReadData(Stream: TStream; var Failed: boolean);virtual;
    procedure WriteData(Stream: TStream; Var Failed: boolean);virtual;
    function DataExists:boolean;virtual;
    function Ready:boolean;Virtual;
  public
    procedure Notification(AComponent: TComponent;
        Operation: TOperation);Override;
  published
    property Encryption: THexEncoder read FEncryption write SetEncryption;
    property SerialMatrix: THexSerialMatrix read FMatrix write SetMatrix;
    property OnDataExists: THexDataExistsEvent Read FOnExists write FOnExists;
    property OnReadData:  THexReadLicenseEvent read FOnRead write FOnRead;
    property OnWriteData: THexWriteLicenseEvent read FOnWrite write FOnWrite;
  end;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexFileLicenseStorage = class(THexCustomLicenseStorage)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FName: TFilename;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    (* IMPLEMENTS: IHexLicenseStorage *)
    procedure ReadData(Stream: TStream;var Failed: boolean);override;
    procedure WriteData(Stream: TStream;var Failed: boolean);override;
    function  DataExists: boolean;override;
    function  Ready: boolean;Override;
  public
    Constructor Create(AOwner:TComponent);override;
  published
    property FileName: TFilename read FName write FName stored true;
  End;

  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  THexOwnerLicenseStorage = class(THexCustomLicenseStorage)
  end;

implementation

uses hexmgrlicenseform;

//###########################################################################
// Exception message resource strings
//###########################################################################

resourcestring
ERR_HEX_LicenseEditingOnlyInDesignMode =
'License editing can only be performed during application design';

ERR_HEX_LicenseEditingOnlyRuntime =
'License editing for this property is only available at runtime';

ERR_HEX_LicenseDurationInvalid =
'License duration is invalid';

ERR_HEX_LicenseSessionNotActive =
'License session not active';

ERR_HEX_LicenseDataIONotReady =
'No license I/O component is connected';

ERR_HEX_LicenseAlreadyRegistered =
'License already registerd';

ERR_HEX_LicenseSerialDecoderNotAssigned =
'License serial decoder not assigned';

ERR_HEX_licenseInvalidSerialNumber =
'License serial number is invalid';

ERR_HEX_LicenseStateInvalidSerialization =
'Invalid license state for serialization';

ERR_HEX_FailedReadLicenseInformation =
'Failed to read license information error';

ERR_HEX_FailedWriteLicenseInformation =
'Failed to write license information error';

ERR_HEX_FailedVerifyLicenseInformation =
'License file failed to verify error';

{ Exception constants }
ERR_HEX_LicenseWriteFailed =
'Failed to write license information';

ERR_HEX_LicenseReadFailed =
'Failed to read license information';

ERR_HEX_LicenseMatrixNotReady =
'Data serial matrix not connected';

ERR_HEX_LicenseMatrixFailed =
'Failed to obtain serial matrix values';

(* DIALOG CONSTANTS *)
const
CNT_DAYS        = ' days';
CNT_RUNS        = ' runs';
CNT_DAYSLEFT    = CNT_DAYS + ' left';
CNT_RUNSLEFT    = CNT_RUNS + ' left';
CNT_Licensed    = 'Licensed';
CNT_EXPIRED     = 'EXPIRED';

CNT_LIC_HEADER  = $ABBABABE;

//###########################################################################
// THexLicense
//###########################################################################

Constructor THexLicense.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);

  { Reset data segment }
  With FData do
  Begin
    Magic := CNT_LIC_HEADER;
    lrLicBuildt := Now;
    lrBought := 0;
    lrFixedStart := Now;
    lrFixedEnd := Now + 14;
    lrLastRun := Now;
    lrSerialNumber := '';
    lrState := lsPending;
    lrSoftware := 'My application name';
    lrProvider := 'My company name';
    lrDuration := 30;
    lrused := 0;
  end;
End;

class function THexLicense.GetVersionText: string;
begin
  result:=format('%d.%d.%d',
    [CNT_HEXLICENSE_MAJOR,
    CNT_HEXLICENSE_MINOR,
    CNT_HEXLICENSE_REVISION]);
end;

procedure THexLicense.BeforeDestruction;
Begin
  { if session is active then close down }
  If Active then
    EndSession;
  inherited;
End;

procedure THexLicense.Loaded;
Begin
  inherited;

  (* if not (csDesigning in ComponentState) then
  begin
    { if automatic start failed, re-raise exception }
    try
      BeginSession;
    except
      on exception do
      raise;
    end;
  end;  *)
End;

procedure THexLicense.Notification(AComponent:TComponent;Operation:TOperation);
Begin
  inherited Notification(AComponent,Operation);

  If (AComponent is THexCustomLicenseStorage) then
  begin
    Case Operation of
    opRemove: SetStorage(NIL);
    opInsert: SetStorage(THexCustomLicenseStorage(AComponent));
    end;
    exit;
  end;

  if (AComponent is THexSerialNumber) then
  begin
    Case Operation of
    opRemove: SetSerialnrclass(NIL);
    opInsert: SetSerialnrclass(THexSerialNumber(AComponent));
    end;
  end;
End;

function THexLicense.LicenseDataExists: boolean;
Begin
  { Check that we can read and write }
  If not CanReadWrite then
  raise EHexLicenseDataIONotReady.Create(ERR_Hex_LicenseDataIONotReady);

  { return license-storage dataexists }
  try
    result:=IHexLicenseStorage(FStorage).DataExists;
  except
    on exception do
    raise;
  end;
End;

procedure THexLicense.ReadLicenseData;
var
  LFailed:  boolean;
  mAccess:  IHexLicenseStorage;
  LRecord:  THexBufferMemory;
  LReader:  THexReaderBuffer;
  LStream:  THexStreamAdapter;
Begin
  if not (csDestroying in ComponentState) then
  begin
    // Only if we can read & write
    if CanReadWrite() then
    begin
      // setup in-memory buffer
      LRecord := THexBufferMemory.Create(nil);
      try
        // Write data
        LReader := THexReaderBuffer.Create(LRecord);
        try
          LStream := THexStreamAdapter.Create(LRecord);
          try

            { Reset failed flag }
            LFailed := false;

            // Request the data from our storage-device
            if FStorage.GetInterface(IHexLicenseStorage, mAccess) then
            Begin
              try
                mAccess.ReadData(LStream, LFailed);
              except
                on exception do
                Raise;
              end;
            end else
            raise EHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);

            { did read operation fail? }
            if not LFailed then
            begin

              // Check signature
              if LReader.ReadLong = CNT_LIC_HEADER then
              begin
                // OK, read in the data

                try
                  FData.Magic := CNT_LIC_HEADER;
                  FData.lrLicBuildt := LReader.ReadDateTime();
                  FData.lrBought := LReader.ReadDateTime();
                  FData.lrKind :=  THexLicenseType( LReader.ReadInt );
                  FData.lrDuration := LReader.ReadInt;
                  FData.lrUsed := LReader.ReadInt;
                  FData.lrProvider := LReader.ReadString;
                  FData.lrSoftware := LReader.ReadString;
                  FData.lrFixedStart := LReader.ReadDateTime;
                  FData.lrFixedEnd := LReader.ReadDateTime;
                  FData.lrLastRun := LReader.ReadDateTime;
                  FData.lrState :=  THexLicenseState( LReader.ReadInt );
                  FData.lrSerialnumber := LReader.ReadString;
                except
                  on e: exception do
                  raise EHexLicenseVerifyFailed.Create(ERR_HEX_FailedVerifyLicenseInformation)
                end;
              end else
              raise EHexLicenseVerifyFailed.Create(ERR_HEX_FailedVerifyLicenseInformation)
            end else
            raise EHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);

          finally
            LStream.Free;
          end;
        finally
          LReader.Free;
        end;
      finally
        LRecord.Free;
      end;

    end else
    raise EHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
  end;
end;

procedure THexLicense.WriteLicenseData;
var
  LFailed:  boolean;
  mAccess:  IHexLicenseStorage;
  LRecord:  THexBufferMemory;
  LWriter:  THexWriterBuffer;
  LStream:  THexStreamAdapter;
begin
  // Not if terminating
  if not (csDestroying in ComponentState) then
  begin
    // Only if we can read & write
    if CanReadWrite() then
    begin
      // setup in-memory buffer
      LRecord := THexBufferMemory.Create(nil);
      try
        // Write data
        LWriter := THexWriterBuffer.Create(LRecord);
        try
          LWriter.WriteLong(FData.Magic);
          LWriter.WriteDateTime(FData.lrLicBuildt);
          LWriter.WriteDateTime(FData.lrBought);
          LWriter.WriteInt( ord(FData.lrKind) );
          LWriter.WriteInt( FData.lrDuration );
          LWriter.Writeint( FData.lrUsed );
          LWriter.Writestring( FData.lrProvider );
          LWriter.Writestring( FData.lrSoftware );
          LWriter.WriteDateTime( FData.lrFixedStart );
          LWriter.WriteDateTime( FData.lrFixedEnd );
          LWriter.WriteDateTime( FData.lrLastRun );
          LWriter.WriteInt( ord(FData.lrState) );
          LWriter.Writestring( FData.lrSerialnumber );

          // Setup stream access to the buffer
          LStream := THexStreamAdapter.Create(LRecord);
          try
            if FStorage.GetInterface(IHexLicenseStorage,mAccess) then
            begin
              LFailed := false;
              mAccess.WriteData(LStream, LFailed);
            end else
            raise EHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
          finally
            LStream.Free;
          end;

        finally
          LWriter.free;
        end;
      finally
        LRecord.Free;
      end;

    end else
    raise EHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
  end;
end;

Function THexLicense.Execute:Boolean;
{ var
  Info: THexLicenseInfo;  }
Begin
  result:=False;
  If not Active then
  exit;

  //if assigned(FOnDialog) then
  //FOnDialog(self,Info);

  With TfrmLicenseProperties.Create(NIL) do
  Begin
    try
      lbCreated.Caption:=DateToStr(FData.lrLicBuildt);
      lbSoftware.Caption:=FData.lrSoftware;
      lbProvider.Caption:=FData.lrProvider;

      Case FData.lrKind of
      ltDayTrial:
        Begin
          lbDuration.Caption:=IntToStr(FData.lrDuration) + CNT_DAYS;
          lbExpires.Caption:=DateToStr(IncDay(FData.lrLicBuildt,FData.lrDuration));
        end;
      ltRunTrial: lbDuration.Caption:=IntToStr(FData.lrDuration) + CNT_RUNS;
      ltFixed:  lbExpires.Caption:=DateToStr(FData.lrFixedEnd);
      End;

      case FData.lrKind of
      ltDayTrial: lbLeft.Caption:=IntToStr(FDurationLeft) + CNT_DAYSLEFT;
      ltRunTrial: lbLeft.Caption:=IntToStr(FDurationLeft) + CNT_RUNSLEFT;
      ltFixed:    lbLeft.Caption:=IntToStr(FDurationLeft) + CNT_DAYSLEFT;
      end;

      nProgress.Max:=FData.lrDuration;
      nProgress.Position:=FDurationLeft;

      If LicenseState=lsValid then
      begin
        lbDuration.Caption:=cnt_Licensed;
        lbExpires.Caption:=cnt_Licensed;
        btnRegister.Enabled:=False;
        edKeyCode.enabled:=False;
        edKeyCode.color:=clBtnface;
        lbleft.caption:='Registered';
      end;

      if LicenseState=lsExpired then
      Begin
        lbDuration.Caption:=CNT_EXPIRED;
        lbLeft.Caption:=CNT_EXPIRED;
      end;

      if ShowModal=mrOK then
      Begin
        { Register pressed, now attempt to
          register the serial number }
        try
          Buy(edKeyCode.text);
        except
          on exception do
          begin
            Result:=False;
            exit;
          end;
        end;
        Result:=True;
      end;
    finally
      Free;
    end;
  end;
End;

procedure THexLicense.BootFirstTime;
Begin
  DoBeforeLoaded;

  { populate standard data }
  FData.lrLastRun:=Now;
  FData.lrBought:=0;
  FData.lrState:=lsPending;

  { Initialize storage }
  try
    WriteLicenseData;
  except
    on exception do
    begin
      FData.lrState:=lsError;
      raise;
      exit;
    end;
  end;

  { Notify user that the license begins }
  DoLicenseBegins;

  { Boot the data }
  try
    ReadLicenseData;
  except
    on exception do
    Begin
      FData.lrState:=lsError;
      raise;
    end;
  end;

  { Update session data }
  try
    UpdateSession;
  except
    on exception do
    Begin
      FData.lrState:=lsError;
      raise;
    end;
  end;

  { Have we expired? }
  If LicenseState=lsExpired then
  Begin
    { license has expired }
    //ResetLicenseInformation;
    FActive := True;
    DoLicenseExpired;
    if LicenseState=lsExpired then
    Begin
      //FActive:=False;
      //exit;
    end;
    //exit;
  End;

  { All ok, write the updated licensedata }
  try
    WriteLicenseData;
  except
    on exception do
    Begin
      raise;
      exit;
    end;
  end;

  { Everything is OK. We are now active }
  FActive:=True;
  DoAfterLoaded;
End;

procedure THexLicense.BootContinued;
Begin
  DoBeforeLoaded;

  FData.lrState:=lsPending;

  { Boot the data from storage }
  try
    ReadLicenseData;
  except
    on exception do
    Begin
      FData.lrState:=lsError;
      raise;
      exit;
    end;
  end;

  FActive:=True;

  { Valid serial, exit at this point }
  If FData.lrState=lsValid then
  exit;

  try
    UpdateSession;
  except
    on exception do
    Begin
      FActive:=False;
      FData.lrState:=lsError;
      raise;
      exit;
    end;
  end;

  { Have we expired? }
  if LicenseState=lsExpired then
  Begin
    { license has expired }
    FActive:=False;
    ResetLicenseInformation;
    DoLicenseExpired;

    //Note: The customer might invoke an execute to display the
    //      register dialog when the app has expired.
    //      Hence we re-check here
    if not (licensestate=lsValid) then
    exit;

    //application.Terminate;
    //exit;
  end;

  { Write updated data to storage }
  try
    WriteLicenseData;
  except
    on exception do
    Begin
      FActive:=False;
      FData.lrState:=lsError;
      raise;
      exit;
    end;
  end;

  DoCountDown;
  DoAfterLoaded;
End;

procedure THexLicense.BeginSession;
Begin
  { Already active? }
  if Active then
  exit;

  { notify user that we are accessing the session data }
  try
    Case LicenseDataExists of
    True:   BootContinued;
    False:  BootFirstTime;
    End;
  except
    on exception do
    raise;
  end;
End;

procedure THexLicense.EndSession;
begin
  { check that we can do this }
  If Not Active then
  exit;

  DoBeforeUnLoaded;

  { Write license data }
  try
    WriteLicenseData;
  except
    on e: exception do
    Begin
      FActive:=False;
      FDurationLeft:=0;
      ResetLicenseInformation;
      Raise;
      exit;
    end;
  end;

  FActive:=False;
  FDurationLeft:=0;
  ResetLicenseInformation;

  DoAfterUnLoaded;
End;

procedure THexLicense.ResetLicenseInformation;
Begin
  With FData do
  Begin
    lrLicBuildt:=Now;
    lrBought:=0;
    lrFixedStart:=Now;
    lrFixedEnd:=IncDay(Now,14);
    lrLastRun:=Now;
    lrSerialNumber:='';
    lrState:=lsPending;
    lrUsed:=0;
  end;
End;

procedure THexLicense.UpdateSession;
Begin
  { It is validated they say }
  If FData.lrState=lsValid then
  Begin
    { Validate the key }
    try
      CheckSerialNumber(trim(FData.lrSerialnumber));
    except
      on exception do
      begin
        FData.lrState:=lsExpired;
        FData.lrSerialnumber:='';
        exit;
      end;
    end;
  end;

  Case FData.lrKind of
  ltDayTrial:
    Begin
      FDurationLeft:=DaysBetween(now,FData.lrLicBuildt);
      If FDurationLeft>FData.lrDuration then
      FDurationLeft:=0 else
      FDurationLeft:=FData.lrDuration-FDurationLeft;
      FData.lrLastRun:=Now;
    End;
  ltRunTrial:
    Begin
      inc(FData.lrUsed);
      If FData.lrUsed>=FData.LrDuration then
      FData.lrUsed:=FData.lrDuration;
      FDurationLeft:=(FData.lrDuration-FData.lrUsed);
      FData.lrLastRun:=Now;
    End;
  ltFixed:
    Begin
      if (DateTimeInRange(now,FData.lrFixedStart,FData.lrFixedEnd) = false)
      or (CompareTime(now,FData.lrFixedStart) < 0 ) then
      Begin
        FDurationLeft:=0;
        FData.lrLastRun:=Now;
        FData.lrState:=lsExpired;
        exit;
      end;

      FDurationLeft:=DaysBetween(now,FData.lrFixedEnd);
      FData.lrLastRun:=Now;
    End;
  End;

  If (FDurationLeft>0) then
  FData.lrState:=lsPending else
  FData.lrState:=lsExpired
End;

procedure THexLicense.DoLicenseBegins;
Begin
  try
    if assigned(FOnBegins) then
    FOnBegins(Self);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoCountDown;
begin
  try
    if assigned(FOnCountDown) then
    FOnCountDown(self,FDurationLeft);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoLicenseExpired;
Begin
  try
    If assigned(FOnEnds) then
    FOnEnds(self);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoBeforeLoaded;
Begin
  try
    if assigned(FOnBefore) then
    FOnBefore(Self);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoAfterLoaded;
Begin
  try
    If assigned(FOnAfter) then
    FOnAfter(Self);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoBeforeUnLoaded;
Begin
  try
    If assigned(FOnbeforeUnLoad) then
    FOnBeforeUnload(Self);
  except
    on exception do;
  end;
End;

procedure THexLicense.DoAfterUnloaded;
Begin
  if assigned(FOnAfterUnLoad) then
  FOnAfterUnLoad(self);
End;

procedure THexLicense.CheckSerialNumber(Const Value:string);
Begin
  If not Active then
  raise EHexLicenseSessionNotActive.Create
  (ERR_HEX_LicenseSessionNotActive);

  { No serial number decoder installed? }
  If not Assigned(FSerial) then
  raise EHexLicenseSerialDecoderNotAssigned.Create
  (ERR_HEx_LicenseSerialDecoderNotAssigned);

  { A serial number is already present? }
  if length(trim(FData.lrSerialnumber))>0 then
  raise EHexLicenseAlreadyRegistered.Create
  (ERR_HEX_LicenseAlreadyRegistered);

  { Validate the serial number }
  If not FSerial.Validate(Value) then
  raise EHexLicenseInvalidSerialNumber.Create
  (ERR_HEX_LicenseInvalidSerialNumber);
End;

procedure THexLicense.Buy(Const aSerialNumber:string);
begin
  if (LicenseState in [lsPending,lsExpired]) then
  Begin

    { Validate that the serial number is OK }
    try
      CheckSerialNumber(aSerialNumber);
    except
      on exception do
      raise;
    end;

    { All ok. Insert the code into our data segment }
    FData.lrSerialnumber:=aSerialNumber;
    FData.lrBought:=Now;
    FData.lrState:=lsValid;

    (* Mark cycle as active *)
    FActive:=True;

    { Attempt to write the license data }
    try
      WriteLicenseData;
    except
      { Failed, reset last actions }
      on e: exception do
      Begin
        FData.lrSerialnumber:='';
        FData.lrState:=lsPending;
        FData.lrBought:=0;
        Raise;
        exit;
      end;
    end;

    { Notify host of change }
    if assigned(FOnObtained) then
    FOnObtained(self);

  end else
  Raise EHexLIcenseSerializationState.Create
  (ERR_HEX_LicenseStateInvalidSerialization);
end;

procedure THexLicense.StoreDuration(Value:integer);
begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);

  { Check that the duration value is valid }
  If (Value<1) then
  Raise EHexLicenseDurationInvalid.Create(ERR_HEX_LicenseDurationInvalid);

  FData.lrDuration:=value;
end;

procedure THexLicense.StoreLicenseType(value:THexLicenseType);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrKind:=Value;
End;

function THexLicense.GetProvider:string;
Begin
  result:=FData.lrProvider;
End;

procedure THexLicense.SetProvider(Value:string);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrProvider:=Value;
End;

procedure THexLicense.SetStorage(Value:THexCustomLicenseStorage);
Begin
  { we already have one }
  If assigned(FStorage) then
  FStorage.RemoveFreeNotification(self);

  FStorage:=Value;

  { Set free notification }
  If Assigned(FStorage) then
  FStorage.FreeNotification(self);
End;

procedure THexLicense.SetSerialNrClass(Value: THexSerialNumber);
Begin
  { we already have one }
  If assigned(FSerial) then
    FSerial.RemoveFreeNotification(self);

  FSerial:=Value;

  { Set free notification }
  If Assigned(FSerial) then
    FSerial.FreeNotification(self);
End;

function THexLicense.CanReadWrite:boolean;
Begin
  If assigned(FStorage) then
    result := IHexLicenseStorage(FStorage).Ready
  else
    result := False;
End;

procedure THexLicense.SetFixedStartDate(Value:TDateTime);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate) and
     not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
    (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrFixedStart:=Value;
End;

procedure THexLicense.SetFixedEndDate(Value:TDateTime);
Begin
  { Are we in runtime or designtime? }
  If  not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrFixedEnd:=Value;
End;

function THexLicense.GetSoftware:string;
Begin
  result:=FData.lrSoftware;
End;

procedure THexLicense.SetSoftware(Value:string);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrSoftware:=Value;
End;

function THexLicense.GetSerialNumber:string;
Begin
  result:=FData.lrSerialNumber;
End;


//############################################################
// THexFileLicenseStorage
//############################################################

Constructor THexFileLicenseStorage.Create(AOwner: TComponent);
Begin
  inherited Create(Aowner);
  FName:='lcdata.lcc';
End;

function THexFileLicenseStorage.Ready: boolean;
begin
  result:=assigned(SerialMatrix);
end;

procedure THexFileLicenseStorage.ReadData(Stream: TStream; var Failed: boolean);
var
  LFile:  TFileStream;
Begin
  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  If assigned(OnReadData) then
  begin
    inherited ReadData(Stream, Failed);
    exit;
  end;

  { Can we encode? }
  If not CanEncode then
  Begin
    Failed := true;
    Raise EHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
  end;

  { Does the data exist? }
  If not DataExists() then
  Begin
    Failed := True;
    exit;
  end;

  { open the file in question }
  try
    LFile := TFileStream.Create(FName,fmOpenRead);
  except
    on exception do
    begin
      Failed:=True;
      raise EHexLicenseReadFailed.Create(ERR_Hex_LicenseReadFailed);
    end;
  end;

  try
    Encryption.DecodeStream(LFile, Stream);
  finally
    LFile.Free;
  end;
end;

procedure THexFileLicenseStorage.WriteData(Stream: TStream; var Failed:boolean);
var
  FFile:    TFileStream;
Begin
  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  If assigned(OnWriteData) then
  begin
    inherited WriteData(Stream, Failed);
    exit;
  end;

  { Can we encode? }
  If not CanEncode then
  Begin
    Failed := true;
    Raise EHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
  end;

  { open the file in question }
  try
    FFile := TFileStream.Create(FName, fmCreate or fmOpenWrite);
  except
    on exception do
    Begin
      Failed := true;
      raise EHexLicenseWriteFailed.Create(ERR_Hex_LicenseWriteFailed);
    end;
  end;

  try
    Encryption.EncodeStream(Stream, FFile);
  finally
    FFile.Free;
  end;
end;

function THexFileLicenseStorage.DataExists:boolean;
Begin
  result:=False;

  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  If assigned(OnDataExists) then
  begin
    result:=inherited DataExists;
    exit;
  end;

  result:=FileExists(FName);
end;

//############################################################
// THexCustomLicenseStorage
//############################################################

procedure THexCustomLicenseStorage.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  inherited Notification(AComponent,Operation);
  If (AComponent is THexSerialMatrix) then
  begin
    case Operation of
    opRemove: SetMatrix(NIL);
    opInsert: SetMatrix(THexSerialMatrix(AComponent));
    end;
  end else
  if (AComponent is THexEncoder) then
  begin
    case Operation of
    opRemove: SetEncryption(NIL);
    opInsert: SetEncryption(THexEncoder(AComponent));
    end;
  end;
End;

function THexCustomLicenseStorage.CanEncode:boolean;
Begin
  result := Assigned(FMatrix);
End;

procedure THexCustomLicenseStorage.WriteData(Stream: TStream; var Failed: boolean);
var
  LTemp: TMemoryStream;
Begin
  Failed := not assigned(OnWriteData);
  if not Failed then
  begin
    LTemp := TMemoryStream.Create;
    try
      Encryption.EncodeStream(Stream, LTemp);
      LTemp.Position := 0;

      OnWriteData(self, LTemp, Failed);
    finally
      LTemp.Free;
    end;
  end;
End;

procedure THexCustomLicenseStorage.ReadData(Stream: TStream; var Failed: boolean);
var
  LTemp: TMemoryStream;
begin
  Failed := not assigned(OnReadData);
  if not Failed then
  begin
    LTemp := TMemoryStream.Create;
    try
      OnReadData(self, LTemp, Failed);

      if not Failed then
      begin
        LTemp.Position := 0;
        Encryption.DecodeStream(LTemp, Stream);
      end;

    finally
      LTemp.Free;
    end;
  end;
End;

function THexCustomLicenseStorage.DataExists: boolean;
Begin
  if assigned(FOnExists) then
    FOnExists(self, result)
  else
    result := false;
End;

{ purpose:
  Checks to see if the component is ready to
  forfill it's task. }
function THexCustomLicenseStorage.Ready:boolean;
Begin
  result := false;
  if assigned(FMatrix) then
  begin
    if assigned(OnReadData) then
    begin
      if assigned(OnWriteData) then
      begin
        result := true;
      end;
    end;
  end;
End;

procedure THexCustomLicenseStorage.SetEncryption(NewEncoder: THexEncoder);
begin
  if assigned(FEncryption) then
    FEncryption.RemoveFreeNotification(self);

  FEncryption := NewEncoder;

  if assigned(FEncryption) then
    FEncryption.FreeNotification(self);
end;

procedure THexCustomLicenseStorage.SetMatrix(Value:THexSerialMatrix);
Begin
  { we already have one }
  If assigned(FMatrix) then
  FMatrix.RemoveFreeNotification(self);

  FMatrix:=Value;

  { Set free notification }
  If Assigned(FMatrix) then
  FMatrix.FreeNotification(self);
End;

//###########################################################################
// THexSerialMatrix
//###########################################################################

{ Simply returns a default serial matrix.
  The user can override this by assigning their own event code }
function THexSerialMatrix.GetSerialMatrix(var Value:THexKeyMatrix):boolean;
Const
  AMatrix: THexKeyMatrix = ($89,$C8,$82,$13,$D3,$86,$00,$98,$AF,$D3,$D5,$F2);
Begin
  { user defined? }
  If assigned(FOnGetMatrix) then
  Begin
    FOnGetMatrix(self,value);
    result:=True;
    exit;
  end;
  { user has not (4 some veird reason) populated the event,
    return the default }
  value:=AMatrix;
  result:=True;
End;

//###########################################################
// THexSerialGenerator
//###########################################################

procedure THexSerialGenerator.Generate(Count: integer);
var
  x:        integer;
  FAccepted:  boolean;
Begin
  LoadMatrix;

  for x:=1 to Count do
  begin
    FAccepted:=False;
    if assigned(FOnAvailable) then
    Begin
      While FAccepted=False do
      Begin
        Spin;
        FOnAvailable(self,GetSerial,FAccepted);
      end;
    end;
  end;
end;

//###########################################################
// THexSerialNumber
//###########################################################

Constructor THexSerialNumber.Create(AOwner:TComponent);
var
  x:  integer;
begin
  inherited Create(AOwner);
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x] := THexNumberSequence.Create;
  end;
End;

Destructor THexSerialNumber.Destroy;
var
  x:  integer;
Begin
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    if FGrowthRings[x] <> nil then
    begin
      FGrowthRings[x].Free;
      FGrowthRings[x] := nil;
    end;
  end;
  Inherited;
End;

procedure THexSerialNumber.Notification(AComponent:TComponent;Operation:TOperation);
Begin
  inherited Notification(AComponent,Operation);
  If (AComponent is THexSerialMatrix) then
  begin
    Case Operation of
    opRemove: SetMatrix(nil);
    opInsert: SetMatrix(THexSerialMatrix(AComponent));
    end;
  end;
end;

procedure THexSerialNumber.SetMatrix(Value:THexSerialMatrix);
Begin
  { we already have one }
  If assigned(FMatrix) then
  begin
    FMatrix.RemoveFreeNotification(self);
    FMatrix := nil;
  end;

  if Value <> FMatrix then
  begin
    FMatrix:=Value;
    If Assigned(FMatrix) then
    FMatrix.FreeNotification(self);
  end;
End;

procedure THexSerialNumber.LoadMatrix;
var
  x:      integer;
  LData:  THexKeyMatrix;
  LAccess: IHexSerialMatrix;
Begin
  { check that matrix is there }
  If not assigned(FMatrix) then
  begin
    raise EHexSerialMatrixNotReady.Create(ERR_Hex_LicenseMatrixNotReady);
    exit;
  end;

  if FMatrix.GetInterface(IHexSerialMatrix, LAccess) then
  Begin
    if not LAccess.GetSerialMatrix(LData) then
    Raise EHexLicenseMatrixFailed.Create(ERR_HEX_LicenseMatrixFailed);
  end else
  Raise EHexLicenseMatrixFailed.Create(ERR_Hex_LicenseMatrixNotReady);

  { Load values into wheels }
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x].MatrixElement := LData[x];
  end;
End;

procedure THexSerialNumber.Clear;
var
  x:  integer;
Begin
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x].MatrixElement:=0;
  end;
End;

function THexSerialNumber.GetSerial: string;
var
  LText:  string;
  x:  integer;
  y:  integer;
Begin
  y:=1;
  for x := low(FGrowthRings) to high(FGrowthRings) do
  begin
    LText:=LText + IntToHex(FGrowthRings[x].Value, 2);
    inc(y);
    If (y = 4) then
    begin
      If (x < 11) then
      LText:=LText + '-';
      y:=1;
    end;
  end;
  result:=LText;
End;

procedure THexSerialNumber.Spin;
var
  x:      integer;
  LValue: integer;
  LRightIndex: integer;
begin
  { make sure matrix is loaded }
  try
    LoadMatrix;
  except
    on exception do
    Begin
      raise;
      exit;
    end;
  end;

  // By fetching bytes from each extreme edge of the serial
  // string, we form the number that must be balanced by natures forces.
  // This is exactly like plants do to balance themselves no matter how
  // high or large they grow. The principle of Amun (known in our age
  // as the fibbonaci formula. Its actually ancient.
  for x := low(FGrowthRings) to high(FGrowthRings) do
  Begin
    Randomize;
    LValue:=0;

    // Build the pillar of hercules
    while (LValue<1) do
    begin
      LRightIndex := high(FGrowthRings) - x;
      LValue := Random(FGrowthRings[LRightIndex].MatrixElement) + random(FGrowthRings[x].MatrixElement);
      If (LValue > 255)
      or (LValue = 0) then
      Begin
        LValue:=0;
        Continue;
      end;
    end;

    // Now send the number through the Lucas-number sequence
    FGrowthRings[x].Grow(LValue);

    // And bring balance to the force
    FGrowthRings[x].AlignToLock;
  end;
End;

function THexSerialNumber.Validate(Serial:string):boolean;
var
  x:      integer;
  LValue: integer;
  LLock:  integer;
Begin
  LoadMatrix;

  { clean up serial }
  Serial := stringReplace(Serial, '-', '', [rfReplaceAll]);
  Serial := trim(serial);

  { validate length }
  if length(Serial) <> 24 then
  Begin
    result:=False;
    exit;
  end;

  LLock:=0;

  // Validate that each number can be found within the growth
  // rings they originated from. If they cannot be found or
  // are inaccurate, they can not have been produced by the
  // initial root key.
  for x := low(FGrowthRings) to high(FGrowthRings) do
  begin
    LValue:=StrToInt('$' + Copy(Serial,1,2));
    delete(Serial,1,2);
    if FGrowthRings[x].Validate(LValue) then
    inc(LLock);
  end;

  Result:=(LLock = length(FGrowthRings) );
end;

//###########################################################
// THexNumberSequence
//###########################################################

(* Notes:
   The lucas number sequence is closely tied to the Fibonacci growth
   formula: 2, 1, 3, 4, 7, 11, 18, 29, 47, 76

   In order to provoke growth I introduce a top range of 64 (0..63) ceil.
   This means that a maximum of 64 variations can occur within a single
   turn of the growth-ring [64 | 64 | 64 | 64], 4 quadrants that through
   256 permutations must contain the number *)

const
  CNT_LUCAS_IRRATIONALE  = 63;

procedure THexNumberSequence.SetKey(Value: byte);
var
  LHoly:  integer;
  x:      integer;
  LValue: integer;
  LTemp:  string;
Begin
  FKey:=Value;
  FValue:=Value;

  LTemp := IntToHex(FKey,2);

  // Sum previous with next A <--> B = Seed
  // Note: The limit here will be 256 combinations
  // hence the upper ceiling of 64 (64 <-> 128 <-> 256)
  // that forms the 4 corners of the seed stone in the temple
  LHoly := StrToInt('$' + Copy(Ltemp, 1, 1));
  LHoly := LHoly + StrToInt('$' + Copy(Ltemp, 2, 1));

  // Now climb the horns of amun (self balancing principle of growth),
  // each number sequence will push the evolution of each ring to align,
  // like a binary helix, not unlike the ram's horn (hence the neteru ref).
  LValue:=0;
  for x:=0 to CNT_LUCAS_IRRATIONALE do
  Begin
    inc(LValue, LHoly);
    If LValue > 255 then
      LValue:=0;
    FValues[x]:=LValue;
  end;
end;

procedure THexNumberSequence.AlignToLock;
Begin
  While not Lock do
  grow(1);
end;

function THexNumberSequence.Validate(Value:Byte):boolean;
var
  x:  integer;
Begin
  { Reset matrix }
  MatrixElement := FKey;

  // If the number does not exist within the growth-ring [64 | 64 | 64 | 64] of
  // the lucas based sequence, the value cannot have been produced by
  // the root-key. We keep on growing until the ring
  // is exhausted or we have a match.
  for x:=0 to 255 do
  Begin
    if (FValue <> Value) then
      grow(1)
    else
      break;
  end;

  // If the value belongs to the ring, it should be found
  // within the first quadrant. 63, the great divide.
  result := GetLockToQuadrant;
end;

function THexNumberSequence.GetLockToQuadrant: boolean;
var
  x:  integer;
Begin
  for x:=0 to CNT_LUCAS_IRRATIONALE do
  begin
    result := FValue = FValues[x];
    if result then
    break;
  end;
End;

procedure THexNumberSequence.Grow(Value: byte);
var
  x:  integer;
  LGrowth: integer;
Begin
  for x:=1 to Value do
  Begin
    if FValue > 0 then
    LGrowth := x + (x-1) else
    LGrowth := 1;

    if (LGrowth > 255) then
    FValue := LGrowth mod 255 else
    FValue := FValue + LGrowth mod 255;
  end;
End;

function THexNumberSequence.Value: byte;
begin
  Result := FValue;
end;

end.
