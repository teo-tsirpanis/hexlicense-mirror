unit FMX.hexmgrlicense;

{$I FMX.hexlicense.inc}

interface

uses
  {$IFDEF VCL_TARGET}
    {$IFDEF USE_NEW_UNITNAMES}
    hexbuffers,
    Winapi.Windows,
    System.SysUtils, System.classes, System.Variants, Vcl.Controls,
    System.dateutils, VCL.graphics, System.Win.Registry;
    {$ELSE}
    hexbuffers,
    sysutils, classes, variants, controls, dateutils, graphics, windows, registry;
    {$ENDIF}
  {$ENDIF}

  {$IFDEF FMX_TARGET}
    FMX.hexbuffers,
    FMX.Dialogs,
    System.SysUtils, System.classes, System.Variants, System.dateutils,
    System.UITypes,
    {$IFDEF MSWINDOWS}
    Winapi.Windows,
    System.Win.Registry,
    {$ENDIF}
    FMX.Forms, FMX.graphics, FMX.frmhexmgrlicense;
  {$ENDIF}

const
  CNT_FMXHEXLICENSE_MAJOR    = 1;
  CNT_FMXHEXLICENSE_MINOR    = 0;
  CNT_FMXHEXLICENSE_REVISION = 3;
  CNT_FMXHEXLICENSE_CIPNAME  = 'Embarcadero';

  {$IFDEF FMX_TARGET}
    {$IFDEF SUPPORT_PIDS}
    CNT_ALL_PLATFORMS =
      {$IFDEF SUPPORT_WIN32}   + pidWin32 {$ENDIF}
      {$IFDEF SUPPORT_WIN64}   + pidWin64 {$ENDIF}
      {$IFDEF SUPPORT_OSX32}   + pidOSX32 {$ENDIF}
      {$IFDEF SUPPORT_OSX64}   + pidOSX64 {$ENDIF}
      {$IFDEF SUPPORT_IOS32}   + pidiOSDevice32 {$ENDIF}
      {$IFDEF SUPPORT_IOS64}   + pidiOSDevice64 {$ENDIF}
      {$IFDEF SUPPORT_IOSDev}  + pidiOSDevice {$ENDIF}
      {$IFDEF SUPPORT_ANDROID} + pidAndroid {$ENDIF}
      {$IFDEF SUPPORT_IOS32 or SUPPORT_IOS64 or SUPPORT_IOSDev}
        + pidiOSSimulator
      {$ENDIF}
      ;

    CNT_WIN_ONLY =
      {$IFDEF SUPPORT_WIN32}   + pidWin32 {$ENDIF}
      {$IFDEF SUPPORT_WIN64}   + pidWin64 {$ENDIF}
      ;
    {$ENDIF}
  {$ENDIF}

  {$IFDEF VCL_TARGET}
    {$IFDEF SUPPORT_PIDS}
    CNT_ALL_PLATFORMS =
      {$IFDEF SUPPORT_WIN32} + pidWin32 {$ENDIF}
      {$IFDEF SUPPORT_WIN64} + pidWin64 {$ENDIF}
      ;
    {$ENDIF}
  {$ENDIF}

type

  //###########################################################################
  // Forward declarations
  //###########################################################################

  {$IFDEF MSWINDOWS}
  TFMXHexRegistryLicenseStorage  = class;
  {$ENDIF}
  TFMXHexCustomLicenseStorage    = class;
  TFMXHexOwnerLicenseStorage     = class;
  TFMXHexLucasNumberSequence     = class;
  TFMXHexFileLicenseStorage      = class;
  TFMXHexSerialGenerator         = class;
  TFMXHexSerialMatrix            = class;
  TFMXHexSerialNumber            = class;

  //###########################################################################
  // Exception classes
  //###########################################################################

  EFMXHexLicense                         = class(Exception);      (* License *)
  EFMXHexLicenseInternalError            = class(EFMXHexLicense); (* General *)
  EFMXHexLIcenseSerializationState       = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseEditingOnlyInDesignMode  = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseEditingOnlyRuntime       = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseDurationInvalid          = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseSessionNotActive         = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseDataIONotReady           = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseAlreadyRegistered        = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseSerialDecoderNotAssigned = class(EFMXHexLicense); (* License *)
  EFMXHexLicenseInvalidSerialNumber      = class(EFMXHexLicense); (* License *)

  EFMXHexLicStorage                      = class(Exception);         (* Storage *)
  EFMXHexLicenseWriteFailed              = class(EFMXHexLicStorage); (* Storage *)
  EFMXHexLicenseReadFailed               = class(EFMXHexLicStorage); (* Storage *)
  EFMXHexLicenseMatrixNotReady           = class(EFMXHexLicStorage); (* Storage *)
  EFMXHexLicenseMatrixFailed             = class(EFMXHexLicStorage); (* Storage *)
  EFMXHexLicenseVerifyFailed             = class(EFMXHexLicStorage);

  EFMXHexSerialNumber                    = class(Exception);            (* Serial *)
  EFMXHexSerialMatrixNotReady            = class(EFMXHexSerialNumber);  (* Serial *)
  EFMXHexSerialMatrixFailed              = class(EFMXHexSerialNumber);  (* Serial *)

  //###########################################################################
  // Datatypes
  //###########################################################################

  TFMXHexLicenseType   = (ltDayTrial,ltRunTrial,ltFixed);
  TFMXHexLicenseState  = (lsPending,lsExpired,lsValid,lsError);
  TFMXHexKeyMatrix     = packed Array[0..11] of byte;

  { Data record }
  TFMXHexLicenseRecord = packed Record
    Magic:        LONGWORD;
    { defined when first created }
    lrLicBuildt:    TDateTime;
    lrBought:       TDateTime;

    { Definable properties }
    lrKind:         TFMXHexLicenseType;
    lrDuration:     integer;
    lrUsed:         integer;
    lrProvider:     string;
    lrSoftware:     string;
    lrFixedStart:   TDateTime;
    lrFixedEnd:     TDateTime;

    { Runtime properties }
    lrLastRun:      TDateTime;
    lrState:        TFMXHexLicenseState;
    lrSerialnumber: string;
  End;
                                    
  //###########################################################################
  // Event declarations
  //###########################################################################

  { Events for license }
  TFMXHexBeforeLicenseLoadedEvent   =  procedure (Sender:TObject) of Object;
  TFMXHexAfterLicenseLoadedEvent    =  procedure (Sender:TObject) of Object;
  TFMXHexBeforeLicenseUnLoadedEvent =  procedure (Sender:TObject) of Object;
  TFMXHexAfterLicenseUnloadedEvent  =  procedure (Sender:TObject) of Object;
  TFMXHexLicenseExpiredEvent        =  procedure (Sender:TObject) of Object;
  TFMXHexLicenseBeginsEvent         =  procedure (Sender:TObject) of Object;
  TFMXHexLicenseObtainedEvent       =  procedure (Sender:TObject) of Object;
  TFMXHexLicenseCountdownEvent      =  procedure (Sender:TObject;
                                    Value:integer) of Object;
  TFMXHexWarnDebuggerEvent          =  procedure (sender:TObject) of Object;
  
  { Events for storage }
  TFMXHexWriteLicenseEvent          =  procedure (sender:TObject;Stream:TStream;
                                    var Failed:boolean) of Object;
  TFMXHexReadLicenseEvent           =  procedure (Sender:TObject;Stream:TStream;
                                    var Failed:boolean) of Object;
  TFMXHexDataExistsEvent            =  procedure (Sender:TObject;
                                    var Value:boolean) of Object;
  { Events for KeyMatrix }
  TFMXHexGetKeyMatrixEvent          =  procedure (Sender:TObject;
                                    Var Value: TFMXHexKeyMatrix) of Object;
  { Events for serialnumber }
  TFMXHexSerialNumberAvailableEvent =  procedure (Sender:TObject;Value:string;
                                    var Accepted:boolean) of Object;


  TFMXHexLicenseInfo = Record
  end;

  TFMXHexShowRegisterDialogEvent = procedure (Sender:TObject;
    const Info: TFMXHexLicenseInfo) of object;

  //###########################################################################
  // Interface declarations
  //###########################################################################

  { Access interface for TFMXHexLicense }
  IHexLicenseStorage = Interface
    ['{894A9A51-6287-48BB-B6B3-6B195123DB02}']
    procedure ReadData(Stream: TStream; var Failed: boolean);
    procedure WriteData(Stream: TStream; var Failed: boolean);
    function  DataExists: boolean;
    function  Ready: boolean;
  end;

  { Access interface for TFMXHexCustomLicenseStorage}
  IHexSerialMatrix = Interface
    ['{D562EC1E-6254-45E6-87C7-18CF16CF84B3}']
    function GetSerialMatrix(var Value: TFMXHexKeyMatrix): boolean;
  end;

  //###########################################################################
  // Components
  //###########################################################################

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexLicense = class(TComponent)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FActive:          boolean;
    FAuto:            boolean;
    FDurationLeft:    integer;
    FData:            TFMXHexLicenseRecord;
    FStorage:         TFMXHexCustomLicenseStorage;
    FSerial:          TFMXHexSerialNumber;

    FOnBeforeUnload:  TFMXHexBeforeLicenseUnLoadedEvent;
    FOnAfterUnLoad:   TFMXHexAfterLicenseUnloadedEvent;
    FOnCountDown:     TFMXHexLicenseCountdownEvent;
    FOnObtained:      TFMXHexLicenseObtainedEvent;
    FOnBefore:        TFMXHexBeforeLicenseLoadedEvent;
    FOnBegins:        TFMXHexLicenseBeginsEvent;
    FOnAfter:         TFMXHexAfterLicenseLoadedEvent;
    FOnEnds:          TFMXHexLicenseExpiredEvent;
    FOnWarning:       TFMXHexWarnDebuggerEvent;
    //FOnDialog:        TFMXHexShowRegisterDialogEvent;

    function    LicenseDataExists: boolean;
    procedure   ReadLicenseData;
    procedure   WriteLicenseData;
    function    CanReadWrite: boolean;
    procedure   StoreLicenseType(value: TFMXHexLicenseType);
    procedure   StoreDuration(Value: integer);
    procedure   SetFixedStartDate(Value: TDateTime);
    procedure   SetFixedEndDate(Value: TDateTime);
    procedure   ResetLicenseInformation;
    function    GetSerialNumber: string;
    procedure   UpdateSession;

    procedure   SetStorage(Value: TFMXHexCustomLicenseStorage);
    procedure   SetSerialnrclass(Value: TFMXHexSerialNumber);
    procedure   CheckSerialNumber(const Value: string);

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
    property    LicenseState: TFMXHexLicenseState read FData.lrState;
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
    property Automatic: boolean read FAuto write FAuto stored true;
    property Storage: TFMXHexCustomLicenseStorage read FStorage write SetStorage;
    property SerialNumber: TFMXHexSerialNumber read FSerial write SetSerialnrclass;
    property License: TFMXHexLicenseType read FData.lrKind write StoreLicenseType stored true;
    property Duration: integer read FData.lrDuration write StoreDuration stored true;
    property Provider: string read Getprovider write SetProvider stored true;
    property FixedStart:TDateTime read FData.lrFixedStart write SetFixedStartDate stored true;
    property FixedEnd:TDateTime read FData.lrFixedEnd write SetFixedEndDate stored true;
    property Software: string read GetSoftware write SetSoftware stored true;

    property WarnDebugger:TFMXHexWarnDebuggerEvent read FOnWarning write FOnWarning;
    property OnLicenseObtained: TFMXHexLicenseObtainedEvent read FOnObtained write FOnObtained;
    property OnBeforeLicenseLoaded: TFMXHexBeforeLicenseLoadedEvent read FOnBefore write FOnBefore;
    property OnAfterLicenseLoaded: TFMXHexAfterLicenseLoadedEvent read FOnAfter write FOnAfter;
    property OnLicenseBegins: TFMXHexLicenseBeginsEvent read FOnBegins write FOnBegins;
    property OnLicenseExpires: TFMXHexLicenseExpiredEvent read FOnEnds write FOnEnds;
    property OnBeforeLicenseUnLoaded: TFMXHexBeforeLicenseUnLoadedEvent read FOnBeforeUnload write FOnBeforeUnload;
    property OnAfterLicenseUnLoaded: TFMXHexAfterLicenseUnloadedEvent read FOnAfterUnLoad write FOnAfterUnLoad;
    property OnLicenseCountDown: TFMXHexLicenseCountdownEvent read FOnCountDown write FOnCountDown;
  End;

  TFMXHexLucasNumberSequence = class
  {$IFDEF SUPPORT_SEALED} sealed {$ENDIF} (TObject)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FValue:   Byte;
    FKey:     Byte;
    FValues:  Array[0..63] of Byte;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    procedure SetKey(Value:Byte);
    function  GetLockToFibonacci:boolean;
  public
    property  MatrixElement: Byte read FKey write SetKey;
    property  Lock: boolean read GetLockToFibonacci;
    procedure AlignToLock;
    procedure Grow(Value:Byte);
    function  Validate(Value:Byte):boolean;
    function  Value:Byte;
  End;

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexSerialNumber = class(TComponent)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FMatrix:  TFMXHexSerialMatrix;
    FGrowthRings: Array[0..11] of TFMXHexLucasNumberSequence;
    procedure SetMatrix(Value: TFMXHexSerialMatrix);
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
    property    SerialMatrix: TFMXHexSerialMatrix read FMatrix write SetMatrix;
  End;

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexSerialGenerator = class(TFMXHexSerialNumber)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnAvailable: TFMXHexSerialNumberAvailableEvent;
  public
    procedure Generate(Count:integer); virtual;
  published
    property OnSerialnumberAvailable: TFMXHexSerialNumberAvailableEvent
      read FOnAvailable write FOnAvailable;
  End;

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexSerialMatrix = class(TComponent,IHexSerialMatrix)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnGetMatrix: TFMXHexGetKeyMatrixEvent;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    function  GetSerialMatrix(var Value:TFMXHexKeyMatrix):boolean;
  published
    property  OnGetKeyMatrix:TFMXHexGetKeyMatrixEvent
              read FOnGetMatrix write FOnGetMatrix;
  End;

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexCustomLicenseStorage=class(TComponent, IHexLicenseStorage)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FOnRead:  TFMXHexReadLicenseEvent;
    FOnWrite: TFMXHexWriteLicenseEvent;
    FOnExists:  TFMXHexDataExistsEvent;
    FMatrix:  TFMXHexSerialMatrix;

    procedure SetMatrix(Value:TFMXHexSerialMatrix);
    function RC4(Source:string;key:string):string;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    function CanEncode:boolean;
    procedure EncodeData(pBuffer:pointer;Length:integer);
    procedure DecodeData(pBuffer:pointer;Length:integer);

    (* IMPLEMENTS: IHexLicenseStorage *)
    procedure ReadData(Stream:TStream;var Failed:boolean);virtual;
    procedure WriteData(Stream:TStream;Var Failed:boolean);virtual;
    function DataExists:boolean;virtual;
    function Ready:boolean;Virtual;
  public
    procedure Notification(AComponent: TComponent;
        Operation: TOperation);Override;
  published
    property SerialMatrix: TFMXHexSerialMatrix read FMatrix write SetMatrix;
    property OnDataExists: TFMXHexDataExistsEvent Read FOnExists write FOnExists;
    property OnReadData:  TFMXHexReadLicenseEvent read FOnRead write FOnRead;
    property OnWriteData: TFMXHexWriteLicenseEvent read FOnWrite write FOnWrite;
  End;

  {$IFDEF MSWINDOWS}
  TFMXHexRegistryGetPathEvent = procedure (Sender:TObject;var Root:string) of object;

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_WIN_ONLY)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexRegistryLicenseStorage = class(TFMXHexCustomLicenseStorage)
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  private
    FRegValue:  string;
    FRegPath:   string;
    FOnGetPath: TFMXHexRegistryGetPathEvent;
  {$IFDEF SUPPORT_STRICT} strict {$ENDIF}
  protected
    (* IMPLEMENTS: IHexLicenseStorage *)
    procedure ReadData(Stream: TStream; var Failed: boolean);override;
    procedure WriteData(Stream: TStream; var Failed: boolean);override;
    function DataExists: boolean;override;
    function Ready: boolean;Override;
  public
    constructor Create(AOwner:TComponent);Override;
  published
    property OnGetRegistryPath: TFMXHexRegistryGetPathEvent
      read FOnGetPath write FOnGetPath;
    property RegPath: string read FRegPath write FRegPath stored true;
    property RegValue: string read FRegValue write FRegValue stored true;
  End;
  {$ENDIF}

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexFileLicenseStorage = class(TFMXHexCustomLicenseStorage)
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

  {$IFDEF FMX_TARGET}
  {$IFDEF SUPPORT_PIDS}
  [ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
  {$ENDIF}
  {$ENDIF}
  TFMXHexOwnerLicenseStorage = class(TFMXHexCustomLicenseStorage)
  end;

implementation

//###########################################################################
// Exception message resource strings
//###########################################################################

resourcestring
ERR_HEX_LicenseEditingOnlyInDesignMode =
'License editing can only be performed during application design';

ERR_HEX_InternalError =
'Internal error, the following error occured: %s';

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
// TFMXHexLicense
//###########################################################################

Constructor TFMXHexLicense.Create(AOwner:TComponent);
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
  FAuto:=False;
End;

class function TFMXHexLicense.GetVersionText: string;
begin
  result:=format('%d.%d.%d',
    [CNT_FMXHEXLICENSE_MAJOR,
    CNT_FMXHEXLICENSE_MINOR,
    CNT_FMXHEXLICENSE_REVISION]);
end;

procedure TFMXHexLicense.BeforeDestruction;
Begin
  { if session is active then close down }
  If Active then
    EndSession;
  inherited;
End;

procedure TFMXHexLicense.Loaded;
Begin
  inherited;

  { automatically start? }
  If (csDesigning in ComponentState)
  or (FAuto = False) then
  exit;

  { if automatic start failed, re-raise exception }
  try
    BeginSession;
  except
    on exception do
    raise;
  end;
End;

procedure TFMXHexLicense.Notification(AComponent: TComponent; Operation: TOperation);
Begin
  If (AComponent is TFMXHexCustomLicenseStorage) then
  begin
    Case Operation of
    opRemove: SetStorage(nil);
    opInsert: SetStorage( TFMXHexCustomLicenseStorage(AComponent) );
    end;
    exit;
  end else

  if (AComponent is TFMXHexSerialNumber) then
  begin
    Case Operation of
    opRemove: SetSerialNrClass(nil);
    opInsert: SetSerialNrClass( TFMXHexSerialNumber(AComponent) );
    end;
  end else
  inherited Notification(AComponent, Operation);
End;

function TFMXHexLicense.LicenseDataExists: boolean;
Begin
  { Check that we can read and write }
  If not CanReadWrite then
  raise EFMXHexLicenseDataIONotReady.Create(ERR_Hex_LicenseDataIONotReady);

  { return license-storage dataexists }
  try
    result:=IHexLicenseStorage(FStorage).DataExists;
  except
    on exception do
    raise;
  end;
End;

procedure TFMXHexLicense.ReadLicenseData;
var
  LFailed:  boolean;
  mAccess:  IHexLicenseStorage;
  LRecord:  TFMXHexBufferMemory;
  LReader:  TFMXHexReaderBuffer;
  LStream:  TFMXHexStreamAdapter;
Begin
  if not (csDestroying in ComponentState) then
  begin
    // Only if we can read & write
    if CanReadWrite() then
    begin
      // setup in-memory buffer
      LRecord := TFMXHexBufferMemory.Create(nil);
      try
        // Write data
        LReader := TFMXHexReaderBuffer.Create(LRecord);
        try
          LStream := TFMXHexStreamAdapter.Create(LRecord);
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
            raise EFMXHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);

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
                  FData.lrKind :=  TFMXHexLicenseType( LReader.ReadInt );
                  FData.lrDuration := LReader.ReadInt;
                  FData.lrUsed := LReader.ReadInt;
                  FData.lrProvider := LReader.ReadString;
                  FData.lrSoftware := LReader.ReadString;
                  FData.lrFixedStart := LReader.ReadDateTime;
                  FData.lrFixedEnd := LReader.ReadDateTime;
                  FData.lrLastRun := LReader.ReadDateTime;
                  FData.lrState :=  TFMXHexLicenseState( LReader.ReadInt );
                  FData.lrSerialnumber := LReader.ReadString;
                except
                  on e: exception do
                  raise EFMXHexLicenseVerifyFailed.Create(ERR_HEX_FailedVerifyLicenseInformation)
                end;
              end else
              raise EFMXHexLicenseVerifyFailed.Create(ERR_HEX_FailedVerifyLicenseInformation)
            end else
            raise EFMXHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);

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
    raise EFMXHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
  end;
end;

procedure TFMXHexLicense.WriteLicenseData;
var
  LFailed:  boolean;
  mAccess:  IHexLicenseStorage;
  LRecord:  TFMXHexBufferMemory;
  LWriter:  TFMXHexWriterBuffer;
  LStream:  TFMXHexStreamAdapter;
begin
  // Not if terminating
  if not (csDestroying in ComponentState) then
  begin
    // Only if we can read & write
    if CanReadWrite() then
    begin
      // setup in-memory buffer
      LRecord := TFMXHexBufferMemory.Create(nil);
      try
        // Write data
        LWriter := TFMXHexWriterBuffer.Create(LRecord);
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
          LStream := TFMXHexStreamAdapter.Create(LRecord);
          try
            if FStorage.GetInterface(IHexLicenseStorage,mAccess) then
            begin
              LFailed := false;
              try
                mAccess.WriteData(LStream, LFailed);
              except
                on exception do
                raise;
              end;
            end else
            raise EFMXHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
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
    raise EFMXHexLicenseDataIONotReady.Create(ERR_HEX_LicenseDataIONotReady);
  end;
end;

function TFMXHexLicense.Execute:boolean;
var
  LicDlg: TfrmLicenseProperties;
  LRetVal: Boolean;
Begin
  result := False;

  if Active then
  begin
    LRetVal := False;

      LicDlg := TfrmLicenseProperties.Create(NIL);
      With LicDlg do
      begin
      try
        lbCreated.Text := DateToStr(FData.lrLicBuildt);
        lbSoftware.Text := FData.lrSoftware;
        lbProvider.Text := FData.lrProvider;
        lbDuration.Text := '';

        case FData.lrKind of
        ltDayTrial:
          begin
            lbDuration.Text := IntToStr(FData.lrDuration) + CNT_DAYS;
            lbExpires.Text := DateToStr(IncDay(FData.lrLicBuildt,FData.lrDuration));
          end;
        ltRunTrial: lbDuration.Text := IntToStr(FData.lrDuration) + CNT_RUNS;
        ltFixed:
          begin
            lbExpires.Text := DateToStr(FData.lrFixedEnd);
            lbDuration.text := IntToStr(DaysBetween(FData.lrFixedStart,FData.lrFixedEnd)) + CNT_DAYS;
          end;
        end;

        case FData.lrKind of
        ltDayTrial: lbLeft.Text := IntToStr(FDurationLeft) + CNT_DAYSLEFT;
        ltRunTrial: lbLeft.Text := IntToStr(FDurationLeft) + CNT_RUNSLEFT;
        ltFixed:    lbLeft.Text := IntToStr(FDurationLeft) + CNT_DAYSLEFT;
        end;

        nProgress.Max := FData.lrDuration;
        nProgress.Value := FDurationLeft;

        If LicenseState = lsValid then
        begin
          lbDuration.Text := cnt_Licensed;
          lbExpires.Text := cnt_Licensed;
          btnRegister.Enabled := False;
          edKeyCode.enabled := False;
          lbLeft.Text := 'Registered';
        end;

        if LicenseState = lsExpired then
        Begin
          lbDuration.Text := CNT_EXPIRED;
          lbLeft.Text := CNT_EXPIRED;
        end;

        // Set the register button focus to avoid keyboard popup
        btnRegister.SetFocus;

        // We are using the overloaded version of ShowModal to allow multiplatform
        // Support. Android does not support Modal forms thus we have to use
        // An anonomous procedure to capture the ModalResult from the back
        // and reg buttons.
        ShowModal(
        procedure(ModalResult : TModalResult)
        begin
          // Handle the Register button event
          if (ModalResult = mrOK) then
          begin
            //Register pressed, now attempt to
            //register the serial number
            Buy(edKeyCode.Text);
            LRetVal := true;
          end;
          if (ModalResult = mrCancel) then
          begin
            // Handle the back button event
          end;
        end);

        Result := LRetVal;
      finally
        // NOP
      end;
    end;

  end;
End;

procedure TFMXHexLicense.BootFirstTime;
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
    FActive:=True;
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

procedure TFMXHexLicense.BootContinued;
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

procedure TFMXHexLicense.BeginSession;
Begin
  { Already active? }
  if Active then
  exit;

  { notify user that we are accessing the session data }
  try
    Case LicenseDataExists of
    true:
      begin
        try
          BootContinued;
        except
          on e: exception do
          begin
            raise Exception.Create('BootContinued:' + e.Message);
          end;
        end;
      end;
    false:
      begin
        try
          BootFirstTime;
        except
          on e: exception do
          begin
            raise Exception.Create('BootFirstTime:' + e.Message);
          end;
        end;
      end;
    end;
  except
    on exception do
    raise;
  end;
end;

procedure TFMXHexLicense.EndSession;
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

procedure TFMXHexLicense.ResetLicenseInformation;
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

procedure TFMXHexLicense.UpdateSession;
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

      (* FDurationLeft:=DaysBetween(FData.FixedEnd,FData.FixedStart);
      if FDurationLeft<0 then
      FDurationLeft:=0; *)
      FData.lrLastRun:=Now;
    End;
  End;

  If (FDurationLeft>0) then
  FData.lrState:=lsPending else
  FData.lrState:=lsExpired
End;

procedure TFMXHexLicense.DoLicenseBegins;
Begin
  try
    if assigned(FOnBegins) then
    FOnBegins(Self);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoCountDown;
begin
  try
    if assigned(FOnCountDown) then
    FOnCountDown(self,FDurationLeft);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoLicenseExpired;
Begin
  try
    If assigned(FOnEnds) then
    FOnEnds(self);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoBeforeLoaded;
Begin
  try
    if assigned(FOnBefore) then
    FOnBefore(Self);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoAfterLoaded;
Begin
  try
    If assigned(FOnAfter) then
    FOnAfter(Self);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoBeforeUnLoaded;
Begin
  try
    If assigned(FOnbeforeUnLoad) then
    FOnBeforeUnload(Self);
  except
    on exception do;
  end;
End;

procedure TFMXHexLicense.DoAfterUnloaded;
Begin
  if assigned(FOnAfterUnLoad) then
  FOnAfterUnLoad(self);
End;

procedure TFMXHexLicense.CheckSerialNumber(Const Value:string);
Begin
  If not Active then
  raise EFMXHexLicenseSessionNotActive.Create
  (ERR_HEX_LicenseSessionNotActive);

  { No serial number decoder installed? }
  If not Assigned(FSerial) then
  raise EFMXHexLicenseSerialDecoderNotAssigned.Create
  (ERR_HEx_LicenseSerialDecoderNotAssigned);

  { A serial number is already present? }
  if length(trim(FData.lrSerialnumber))>0 then
  raise EFMXHexLicenseAlreadyRegistered.Create
  (ERR_HEX_LicenseAlreadyRegistered);

  { Validate the serial number }
  If not FSerial.Validate(Value) then
  raise EFMXHexLicenseInvalidSerialNumber.Create
  (ERR_HEX_LicenseInvalidSerialNumber);
End;

procedure TFMXHexLicense.Buy(Const aSerialNumber:string);
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
  Raise EFMXHexLIcenseSerializationState.Create
  (ERR_HEX_LicenseStateInvalidSerialization);
end;

procedure TFMXHexLicense.StoreDuration(Value:integer);
begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);

  { Check that the duration value is valid }
  If (Value<1) then
  Raise EFMXHexLicenseDurationInvalid.Create(ERR_HEX_LicenseDurationInvalid);

  FData.lrDuration:=value;
end;

procedure TFMXHexLicense.StoreLicenseType(value:TFMXHexLicenseType);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrKind:=Value;
End;

function TFMXHexLicense.GetProvider:string;
Begin
  result:=FData.lrProvider;
End;

procedure TFMXHexLicense.SetProvider(Value: string);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrProvider := Value;
End;

procedure TFMXHexLicense.SetStorage(Value: TFMXHexCustomLicenseStorage);
Begin
  { we already have one }
  If assigned(FStorage) then
  begin
    FStorage.RemoveFreeNotification(self);
    FStorage := nil;
  end;

  if Value <> FStorage then
  begin
    FStorage := Value;
    FStorage.FreeNotification(self);
  end;

End;

procedure TFMXHexLicense.SetSerialNrClass(Value: TFMXHexSerialNumber);
Begin
  { we already have one }
  If assigned(FSerial) then
    FSerial.RemoveFreeNotification(self);

  FSerial:=Value;

  { Set free notification }
  If Assigned(FSerial) then
    FSerial.FreeNotification(self);
End;

function TFMXHexLicense.CanReadWrite: boolean;
var
  LRef: IHexLicenseStorage;
Begin
  if assigned(FStorage) then
  begin
    if FStorage.GetInterface(IHexLicenseStorage,LRef) then
    begin
      result := LRef.Ready;
    end else
    Raise EFMXHexLicenseInternalError.CreateFmt(ERR_HEX_InternalError,
    ['Failed to obtain reference to storage handler error']);
  end else
  result := False;
End;

procedure TFMXHexLicense.SetFixedStartDate(Value:TDateTime);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate) and
     not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
    (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrFixedStart:=Value;
End;

procedure TFMXHexLicense.SetFixedEndDate(Value:TDateTime);
Begin
  { Are we in runtime or designtime? }
  If  not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrFixedEnd:=Value;
End;

function TFMXHexLicense.GetSoftware:string;
Begin
  result:=FData.lrSoftware;
End;

procedure TFMXHexLicense.SetSoftware(Value:string);
Begin
  { Are we in runtime or designtime? }
  If not (csDesigning in Componentstate)
  and not (csLoading in Componentstate) then
  Raise EFMXHexLicenseEditingOnlyInDesignMode.Create
  (ERR_HEX_LicenseEditingOnlyInDesignMode);
  FData.lrSoftware:=Value;
End;

function TFMXHexLicense.GetSerialNumber:string;
Begin
  result:=FData.lrSerialNumber;
End;


//############################################################
// TFMXHexFileLicenseStorage
//############################################################

Constructor TFMXHexFileLicenseStorage.Create(AOwner: TComponent);
Begin
  inherited Create(Aowner);
  FName:='lcdata.lcc';
End;

function TFMXHexFileLicenseStorage.Ready: boolean;
begin
  result:=assigned(SerialMatrix);
end;

procedure TFMXHexFileLicenseStorage.ReadData(Stream: TStream; var Failed: boolean);
var
  FFile:    TFileStream;
  FBuffer:  pointer;
Begin
  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  If assigned(OnReadData) then
  begin
    inherited ReadData(Stream,Failed);
    exit;
  end;

  { Can we encode? }
  If not CanEncode then
  Begin
    Failed:=True;
    Raise EFMXHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
  end;

  { Does the data exist? }
  If not DataExists then
  Begin
    Failed:=True;
    exit;
  end;

  { Allocate temp memory buffer }
  FBuffer:=Allocmem(SizeOf(TFMXHexLicenseRecord));

  try
    { open the file in question }
    try
      FFile:=TFileStream.Create(FName,fmOpenRead);
    except
      on exception do
      Begin
        Failed:=True;
        raise EFMXHexLicenseReadFailed.Create(ERR_Hex_LicenseReadFailed);
      end;
    end;

    { Get the data }
    try
      try
        FFile.read(FBuffer^,SizeOf(TFMXHexLIcenseRecord));
      except
        on exception do
        Begin
          Failed:=True;
          raise EFMXHexLicenseReadFailed.Create(ERR_Hex_LicenseReadFailed);
        end;
      end;
    finally
      FFile.free;
    end;

    { Decode the data }
    DecodeData(Fbuffer,SizeOf(TFMXHexLIcenseRecord));

    { copy buffer into target stream }
    stream.Write(FBuffer^,SizeOf(TFMXHexLicenseRecord));
  finally
    Freemem(Fbuffer,SizeOf(TFMXHexLicenseRecord));
  end;
end;

procedure TFMXHexFileLicenseStorage.WriteData(Stream:TStream;Var Failed:boolean);
var
  FFile:    TFileStream;
  FBuffer:  pointer;
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
    Failed:=True;
    Raise EFMXHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
  end;

  { Allocate temp memory buffer }
  FBuffer:=Allocmem(SizeOf(TFMXHexLicenseRecord));
  try
    { copy data into our buffer }
    Stream.Read(FBuffer^,SizeOf(TFMXHexLicenseRecord));

    { Encode the data }
    EncodeData(Fbuffer,SizeOf(TFMXHexLIcenseRecord));

    { open the file in question }
    try
      FFile:=TFileStream.Create(FName,fmCreate or fmOpenWrite);
    except
      on exception do
      Begin
        Failed:=True;
        raise EFMXHexLicenseWriteFailed.Create(ERR_Hex_LicenseWriteFailed);
      end;
    end;

    { Get the data }
    try
      try
        FFile.Write(FBuffer^,SizeOf(TFMXHexLIcenseRecord));
      except
        on exception do
        Begin
          Failed:=True;
          raise EFMXHexLicenseWriteFailed.Create(ERR_Hex_LicenseWriteFailed);
        end;
      end;
    finally
      FFile.free;
    end;

  finally
    Freemem(Fbuffer,SizeOf(TFMXHexLicenseRecord));
  end;
end;

function TFMXHexFileLicenseStorage.DataExists:boolean;
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
// TFMXHexCustomLicenseStorage
//############################################################

procedure TFMXHexCustomLicenseStorage.Notification(AComponent:TComponent;Operation:TOperation);
Begin
  inherited Notification(AComponent,Operation);
  If (AComponent is TFMXHexSerialMatrix) then
  begin
    Case Operation of
    opRemove: SetMatrix(NIL);
    opInsert: SetMatrix(TFMXHexSerialMatrix(AComponent));
    end;
  end;
End;

function TFMXHexCustomLicenseStorage.CanEncode:boolean;
Begin
  result:=Assigned(FMatrix);
End;

procedure TFMXHexCustomLicenseStorage.ReadData(Stream:TStream;var Failed:boolean);
Begin
  If assigned(OnReadData) then
  OnReadData(self,Stream,Failed) else
  Failed:=true;
End;

procedure TFMXHexCustomLicenseStorage.WriteData(Stream:TStream;Var Failed:boolean);
Begin
  If assigned(OnWriteData) then
  OnWriteData(Self,Stream,Failed) else
  Failed:=true;
End;

function TFMXHexCustomLicenseStorage.DataExists:boolean;
Begin
  If assigned(FOnExists) then
  FOnExists(self,result) else
  result:=False;
End;

{ purpose:
  Checks to see if the component is ready to
  forfill it's task. }
function TFMXHexCustomLicenseStorage.Ready:boolean;
Begin
  result:=assigned(FMatrix)
    and assigned(OnReadData)
    and assigned(OnWriteData);
End;

procedure TFMXHexCustomLicenseStorage.EncodeData(pBuffer:pointer;Length:integer);
var
  FResult:  string;
  FCode:    string;
  FKeys:    TFMXHexKeyMatrix;
  mAccess:  IHexSerialMatrix;
Begin
  { Can we encode? }
  If not CanEncode then
  raise EFMXHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);

  if FMatrix.GetInterface(IHexSerialMatrix,mAccess) then
  begin
    if not mAccess.GetSerialMatrix(FKeys) then
    raise EFMXHexLicenseMatrixFailed.Create(ERR_HEX_LicenseMatrixFailed);
  end else
  Raise EFMXHexLicenseMatrixFailed.Create(ERR_Hex_LicenseMatrixNotReady);

  { Build up the encryption key }
  FCode:=chr(FKeys[5])
        + chr(FKeys[6])
        + chr(FKeys[2])
        + chr(FKeys[10])
        + chr(FKeys[4])
        + chr(FKeys[0])
        + chr(FKeys[1])
        + chr(FKeys[7])
        + chr(FKeys[11])
        + chr(FKeys[9])
        + chr(FKeys[3])
        + chr(FKeys[8]);

  try
    { Get the content of the buffer }
    SetLength(FResult,Length);
    Move(pBuffer^,FResult[1],Length);

    { encode the content }
    FResult := RC4(FResult, FCode);

    { write the encoded content back to buffer }
    Move(FResult[1],pBuffer^,Length);
  except
    on exception do;
  end;
End;

procedure TFMXHexCustomLicenseStorage.DecodeData(pBuffer: pointer; Length: integer);
Begin
  // RC4 is mutually exclusive
  EncodeData(pBuffer,Length);
End;

function TFMXHexCustomLicenseStorage.RC4(Source:string;key:string):string;
var
  S: Array[0..255] of Byte;
  K: Array[0..255] of byte;
  Temp,y:Byte;
  I,J,T,X:integer;
  target:string;
Begin
  { Byte key layout }
  for i:=0 to 255 do
  s[i]:=i;

  { Rotate with keyword }
  J:=1;
  for I:=0 to 255 do
  begin
    if j>length(key) then j:=1;
    k[i]:=byte(key[j]);
    inc(j);
  end;

  { Modify rotation }
  J:=0;
  For i:=0 to 255 do
  begin
    j:=(j+s[i] + k[i]) mod 256;
    temp:=s[i];
    s[i]:=s[j];
    s[j]:=Temp;
  end;

  { And kick ass }
  i:=0;
  j:=0;
  for x:=1 to length(source) do
  begin
    i:=(i+1) mod 256;
    j:=(j+s[i]) mod 256;
    temp:=s[i];
    s[i]:=s[j];
    s[j]:=temp;
    t:=(s[i] + (s[j] mod 256)) mod 256;
    y:=s[t];
    target:=target + char(byte(source[x]) xor y);
  end;
  result:=Target;
end;

procedure TFMXHexCustomLicenseStorage.SetMatrix(Value:TFMXHexSerialMatrix);
Begin
  { we already have one }
  If assigned(FMatrix) then
  FMatrix.RemoveFreeNotification(self);

  FMatrix:=Value;

  { Set free notification }
  If Assigned(FMatrix) then
  FMatrix.FreeNotification(self);
end;

//############################################################
// TFMXHexRegistryLicenseStorage
//############################################################

{$IFDEF MSWINDOWS}
Constructor TFMXHexRegistryLicenseStorage.Create(AOwner:TComponent);
Begin
  inherited Create(AOwner);
  FRegPath :=  'Software\Licenses\';
  FRegValue := 'lcdata';
End;

function TFMXHexRegistryLicenseStorage.Ready:boolean;
Begin
  result:=assigned(SerialMatrix);
End;

function TFMXHexRegistryLicenseStorage.DataExists:boolean;
var
  Reg:    TRegistry;
  LPath:  string;
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

  // Get registry path if user-defined
  LPath := FRegPath + FRegValue;
  if assigned(FOnGetPath) then
  begin
    FOnGetPath(self,LPath);
    LPath := trim(LPath);
  end;

  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      result := reg.Openkey(LPath,False);
      if result then
      begin
        result:=reg.ValueExists(FRegValue);
      end
    finally
      Reg.CloseKey;
      Reg.Free;
    end;
  except
    on exception do;
  end;
End;

procedure TFMXHexRegistryLicenseStorage.ReadData(Stream:TStream;var Failed:boolean);
var
  Reg:      TRegistry;
  LPath:    string;
  FBuffer:  pointer;
Begin
  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  (* Is read-data overriden? *)
  If assigned(OnReadData) then
  begin
    inherited ReadData(Stream,Failed);
    exit;
  end;

  { Can we encode? }
  If not CanEncode then
  Begin
    Failed:=True;
    Raise EFMXHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
  end;

  // Get registry path if user-defined
  LPath := FRegPath + FRegValue;
  if assigned(FOnGetPath) then
  begin
    FOnGetPath(self,LPath);
    LPath := trim(LPath);
  end;

  { Allocate temp memory buffer }
  FBuffer:=Allocmem(SizeOf(TFMXHexLicenseRecord));
  try
   Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
               
      { attempt to open the license information }
      if not reg.Openkey(LPath,False) then
      begin
        Raise EFMXHexLicenseMatrixFailed.Create(ERR_HEX_LicenseReadFailed);
        exit;
      end;

      { read the registry data into our buffer }
      reg.ReadBinaryData(FRegValue,FBuffer^,SizeOf(TFMXHexLIcenseRecord));

      { Decode the data }
      DecodeData(Fbuffer,SizeOf(TFMXHexLIcenseRecord));

      { copy buffer into target stream }
      stream.Write(FBuffer^,SizeOf(TFMXHexLicenseRecord));
    finally
      Reg.CloseKey;
      Reg.Free;
    end;
  finally
    Freemem(Fbuffer,SizeOf(TFMXHexLicenseRecord));
  end;
End;

procedure TFMXHexRegistryLicenseStorage.WriteData(Stream:TStream;Var Failed:boolean);
var
  Reg:      TRegistry;
  LPath:    string;
  FBuffer:  pointer;
Begin
  { are we terminating? }
  If (csDestroying in componentstate) then
  exit;

  If assigned(OnWriteData) then
  begin
    inherited WriteData(Stream,Failed);
    exit;
  end;

  If not CanEncode then
  Begin
    Failed:=True;
    Raise EFMXHexLicenseMatrixNotReady.Create(ERR_HEX_LicenseMatrixNotReady);
    exit;
  end;

  // Get registry path if user-defined
  LPath := FRegPath + FRegValue;
  if assigned(FOnGetPath) then
  begin
    FOnGetPath(self,LPath);
    LPath := trim(LPath);
  end;

  { Allocate memory buffer }
  FBuffer:=Allocmem(SizeOf(TFMXHexLicenseRecord));
  try
    { copy data into our buffer }
    Stream.Read(FBuffer^,SizeOf(TFMXHexLicenseRecord));

    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;

      { attempt to open the license information }
      if not reg.Openkey(LPath,True) then
      begin
        Raise EFMXHexLicenseMatrixFailed.Create(ERR_HEX_LicenseWriteFailed);
        exit;
      end;

      { Encode the data }
      EncodeData(Fbuffer,SizeOf(TFMXHexLIcenseRecord));

      { read the registry data into our buffer }
      reg.WriteBinaryData(FRegValue,FBuffer^,SizeOf(TFMXHexLIcenseRecord));
    finally
      Reg.CloseKey;
      Reg.Free;
    end;

  finally
    Freemem(Fbuffer,SizeOf(TFMXHexLicenseRecord));
  end;
End;
{$ENDIF}

//###########################################################################
// TFMXHexSerialMatrix
//###########################################################################

{ Simply returns a default serial matrix.
  The user can override this by assigning their own event code }
function TFMXHexSerialMatrix.GetSerialMatrix(var Value:TFMXHexKeyMatrix):boolean;
Const
  AMatrix: TFMXHexKeyMatrix = ($89,$C8,$82,$13,$D3,$86,$00,$98,$AF,$D3,$D5,$F2);
Begin
  { user defined? }
  If assigned(FOnGetMatrix) then
  Begin
    FOnGetMatrix(self,value);
    result:=True;
    exit;
  end;
  { user has not (4 some weird reason) populated the event,
    return the default }
  value:=AMatrix;
  result:=True;
End;

//###########################################################
// TFMXHexSerialGenerator
//###########################################################

procedure TFMXHexSerialGenerator.Generate(Count: integer);
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
// TFMXHexSerialNumber
//###########################################################

Constructor TFMXHexSerialNumber.Create(AOwner:TComponent);
var
  x:  integer;
begin
  inherited Create(AOwner);
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x] := TFMXHexLucasNumberSequence.Create;
  end;
End;

Destructor TFMXHexSerialNumber.Destroy;
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

procedure TFMXHexSerialNumber.Notification(AComponent:TComponent;Operation:TOperation);
Begin
  inherited Notification(AComponent,Operation);
  If (AComponent is TFMXHexSerialMatrix) then
  begin
    Case Operation of
    opRemove: SetMatrix(nil);
    opInsert: SetMatrix(TFMXHexSerialMatrix(AComponent));
    end;
  end;
end;

procedure TFMXHexSerialNumber.SetMatrix(Value:TFMXHexSerialMatrix);
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

procedure TFMXHexSerialNumber.LoadMatrix;
var
  x:      integer;
  LData:  TFMXHexKeyMatrix;
  LAccess: IHexSerialMatrix;
Begin
  { check that matrix is there }
  If not assigned(FMatrix) then
  begin
    raise EFMXHexSerialMatrixNotReady.Create(ERR_Hex_LicenseMatrixNotReady);
    exit;
  end;

  if FMatrix.GetInterface(IHexSerialMatrix, LAccess) then
  Begin
    if not LAccess.GetSerialMatrix(LData) then
    Raise EFMXHexLicenseMatrixFailed.Create(ERR_HEX_LicenseMatrixFailed);
  end else
  Raise EFMXHexLicenseMatrixFailed.Create(ERR_Hex_LicenseMatrixNotReady);

  { Load values into wheels }
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x].MatrixElement := LData[x];
  end;
End;

procedure TFMXHexSerialNumber.Clear;
var
  x:  integer;
Begin
  for x:=low(FGrowthRings) to high(FGrowthRings) do
  begin
    FGrowthRings[x].MatrixElement:=0;
  end;
End;

function TFMXHexSerialNumber.GetSerial: string;
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

procedure TFMXHexSerialNumber.Spin;
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

    while (LValue<1) do
    begin
      LRightIndex := length(FGrowthRings) - x;
      LValue := Random(FGrowthRings[LRightIndex].MatrixElement) + random(FGrowthRings[x].MatrixElement);
      //LValue := Random(FGrowthRings[11-x].MatrixElement) + random(FGrowthRings[x].MatrixElement);
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

function TFMXHexSerialNumber.Validate(Serial:string):boolean;
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
// TFMXHexLucasNumberSequence
//###########################################################

(* Notes:
   The lucas number sequence is closely tied to the Fibonacci growth
   formula: 2, 1, 3, 4, 7, 11, 18, 29, 47, 76

   In order to provoke growth I introduce a top range of 64 (0..63) ceil.
   This means that a maximum of 64 variations can occur within a single
   turn of the growth-ring [64 | 64 | 64 | 64], 4 quadrants that through
   256 permutations must contain the number *)

const
  CNT_LUCAS_IRRATIONALE  = {0 ..} 63;

procedure TFMXHexLucasNumberSequence.SetKey(Value: byte);
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

procedure TFMXHexLucasNumberSequence.AlignToLock;
Begin
  While not Lock do
  grow(1);
end;

function TFMXHexLucasNumberSequence.Validate(Value:Byte):boolean;
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
  // within the first quadrant
  result := GetLockToFibonacci;
end;

function TFMXHexLucasNumberSequence.GetLockToFibonacci: boolean;
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

procedure TFMXHexLucasNumberSequence.Grow(Value: byte);
var
  x:  integer;
Begin
  for x:=1 to Value do
  Begin
    if (FValue + 1) > 255 then
    Begin
      FValue:=0;
      Continue;
    end else
    Inc(Fvalue);
  end;
End;

function TFMXHexLucasNumberSequence.Value: byte;
begin
  Result := FValue;
end;

end.


