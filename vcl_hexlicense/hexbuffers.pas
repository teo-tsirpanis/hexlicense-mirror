unit hexbuffers;

{$I vcl.hexlicense.inc}

{$DEFINE HEX_SUPPORT_INTERNET}
{$DEFINE HEX_SUPPORT_VARIANTS}
{$DEFINE HEX_SUPPORT_ZLIB}

interface

uses
{$IFDEF VCL_TARGET}
  {$IFNDEF USE_NEW_UNITNAMES}
    SysUtils, classes, Math, Contnrs
    {$IFDEF HEX_SUPPORT_ZLIB},Zlib{$ENDIF}
    {$IFDEF HEX_SUPPORT_VARIANTS},variants{$ENDIF}
  {$ELSE}
    System.SysUtils, System.classes, System.Math, System.Generics.Collections
  {$IFDEF HEX_SUPPORT_ZLIB},System.Zlib{$ENDIF}
  {$IFDEF HEX_SUPPORT_VARIANTS},System.Variants{$ENDIF}
  {$ENDIF}

{$IFDEF HEX_SUPPORT_INTERNET}
  , IdZLibCompressorBase
  , IdCompressorZLib
  , IdBaseComponent
  , IdComponent
  , IdTCPConnection
  , IdTCPClient
  , IdHTTP
  , idMultipartFormData
{$ENDIF}
  ;
{$ENDIF}

{$IFDEF FMX_TARGET}
  System.SysUtils, System.classes, System.Math, System.Generics.Collections
  {$IFDEF HEX_SUPPORT_ZLIB},System.Zlib{$ENDIF}
  {$IFDEF HEX_SUPPORT_VARIANTS},System.Variants{$ENDIF}
  {$IFDEF HEX_SUPPORT_INTERNET}
  , IdZLibCompressorBase
  , IdCompressorZLib
  , IdBaseComponent
  , IdComponent
  , IdTCPConnection
  , IdTCPClient
  , IdHTTP
  , idMultipartFormData
  {$ENDIF}
  ;
{$ENDIF}

const
CNT_HEX_IOCACHE_SIZE        = 1024 * 10;

CNT_HEX_ANSI_STRING_HEADER  = $DB07;  // Ansi string encoding
CNT_HEX_ASCI_STRING_HEADER  = $DB08;  // Ascii string encoding
CNT_HEX_UNIC_STRING_HEADER  = $DB09;  // unicode string encoding
CNT_HEX_UTF7_STRING_HEADER  = $DB0A;  // UTF7
CNT_HEX_UTF8_STRING_HEADER  = $DB0B;  // UTF8
CNT_HEX_DEFA_STRING_HEADER  = $DB0C;  // Default encoding (Do not localize!)

CNT_HEX_VARIANT_HEADER      = $DB0E;
CNT_HEX_COMPONT_HEADER      = $DBCF;
CNT_RECORD_HEADER           = $BAADBABE;

{$IFDEF SUPPORT_PIDS}
CNT_ALL_PLATFORMS = 0
  {$IFDEF SUPPORT_WIN32} + pidWin32 {$ENDIF}
  {$IFDEF SUPPORT_WIN64} + pidWin64 {$ENDIF}
  ;
{$ENDIF}


type

(* Custom exceptions *)
EHexError            = class(Exception);
EHexPersistent       = class(EHexError);
EHexBufferError      = class(EHexError);
EHexStreamAdapter    = class(EHexError);
EHexReader           = class(EHexError);
EHexWriter           = class(EHexError);
EHexRecordFieldError = class(EHexError);
EHexRecordError      = class(EHexError);
EHexBitAccess        = class(EHexError);
EHexPartAccess       = class(EHexError);
EHexEncoder          = class(EHexError);

(* Forward declarations: work classes *)
THexObject           = class;
THexPersistent       = class;
THexBuffer           = class;
THexReader           = class;
THexWriter           = class;
THexBufferFile       = class;
THexBufferMemory     = class;
THexStreamAdapter    = class;
THexBitAccess        = class;
THexPartsAccess      = class;
THexRecordField      = class;
THexEncoder          = class;

(* Forward declarations: record field classes *)
THexFieldboolean   = class;
THexFieldbyte      = class;
THexFieldCurrency  = class;
THexFieldData      = class;
THexFieldDateTime  = class;
THexFieldDouble    = class;
THexFieldGUID      = class;
THexFieldInteger   = class;
THexFieldInt64     = class;
THexFieldString    = class;
THexFieldLong      = class;

THexObjectclass      = class of THexObject;
THexRecordFieldclass = class of THexRecordField;
THexRecordFieldArray = array of THexRecordFieldclass;

(* custom 3byte record for our FillTriple class procedure *)
PBRTriplebyte = ^THexTriplebyte;
THexTriplebyte = packed record
  a, b, c: byte;
end;

THexObjectState = set of
  (
    osCreating,
    osDestroying,
    osUpdating,
    osReadWrite,
    osSilent
  );

THexDumpOptions = set of (hdSign, hdZeroPad);

  IHexOwnedObject = Interface
  ['{286A5B65-D5F6-4008-8095-7978CE74C666}']
    function  GetParent: TObject;
    procedure SetParent(const Value: TObject);
  End;

  IHexObject = Interface
    ['{FFF8E7BF-ADC9-4245-8717-E9A6C567DED9}']
    procedure SetObjectState(const Value: THexObjectState);
    procedure AddObjectState(const Value: THexObjectState);
    procedure RemoveObjectState(const Value: THexObjectState);
    function  GetObjectState: THexObjectState;
    function  QueryObjectState(const Value: THexObjectState):  boolean;
    function  GetObjectClass: THexObjectClass;
  End;

  IHexPersistent = interface
    ['{282CC310-CD3B-47BF-8EB0-017C1EDF0BFC}']
    procedure   ObjectFrom(const Reader: THexReader);
    procedure   ObjectFromStream(const Stream: TStream;
                const Disposable: boolean);
    procedure   ObjectFromData(const Data: THexBuffer;
                const Disposable: boolean);
    procedure   ObjectFromFile(const Filename: string);

    procedure   ObjectTo(const Writer: THexWriter);
    function    ObjectToStream: TStream; overload;
    procedure   ObjectToStream(const Stream: TStream); overload;
    function    ObjectToData: THexBuffer; overload;
    procedure   ObjectToData(const Data: THexBuffer); overload;
    procedure   ObjectToFile(const Filename: string);
  end;

(* Generic progress events *)
THexProcessBeginsEvent = procedure
  (const Sender: TObject; const Primary: integer) of Object;

THexProcessUpdateEvent = procedure
  (const Sender: TObject; const Value, Primary: integer) of Object;

THexProcessEndsEvent = procedure
  (const Sender: TObject; const Primary, Secondary: integer) of Object;

{$IFDEF HEX_SUPPORT_INTERNET}
  {$IFDEF DELPHI_CLASSIC}
  // Classical delphi, no references so we map to a traditional event
  THexMultiPartCallback = procedure (const Buffer: THexBuffer;
    const Stream: TIdMultiPartFormDataStream) of object;
  {$ELSE}
  // Modern delphi has support for references
  THexMultipartCallback = reference to procedure(const Buffer: THexBuffer;
    const Stream: TIdMultiPartFormDataStream);
  {$ENDIF}
{$ENDIF}

THexSize = class
public
  class function Kilobyte: NativeInt;
  class function Megabyte: NativeInt;
  class function Gigabyte: NativeInt;
  {$IFNDEF NO_UINT64}
  class function Terabyte: UInt64;
  {$ENDIF}

  class function KilobytesIn(ByteCount: int64;
      const Aligned: boolean = true):  NativeInt;

  class function MegabytesIn(ByteCount: int64;
      const Aligned: boolean = true):  NativeInt;

  class function GigabytesIn(ByteCount: int64;
      const Aligned: boolean = true):  NativeInt;

  {$IFNDEF NO_UINT64}
  class function TerabytesIn(ByteCount: UInt64;
      const Aligned: boolean = true):  NativeInt;
  {$ENDIF}

  class function KilobytesOf(Amount: NativeInt):  int64;
  class function MegabytesOf(Amount: NativeInt):  int64;
  class function GigabytesOf(Amount: NativeInt):  int64;
  {$IFNDEF NO_UINT64}
  class function TerabytesOf(Amount: NativeInt;
      const Aligned: boolean = true):  UInt64;
  {$ENDIF}
  class function AsString(const SizeInbytes: int64):  string;
end;

THexRC4EncodingTable = packed record
  etShr: packed array[0..255] of byte;
  etMod: packed array[0..255] of byte;
End;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexEncodingKey = class(TComponent)
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
private
  FEncoder:   THexEncoder;
  FOnBefore:  TNotifyEvent;
  FOnAfter:   TNotifyEvent;
  FOnReset:   TNotifyEvent;
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
protected
  function    GetReady: boolean; virtual; abstract;
  procedure   DoReset; virtual; abstract;
  procedure   DoBuild(const Data; const ByteSize: integer); overload; virtual; abstract;
  procedure   DoBuild(const Data: TStream); overload; virtual; abstract;
  procedure   SetEncoder(const NewEncoder: THexEncoder); virtual;
public
  property    Encoder: THexEncoder read FEncoder write SetEncoder;
  property    Ready: boolean read GetReady;
  procedure   Build(const Data; const ByteSize: integer);
  procedure   Reset;

  procedure   Notification(AComponent: TComponent; Operation: TOperation); override;

  destructor  Destroy; override;
published
  property  OnKeyReset: TNotifyEvent read FOnReset write FOnReset;
  property  OnBeforeKeyBuildt: TNotifyEvent read FOnBefore write FOnBefore;
  property  OnAfterKeyBuilt: TNotifyEvent read FOnAfter write FOnAfter;
end;

THexEncoderBeforeEncodeEvent    = procedure (Sender: TObject; Total: int64) of object;
THexEncoderEncodeProgressEvent  = procedure (Sender: TObject; Offset, Total: int64) of object;
THexEncoderAfterEncodeEvent     = procedure (Sender: TObject; Total: int64) of object;
THexEncoderBeforeDecodeEvent    = procedure (Sender: TObject; Total: int64) of object;
THexEncoderDecodeProgressEvent  = procedure (Sender: TObject; Offset, Total: int64) of object;
THexEncoderAfterDecodeEvent     = procedure (Sender: TObject; Total: int64) of object;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexEncoder = class(TComponent)
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
private
  FCipherKey:     THexEncodingKey;
  FOnEncBegins:   THexEncoderBeforeEncodeEvent;
  FOnEncProgress: THexEncoderEncodeProgressEvent;
  FOnEncEnds:     THexEncoderAfterEncodeEvent;
  FOnDecBegins:   THexEncoderBeforeDecodeEvent;
  FOnDecProgress: THexEncoderDecodeProgressEvent;
  FOnDecEnds:     THexEncoderAfterDecodeEvent;
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
protected
  function    GetReady: boolean; virtual;
  procedure   SetKey(const NewKey: THexEncodingKey); virtual;
public
  property    Ready: boolean read GetReady;

  function    EncodePtr(const Source; const Target; ByteLen: int64): int64; virtual; abstract;
  function    EncodeStream(Source, Target: TStream): int64; virtual; abstract;

  function    DecodePtr(const Source; const Target; ByteLen: int64): int64; virtual; abstract;
  function    DecodeStream(Source, Target: TStream): int64; virtual; abstract;

  // Returns the size you should allocate for the target buffer.
  // Some ciphers will return encoded data that is larger than the original
  // byte-length of the source.
  function    GetResultSizeOf(const PreSize: int64): int64; virtual;

  // These access the above methods, no need to re-implement
  function    EncodeBuffer(const Source, Target: THexBuffer): int64; virtual;
  function    DecodeBuffer(const Source, Target: THexBuffer): int64; virtual;

  procedure   Notification(AComponent: TComponent; Operation: TOperation); override;

  procedure   Reset; virtual;
published
  property  Key: THexEncodingKey read FCipherKey write SetKey;
  property  OnEncodingBegins: THexEncoderBeforeEncodeEvent read FOnEncBegins write FOnEncBegins;
  property  OnEncodingProgress: THexEncoderEncodeProgressEvent read FOnEncProgress write FOnEncProgress;
  property  OnEncodingEnds: THexEncoderAfterEncodeEvent read FOnEncEnds write FOnEncEnds;

  property  OnDecodingBegins: THexEncoderBeforeDecodeEvent read FOnDecBegins write FOnDecBegins;
  property  OnDecodingProgress: THexEncoderDecodeProgressEvent read FOnDecProgress write FOnDecProgress;
  property  OnDecodingEnds: THexEncoderAfterDecodeEvent read FOnDecEnds write FOnDecEnds;
end;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexKeyRC4 = class(THexEncodingKey)
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
private
  FReady:   boolean;
  FTable:   THexRC4EncodingTable;
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
protected
  function  GetReady: boolean; override;
  procedure DoReset; override;
  procedure DoBuild(const Data; const ByteSize: integer); override;
  procedure DoBuild(const Data: TStream); override;
public
  property  Table: THexRC4EncodingTable read FTable;
end;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexEncoderRC4 = class(THexEncoder)
public
  function  EncodePtr(const Source; const Target; ByteLen: int64): int64; override;
  function  DecodePtr(const Source; const Target; ByteLen: int64): int64; override;

  function  GetResultSizeOf(const PreSize: int64): int64; override;

  function  EncodeStream(Source, Target: TStream): int64; override;
  function  DecodeStream(Source, Target: TStream): int64; override;
end;

{THexUserEncodeEvent = procedure (Sender: TObject; InByte: byte; var OutByte: byte) of object;
THexUserDecodeEvent = procedure (Sender: TObject; InByte: byte; var OutByte: byte) of object;

THexEncoderUser = class(THexEncoder)
private
  FOnEncode: THexUserEncodeEvent;
  FOnDecode: THexUserDecodeEvent;
public
  function  EncodePtr(const Source; const Target; ByteLen: int64): boolean; override;
  function  EncodeStream(Source, Target: TStream): boolean; override;
  function  DecodePtr(const Source; const Target; ByteLen: int64): boolean; override;
  function  DecodeStream(Source, Target: TStream): boolean; override;
published
  property  OnEncodeData: THexUserEncodeEvent read FOnEncode write FOnEncode;
  property  OnDecodeData: THexUserDecodeEvent read FOnDecode write FOnDecode;
end;    }

THexObject = class(TPersistent, IHexOwnedObject, IHexObject)
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
private
  FState:     THexObjectState;
  FParent:    TObject;
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
protected
  (* Implements:: IHexOwnedObject *)
  function    GetParent:TObject; virtual;
  procedure   SetParent(const Value:TObject);
  property    Parent: TObject read GetParent;

  (* Implements:: IHexObject *)
  procedure   SetObjectState(const Value: THexObjectState);
  procedure   AddObjectState(const Value: THexObjectState);
  procedure   RemoveObjectState(const Value: THexObjectState);
  function    QueryObjectState(const Value: THexObjectState):  boolean;
  function    GetObjectState: THexObjectState;
  function    GetObjectclass: THexObjectclass;
protected
  (* implements:: IUnknown *)
  function    QueryInterface(const IID:TGUID; out Obj): HResult; virtual; stdcall;
  function    _AddRef: integer; virtual; stdcall;
  function    _Release: integer; virtual; stdcall;
public
  class function ObjectPath: string;
  procedure   AfterConstruction; override;
  procedure   BeforeDestruction; override;
  constructor Create; virtual;
End;

THexPersistent = class(THexObject, IHexPersistent)
private
  FObjId:     Longword;
  FUpdCount:  integer;
{$IFDEF SUPPORT_STRICT}strict{$ENDIF}
protected
  (* Implements:: IHexPersistent *)
  procedure   ObjectTo(const Writer: THexWriter);
  procedure   ObjectFrom(const Reader: THexReader);
  procedure   ObjectFromStream(const Stream: TStream;
              const Disposable: boolean);
  function    ObjectToStream: TStream; overload;
  procedure   ObjectToStream(const Stream: TStream); overload;
  procedure   ObjectFromData(const Binary: THexBuffer;
              const Disposable: boolean);
  function    ObjectToData: THexBuffer; overload;
  procedure   ObjectToData(const Binary: THexBuffer); overload;
  procedure   ObjectFromFile(const Filename: string);
  procedure   ObjectToFile(const Filename: string);
protected
  procedure   BeforeUpdate; virtual;
  procedure   AfterUpdate; virtual;
protected
  (* Persistency Read/Write methods *)
  procedure   BeforeReadObject; virtual;
  procedure   AfterReadObject; virtual;
  procedure   BeforeWriteObject; virtual;
  procedure   AfterWriteObject; virtual;
  procedure   WriteObject(const Writer: THexWriter); virtual;
  procedure   ReadObject(const Reader: THexReader); virtual;
protected
  (* Standard persistence *)
  function    ObjectHasData: boolean; virtual;
  procedure   ReadObjBin(Stream: TStream); virtual;
  procedure   WriteObjBin(Stream: TStream); virtual;
  procedure   DefineProperties(Filer: TFiler); override;
public
  property    UpdateCount:integer read FUpdCount;

  procedure   Assign(Source:TPersistent); override;

  function    ObjectIdentifier: longword;

  function    BeginUpdate: boolean;
  procedure   EndUpdate;

  class function classIdentifier: longword;

  constructor Create; override;
End;


(* This class allows you to access a buffer regardless of how its
   implemented, through a normal stream. This makes it very easy to
   use buffers with standard VCL components and classes *)
THexStreamAdapter = class(TStream)
private
  FBufObj: THexBuffer;
  FOffset: int64;
protected
  function GetSize: Int64; override;
  procedure SetSize(const NewSize: Int64); override;
public
  property BufferObj: THexBuffer read FBufObj;
public
  function Read(var Buffer; Count: longint):  longint; override;
  function Write(const Buffer;Count: longint):  longint; override;
  function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  constructor Create(const SourceBuffer: THexBuffer);reintroduce;
end;

(* Buffer capability enum. Different buffer types can have different
   rules. Some buffers can be read only, depending on the application,
   while others may be static - meaning that it cannot grow in size *)
THexBufferCapabilities = set of (
    mcScale,  // Can scale
    mcOwned,  // Buffer originates elsewhere, dont explicitly release
    mcRead,   // Buffer can be read
    mcWrite   // Buffer can be written to
  );

(* Data cache byte array type. Read and write operations process data in
   fixed chunks of this type *)
THexIOCache = packed Array [1..CNT_HEX_IOCACHE_SIZE] of byte;

(* This is the basic buffer class. It is an abstract class and should not be
   created. Create objects from classes that decend from this and that
   implements the buffering you need to work with (memory, stream, temp etc *)
{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexBuffer = class(TComponent)
private
  (* Buffer capabilities. I.E: Readable, writeable etc. *)
  FCaps: THexBufferCapabilities;

  {$IFDEF HEX_SUPPORT_ZLIB}
  FOnCompressionBegins:  THexProcessBeginsEvent;
  FOnCompressionUpdate:  THexProcessUpdateEvent;
  FOnCompressionEnds:    THexProcessEndsEvent;
  FOnDeCompressionBegins:  THexProcessBeginsEvent;
  FOnDeCompressionUpdate:  THexProcessUpdateEvent;
  FOnDeCompressionEnds:    THexProcessEndsEvent;
  {$ENDIF}

  FEncryption: THexEncoder;

  procedure SetSize(const NewSize: Int64);
protected
  (*  Standard persistence. Please note that we call the function
      ObjectHasData() to determine if there is anything to save.
      See extended persistence below for more information.

      NOTE: Do not override these methods, use the functions defined
            in extended persistance when modifying this object *)
  procedure ReadObjBin(Stream: TStream);
  procedure WriteObjBin(Stream: TStream);
  procedure DefineProperties(Filer: TFiler); override;
protected
  (*  Extended persistence.
      The function ObjectHasData() is called by the normal VCL
      DefineProperties to determine if there is any data to save.
      The other methods are invoked before and after either loading or
      saving object data.

      NOTE: To extend the functionality of this object please override
      ReadObject() and WriteObject(). The object will take care of
      everything else. *)
  function ObjectHasData: boolean;
  procedure BeforeReadObject; virtual;
  procedure AfterReadObject; virtual;
  procedure BeforeWriteObject; virtual;
  procedure AfterWriteObject; virtual;
  procedure ReadObject(Reader: TReader); virtual;
  procedure WriteObject(Writer: TWriter); virtual;
protected
  (* Call this to determine if the object is empty (holds no data) *)
  function GetEmpty: boolean; virtual;

  procedure SetEncryption(const NewEncoder: THexEncoder); virtual;

protected
  (* Actual Buffer implementation. Decendants must override and
     implement these methods. It does not matter where or how the
     data is stored - this is up to the implementation. *)
  function DoGetCapabilities: THexBufferCapabilities; virtual;abstract;
  function DoGetDataSize: Int64; virtual;abstract;
  procedure DoReleaseData; virtual;abstract;
  procedure DoGrowDataBy(const Value: integer); virtual;abstract;
  procedure DoShrinkDataBy(const Value: integer); virtual;abstract;
  procedure DoReadData(Start: Int64; var Buffer;
      BufLen: integer); virtual;abstract;
  procedure DoWriteData(Start: int64; const Buffer;
      BufLen: integer); virtual;abstract;
  procedure DoFillData(Start: Int64; FillLength: Int64;
            const Data; DataLen: integer); virtual;
  procedure DoZeroData; virtual;
public
  property    Empty: boolean read GetEmpty;
  property    Capabilities: THexBufferCapabilities read FCaps;

  procedure   Assign(Source: TPersistent); override;

  (* Read from buffer into memory *)
  function    Read(const ByteIndex: int64; DataLength: integer; var Data):  integer; overload;

  (* Write to buffer from memory *)
  function    Write(const ByteIndex: int64; DataLength: integer; const Data):  integer; overload;

  (* Append data to end-of-buffer from various sources *)
  procedure   Append(const Buffer:THexBuffer); overload;
  procedure   Append(const Stream: TStream); overload;
  procedure   Append(const Data;const DataLength:integer); overload;

  (* Fill the buffer with a repeating pattern of data *)
  function    Fill(const ByteIndex: int64;
              const FillLength: int64;
              const DataSource; const DataSourceLength: integer):  int64;

  (* Fill the buffer with the value zero *)
  procedure   Zero;

  (*  Insert data into the buffer. Note: This is not a simple "overwrite"
      insertion. It will inject the new data and push whatever data is
      successive to the byteindex forward *)
  procedure   Insert(const ByteIndex: int64;const Source; DataLength: integer); overload;
  procedure   Insert(ByteIndex: int64; const Source:THexBuffer); overload;

  (* Remove X number of bytes from the buffer at any given position *)
  procedure   Remove(const ByteIndex: int64; DataLength: integer);

  (* Simple binary search inside the buffer *)
  function Search(const Data; const DataLength: integer; var FoundbyteIndex: int64):  boolean;

  (*  Push data into the buffer from the beginning, which moves the current
      data already present forward *)
  function    Push(const Source; DataLength:integer):  integer;

  (* Poll data out of buffer, again starting at the beginning of the buffer.
     The polled data is removed from the buffer *)
  function    Pull(Var Target; DataLength:integer):  integer;

  (* Generate a normal DWORD ELF-hashcode from the content *)
  function    HashCode: Longword; virtual;

  (* Standard IO methods. Please note that these are different from those
     used by persistence. These methods does not tag the content but loads
     it directly. The methods used by persistentse will tag the data with
     a length variable *)
  procedure   LoadFromFile(Filename: string);
  procedure   SaveToFile(Filename: string);
  procedure   SaveToStream(Stream: TStream);
  procedure   LoadFromStream(Stream: TStream);

  (* Export data from the buffer into various output targets *)
  function    ExportTo(ByteIndex: Int64; DataLength: integer; const Writer: TWriter):  integer;

  (* Import data from various input sources *)
  function    ImportFrom(ByteIndex: Int64; DataLength: integer; const Reader:TReader):  integer;

  {$IFDEF HEX_SUPPORT_ZLIB}
  procedure   CompressTo(const Target: THexBuffer); overload;
  procedure   DeCompressFrom(const Source: THexBuffer); overload;
  function    CompressTo: THexBuffer; overload;
  function    DecompressTo: THexBuffer; overload;
  procedure   Compress;
  procedure   Decompress;
  {$ENDIF}

  property    Encryption: THexEncoder read FEncryption write SetEncryption;
  procedure   EncryptTo(const Target: THexBuffer); overload;
  procedure   DecryptFrom(const Source: THexBuffer); overload;
  function    EncryptTo: THexBuffer; overload;
  function    DecryptTo: THexBuffer; overload;
  procedure   Encrypt;
  procedure   Decrypt;

  (* release the current content of the buffer *)
  procedure   Release;
  procedure   AfterConstruction; override;
  procedure   BeforeDestruction; override;

  procedure   Notification(AComponent: TComponent; Operation: TOperation);override;

  (* Generic ELF-HASH methods *)
  class function ElfHash(const Data; DataLength: integer): longword; overload;
  class function ElfHash(const Text: string):  longword; overload;

  (* Kernigan and Ritchie Hash ["the C programming language"] *)
  class function KAndRHash(const Data; DataLength: integer):  longword; overload;
  class function KAndRHash(const Text: string):  longword; overload;

  (* Generic Adler32 hash *)
  class function AdlerHash(const Adler: Cardinal; const Data; DataLength: integer):  longword; overload;
  class function AdlerHash(const Data; DataLength: integer):  longword; overload;
  class function AdlerHash(const Text: string):  longword; overload;

  class function BorlandHash(const Data; DataLength: integer):  longword; overload;
  class function BorlandHash(const Text: string):  longword; overload;

  class function BobJenkinsHash(const Data; DataLength: integer):  longword; overload;
  class function BobJenkinsHash(const Text: string):  longword; overload;

  {$IFDEF HEX_SUPPORT_INTERNET}
  procedure   HttpGet(RemoteURL: string);

  // No Result, content is posted
  procedure   HttpPost(RemoteURL: string;
              const ContentType: string); overload;

  // External response
  procedure   HttpPost(RemoteURL: string;
              const Response: THexBuffer;
              const ContentType: string); overload;

  // Result in SELF
  procedure   HttpPost(RemoteURL: string;
              const FormFields: TStrings); overload;

  // Result in SELF
  procedure   HttpPost(RemoteURL: string;
              const Populate: THexMultipartCallback); overload;
  {$ENDIF}

  function  ToString(BytesPerRow: integer = 16;
            const Options: THexDumpOptions = [hdSign, hdZeroPad]) : string;
            reintroduce; virtual;

  (* Generic memory fill methods *)
  class procedure FillByte(Target: Pbyte;
        const FillSize: integer; const Value: byte);

  class procedure FillWord(Target: PWord;
          const FillSize: integer; const Value: word);

  class procedure FillTriple(dstAddr: PBRTriplebyte;
        const InCount: integer; const Value: THexTriplebyte);

  class procedure FillLong(dstAddr:PLongword;
        const InCount: integer; const Value: Longword);

published
  property Size: int64 read DoGetDataSize write SetSize;
  {$IFDEF HEX_SUPPORT_ZLIB}
  property OnCompressionBegins:  THexProcessBeginsEvent read FOnCompressionBegins write FOnCompressionBegins;
  property OnCompressionUpdate:  THexProcessUpdateEvent read FOnCompressionUpdate write FOnCompressionUpdate;
  property OnCompressionEnds:    THexProcessEndsEvent read FOnCompressionEnds write FOnCompressionEnds;
  property OnDeCompressionBegins:  THexProcessBeginsEvent read FOnDeCompressionBegins write FOnDeCompressionBegins;
  property OnDeCompressionUpdate:  THexProcessUpdateEvent read FOnDeCompressionUpdate write FOnDeCompressionUpdate;
  property OnDeCompressionEnds:    THexProcessEndsEvent read FOnDeCompressionEnds write FOnDeCompressionEnds;
  {$ENDIF}
end;

(* This class implements a memory buffer. It allows you to allocate and
   manipulate data in-memory, more or less like AllocMem but with
   extended functionality *)
{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexBufferMemory = class(THexBuffer)
private
  FDataPTR:   Pbyte;
  FDataLen:   integer;
protected
  function    BasePTR:Pbyte;
  function    AddrOf(const byteIndex:Int64): Pbyte;
protected
  function    DoGetCapabilities:THexBufferCapabilities; override;
  function    DoGetDataSize:Int64; override;
  procedure   DoReleaseData; override;

  procedure   DoReadData(Start: Int64; var Buffer;
              BufLen: integer); override;

  procedure   DoWriteData(Start: Int64;const Buffer;
              BufLen: integer); override;

  procedure   DoFillData(Start: Int64; FillLength: Int64;
              const Data; DataLen: integer); override;

  procedure   DoGrowDataBy(const Value: integer); override;
  procedure   DoShrinkDataBy(const Value: integer); override;
  procedure   DoZeroData; override;
public
  property    Data: Pbyte read FDataPTR;
end;

(* This class implements a file-based buffer *)
{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexBufferFile = class(THexBuffer)
private
  FFilename:  string;
  FFile:      TStream;
protected
  function    GetActive: boolean;
  function    GetEmpty: boolean; override;
protected
  function    DoGetCapabilities: THexBufferCapabilities; override;
  function    DoGetDataSize: Int64; override;
  procedure   DoReleaseData; override;
  procedure   DoReadData(Start: Int64; var Buffer; BufLen: integer); override;
  procedure   DoWriteData(Start: Int64;const Buffer; BufLen:integer); override;
  procedure   DoGrowDataBy(const Value:integer); override;
  procedure   DoShrinkDataBy(const Value:integer); override;
public
  property    Filename: string read FFilename;
  property    Active: boolean read GetActive;
  procedure   Open(aFilename: string; StreamFlags: Word); virtual;
  procedure   Close; virtual;
public
  procedure   BeforeDestruction; override;
  constructor CreateEx(aFilename: string; StreamFlags: Word); overload;
end;

(* Abstract reader class *)
THexReader = class
private
  FOffset:    Int64;
  FEncoding:  TEncoding;
protected
  procedure   Advance(const Value:integer);
public
  property    Position: Int64 read FOffset;
  property    TextEncoding: TEncoding read FEncoding write FEncoding;
  function    ReadNone(Length: integer):  integer;
  function    ReadPointer: pointer;
  function    Readbyte: byte;
  function    ReadBool: boolean;
  function    ReadWord: word;
  function    ReadSmall: smallint;
  function    ReadInt: integer;
  function    ReadLong: longword;
  function    ReadInt64: int64;
  function    ReadCurrency: currency;
  function    ReadDouble: double;
  function    ReadShort: shortint;
  function    ReadSingle: single;
  function    ReadDateTime: TDateTime;
  function    ReadGUID: TGUID;

  function    ReadString: string; overload;

  function    CopyTo(const Writer: THexWriter; CopyLen: integer):  integer; overload;
  function    CopyTo(const Stream: TStream; const CopyLen: integer):  integer; overload;
  function    CopyTo(const Binary:THexBuffer; const CopyLen: integer):  integer; overload;

  function    ReadStream: TStream;
  function    ReadData: THexBuffer;
  function    ContentToStream: TStream;
  function    ContentToData: THexBuffer;

  {$IFDEF HEX_SUPPORT_VARIANTS}
  function    ReadVariant: variant;
  {$ENDIF}
  procedure   Reset; virtual;

  function    Read(var Data; DataLen: integer):  integer; virtual; abstract;
end;

(* Abstract writer class *)
THexWriter = class
private
  FOffset:    Int64;
  FEncoding:  TEncoding;
protected
  procedure   Advance(const Value: integer);
  procedure   __FillWord(dstAddr: PWord; const inCount: integer;
              const Value: Word);
public
  property    TextEncoding: TEncoding read FEncoding write FEncoding;
  procedure   WritePointer(const Value: pointer);
  {$IFDEF HEX_SUPPORT_VARIANTS}
  procedure   WriteVariant(const Value: variant);
  {$ENDIF}
  procedure   WriteCRLF(const Times: integer=1);
  procedure   Writebyte(const Value: byte);
  procedure   WriteBool(const Value: boolean);
  procedure   WriteWord(const Value: word);
  procedure   WriteShort(const Value: shortint);
  procedure   WriteSmall(const Value: smallInt);
  procedure   WriteInt(const Value: integer);
  procedure   WriteLong(const Value: longword);
  procedure   WriteInt64(const Value: int64);
  procedure   WriteCurrency(const Value: currency);
  procedure   WriteDouble(const Value: double);
  procedure   WriteSingle(const Value: single);
  procedure   WriteDateTime(const Value: TDateTime);

  procedure   Writestring(const Text: string); overload;
  procedure   Writestring(const Text: string;const Encoding: TEncoding); overload;

  procedure   WriteStreamContent(const Content: TStream; const Disposable: boolean = false);
  procedure   WriteDataContent(const Content: THexBuffer; const Disposable: boolean = false);
  procedure   WriteStream(const Value: TStream; const Disposable: boolean);
  procedure   WriteData(const Data: THexBuffer; const Disposable: boolean);
  procedure   WriteGUID(const Value: TGUID);
  procedure   WriteFile(const Filename: string);
  function    CopyFrom(const Reader: THexReader;DataLen: Int64):  Int64; overload;
  function    CopyFrom(const Stream: TStream;const DataLen: Int64):  Int64; overload;
  function    CopyFrom(const Data: THexBuffer;const DataLen: Int64):  Int64; overload;
  function    Write(const Data; DataLen: integer):  integer; virtual;abstract;
  property    Position: Int64 read FOffset;
  procedure   Reset; virtual;
end;

(* Writer class for buffers *)
THexWriterBuffer = class(THexWriter)
private
  FData: THexBuffer;
public
  property Data: THexBuffer read FData;
  function Write(const Data; DataLen: integer):  integer; override;
  constructor Create(const Target: THexBuffer);reintroduce;
end;

(* Reader class for buffers *)
THexReaderBuffer = class(THexReader)
private
  FData:      THexBuffer;
public
  function    Read(var Data; DataLen: integer):  integer; override;
  constructor Create(const Source: THexBuffer);reintroduce;
end;

(* writer class for stream *)
THexWriterStream = class(THexWriter)
private
  FStream:    TStream;
public
  property    DataStream: TStream read FStream;
  function    Write(const Data; DataLen: integer):  integer; override;
  constructor Create(const Target: TStream);reintroduce;
end;

(* reader class for stream *)
THexReaderStream = class(THexReader)
private
  FStream:    TStream;
public
  function    Read(var Data; DataLen: integer):  integer; override;
  constructor Create(const Source: TStream);reintroduce;
end;

(* Bit-level access to a buffer *)
{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexBitAccess = class(TComponent)
{$IFDEF SUPPORT_STRICT} strict {$ENDIF}
private
  FBuffer:    THexBuffer;
  function    ReadBit(const BitIndex: NativeInt):  boolean;
  procedure   WriteBit(const BitIndex: NativeInt; const Value: boolean);
  function    GetCount: NativeUInt;
  procedure   SetBuffer(NewBuffer: THexBuffer);
public
  property    Bits[const BitIndex:NativeInt]: boolean read ReadBit write WriteBit;
  property    Count: NativeUInt read GetCount;
  function    FindIdleBit(const FromIndex: NativeUInt;
              out IdleBitIndex: NativeUInt):  boolean;
  function    AsString(const CharsPerLine: integer = 32):  string;

  procedure   Notification(AComponent: TComponent; Operation: TOperation); override;
published
  property    Buffer: THexBuffer read FBuffer write SetBuffer;
end;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexPartsAccess = class(TComponent)
private
  FBuffer:    THexBuffer;
  FheadSize:  integer;
  FPartSize:  integer;
protected
  procedure   SetBuffer(const NewBuffer: THexBuffer); virtual;
  function    GetPartCount: integer;
  function    GetOffsetForPart(const PartIndex: integer): Int64;
public
  property    ReservedHeaderSize: integer read FheadSize;
  property    PartSize: integer read FPartSize;
  property    Count: integer read GetPartCount;

  procedure   ReadPart(const PartIndex: integer; var Data); overload;
  procedure   ReadPart(const PartIndex: integer;const Data: THexBuffer); overload;

  procedure   WritePart(const PartIndex: integer;
              const Data; const DataLength:integer); overload;

  procedure   WritePart(const PartIndex: integer;const Data:THexBuffer); overload;

  procedure   AppendPart(const Data; DataLength: integer); overload;
  procedure   AppendPart(const Data: THexBuffer); overload;

  procedure   Notification(AComponent: TComponent; Operation: TOperation);override;

  function    CalcPartsForData(const DataSize: Int64):  NativeInt;

  procedure   Setup(const ReservedHeaderSize: integer; const PartSize: integer); virtual;

published
  property  Buffer: THexBuffer read FBuffer write SetBuffer;
end;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexRecordField = class(THexBufferMemory)
private
  FName:      string;
  FNameHash:  Int64;
  FOnRead:    TNotifyEvent;
  FOnWrite:   TNotifyEvent;
  FOnRelease: TNotifyEvent;
  procedure   SetRecordName(NewName: string);
protected
  function    GetDisplayName: string; virtual;
  procedure   BeforeReadObject; override;
  procedure   ReadObject(Reader:TReader); override;
  procedure   WriteObject(Writer:TWriter); override;
  procedure   DoReleaseData; override;
protected
  procedure   SignalWrite;
  procedure   SignalRead;
  procedure   SignalRelease;
public
  function    AsString: string; virtual;abstract;
  property    DisplayName: string read GetDisplayName;
  property    FieldSignature:Int64 read FNameHash;
published
  property    OnValueRead: TNotifyEvent read FOnRead write FOnRead;
  property    OnValueWrite: TNotifyEvent read FOnWrite write FOnWrite;
  property    OnValueRelease: TNotifyEvent read FOnRelease write FOnRelease;
  property    FieldName: string read FName write SetRecordName;
end;


THexFieldboolean = class(THexRecordField)
private
  function    GetValue: boolean;
  procedure   SetValue(const NewValue: boolean);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value: boolean read GetValue write SetValue;
end;

THexFieldbyte = class(THexRecordField)
private
  function    GetValue:byte;
  procedure   SetValue(const NewValue:byte);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:byte read GetValue write SetValue;
end;

THexFieldCurrency = class(THexRecordField)
private
  function    GetValue:Currency;
  procedure   SetValue(const NewValue:Currency);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:Currency read GetValue write SetValue;
end;

THexFieldData = class(THexRecordField)
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
end;

THexFieldDateTime = class(THexRecordField)
private
  function    GetValue:TDateTime;
  procedure   SetValue(const NewValue:TDateTime);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:TDateTime read GetValue write SetValue;
end;

THexFieldDouble = class(THexRecordField)
private
  function    GetValue:Double;
  procedure   SetValue(const NewValue:Double);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:Double read GetValue write SetValue;
end;

THexFieldGUID = class(THexRecordField)
private
  function    GetValue:TGUID;
  procedure   SetValue(const NewValue:TGUID);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:TGUID read GetValue write SetValue;
end;

THexFieldInteger = class(THexRecordField)
private
  function    GetValue: integer;
  procedure   SetValue(const NewValue:integer);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:integer read GetValue write SetValue;
end;

THexFieldInt64 = class(THexRecordField)
private
  function    GetValue:Int64;
  procedure   SetValue(const NewValue:Int64);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value:Int64 read GetValue write SetValue;
end;

THexFieldString = class(THexRecordField)
private
  FLength:    integer;
  FExplicit:  boolean;
  function    GetValue: string;
  procedure   SetValue(NewValue: string);
  procedure   SetFieldLength(Value:integer);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
  constructor Create(AOwner: TComponent); override;
published
  property    Value: string read GetValue write SetValue;
  property    Length: integer read FLength write SetFieldLength;
  property    Explicit: boolean read FExplicit write FExplicit;
end;

THexFieldLong = class(THexRecordField)
private
  function    GetValue:Longword;
  procedure   SetValue(const NewValue:Longword);
protected
  function    GetDisplayName: string; override;
public
  function    AsString: string; override;
published
  property    Value: Longword read GetValue write SetValue;
end;

THexCustomRecord = class(TComponent)
private
  // If the new unit-names are not supported, then generics is
  // not available anyways -- so fall back on older TObjectList
  {$IFNDEF USE_NEW_UNITNAMES}
  FObjects:   TObjectList;
  {$ELSE}
  FObjects:   TObjectList<THexRecordField>;
  {$ENDIF}
  function    GetCount: integer;
  function    GetItem(const Index:integer): THexRecordField;
  procedure   SetItem(const Index: integer;
              const Value:THexRecordField);
  function    GetField(const FieldName: string): THexRecordField;
  procedure   SetField(const FieldName: string;
              const Value:THexRecordField);
protected
  property    Fields[const FieldName: string]: THexRecordField
              read GetField write SetField;
  property    Items[const index:integer]: THexRecordField
              read GetItem write SetItem;
  property    Count:integer read GetCount;
public
  function    Add(const FieldName: string;
              const Fieldclass: THexRecordFieldclass): THexRecordField;
  function    Addinteger(const FieldName: string): THexFieldInteger;
  function    AddStr(const FieldName: string): THexFieldString;
  function    Addbyte(const FieldName: string): THexFieldbyte;
  function    AddBool(const FieldName: string): THexFieldboolean;
  function    AddCurrency(const FieldName: string): THexFieldCurrency;
  function    AddData(const FieldName: string): THexFieldData;
  function    AddDateTime(const FieldName: string): THexFieldDateTime;
  function    AddDouble(const FieldName: string): THexFieldDouble;
  function    AddGUID(const FieldName: string):  THexFieldGUID;
  function    AddInt64(const FieldName: string): THexFieldInt64;
  function    AddLong(const FieldName: string): THexFieldLong;

  procedure   WriteInt(const FieldName: string;const Value: integer);
  procedure   WriteStr(const FieldName: string;const Value: string);
  procedure   Writebyte(const FieldName: string;const Value: byte);
  procedure   WriteBool(const FieldName: string;const Value: boolean);
  procedure   WriteCurrency(const FieldName: string;const Value: currency);
  procedure   WriteData(const FieldName: string;const Value: TStream);
  procedure   WriteDateTime(const FieldName: string;const Value: TDateTime);
  procedure   WriteDouble(const FieldName: string;const Value: double);
  procedure   WriteGUID(const FieldName: string;const Value: TGUID);
  procedure   WriteInt64(const FieldName: string; const Value: int64);
  procedure   WriteLong(const FieldName: string; const Value: longword);

  procedure   Clear; virtual;

  procedure   Assign(source: TPersistent); override;

  function    ToStream: TStream; virtual;
  function    ToBuffer: THexBuffer; virtual;

  procedure   SaveToStream(const Stream: TStream); virtual;
  procedure   LoadFromStream(const Stream: TStream); virtual;

  function    IndexOf(FieldName: string):  integer;
  function    ObjectOf(FieldName: string): THexRecordField;
  constructor Create(AOwner: TComponent); override;
  destructor  Destroy; override;
end;

{$IFDEF SUPPORT_PIDS}
[ComponentPlatformsAttribute(CNT_ALL_PLATFORMS)]
{$ENDIF}
THexRecord = class(THexCustomRecord)
public
  property  Fields;
  property  Items;
  property  Count;
end;

procedure HexRegisterRecordField(AClass: THexRecordFieldclass);

function  HexRecordFieldKnown(AClass: THexRecordFieldclass):  boolean;

function  HexRecordFieldClassFromName(aName: string;
          var Aclass: THexRecordFieldClass):  boolean;

function  HexRecordInstanceFromName(aName: string;
          out Value:THexRecordField):  boolean;

function HexStrToGUID(const Value: Ansistring):  TGUID;
function HexGUIDToStr(const GUID: TGUID):  Ansistring;


implementation


const
CNT_VOLUME_UNIT_POSTFIX: ARRAY[0..6] of PChar = ('bytes',
  'Kb', 'Mb', 'Gb',
  'Tb', 'Pb', 'Eb'
);

CNT_VOLUME_UNIT_NAMES: ARRAY[0..6] of PChar = ('byte',
  'Kilobyte', 'Megabyte', 'Gigabyte',
  'Terabyte', 'Petabyte', 'Exabyte'
);

CNT_VOLUME_UNIT_SIZES: Array [0..6] of UInt64 = (
  1, 1024, 1048576, 1073741824,
  1099511627776, 1125899906842624, 1152921504606846976
);

//###########################################################################
// Persistancy errors
//###########################################################################

ERR_HEX_PERSISTENCY_ASSIGNCONFLICT
= '%s can not be assigned to %s ';

ERR_HEX_PERSISTENCY_INVALIDSIGNATURE
= 'Invalid signature, found %s, expected %s';

ERR_HEX_PERSISTENCY_INVALIDREADER
= 'Invalid reader object error';

ERR_HEX_PERSISTENCY_INVALIDWRITER
= 'Invalid writer object error';

//###########################################################################
// Record management errors
//###########################################################################

ERR_RECORDFIELD_INVALIDNAME =
'Invalid field name [%s] error';

ERR_RECORDFIELD_FailedSet =
'Writing to field buffer [%s] failed error';

ERR_RECORDFIELD_FailedGet =
'Reading from field buffer [%s] failed error';

ERR_RECORDFIELD_FieldIsEmpty
= 'Record field is empty [%s] error';

//###########################################################################
// byterage errors
//###########################################################################

CNT_ERR_BTRG_BASE  = 'Method %s threw exception %s with %s';

CNT_ERR_BTRG_RELEASENOTSUPPORTED
= 'Buffer capabillities does not allow release';

CNT_ERR_BTRG_SCALENOTSUPPORTED
= 'Buffer capabillities does not allow scaling';

CNT_ERR_BTRG_READNOTSUPPORTED
= 'Buffer capabillities does not allow read';

CNT_ERR_BTRG_WRITENOTSUPPORTED
= 'Buffer capabillities does not allow write';

CNT_ERR_BTRG_SOURCEREADNOTSUPPORTED
= 'Capabillities of datasource does not allow read';

CNT_ERR_BTRG_TARGETWRITENOTSUPPORTED
= 'Capabillities of data-target does not allow write';

CNT_ERR_BTRG_SCALEFAILED
= 'Memory scale operation failed: %s';

CNT_ERR_BTRG_BYTEINDEXVIOLATION
= 'Memory byte index violation, expected %d..%d not %d';

CNT_ERR_BTRG_INVALIDDATASOURCE
= 'Invalid data-source for operation';

CNT_ERR_BTRG_INVALIDDATATARGET
= 'Invalid data-target for operation';

CNT_ERR_BTRG_EMPTY
= 'Memory resource contains no data error';

CNT_ERR_BTRG_NOTACTIVE
= 'File is not active error';

CNT_ERR_BTRGSTREAM_INVALIDBUFFER
= 'Invalid buffer error, buffer is NIL';


//###########################################################################
// Error messages for reader decendants
//###########################################################################

ERR_HEX_READER_INVALIDSOURCE      = 'Invalid source medium error';
ERR_HEX_READER_FAILEDREAD         = 'Read failed on source medium';
ERR_HEX_READER_INVALIDDATASOURCE  = 'Invalid data source for read operation';
ERR_HEX_READER_INVALIDOBJECT      = 'Invalid object for read operation';
ERR_HEX_READER_INVALIDHEADER      = 'Invalid header, expected %d not %d';

(* Error messages for THexWriter decendants *)
ERR_HEX_WRITER_INVALIDTARGET       = 'Invalid target medium error';
ERR_HEX_WRITER_FAILEDWRITE         = 'Write failed on target medium';
ERR_HEX_WRITER_INVALIDDATASOURCE   = 'Invalid data source for write operation';
ERR_HEX_WRITER_INVALIDOBJECT       = 'Invalid object for write operation';

CNT_PARTACCESS_BUFFERISNIL = 'Buffer cannot be NIL error';
CNT_PARTACCESS_PARTSIZEINVALID  = 'Invalid partsize error';
CNT_PARTACCESS_TARGETBUFFERINVALID  = 'Invalid target buffer error';

type
TRCByteArray = packed array[0..4095] of byte;
PRCByteArray = ^TRCByteArray;


Var
_Fieldclasses:  THexRecordFieldArray;


function HexGUIDToStr(const GUID: TGUID):  Ansistring;
begin
  SetLength(result, 38);
  StrLFmt(@result[1],38,'{%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x}',
  [GUID.D1, GUID.D2, GUID.D3, GUID.D4[0], GUID.D4[1], GUID.D4[2], GUID.D4[3],
  GUID.D4[4], GUID.D4[5], GUID.D4[6], GUID.D4[7]]);
end;

function HexStrToGUID(const Value:Ansistring): TGUID;
const
  ERR_InvalidGUID = '[%s] is not a valid GUID value';
var
  i:  integer;
  src, dest: PAnsiChar;

  function _HexChar(const C: AnsiChar):  byte;
  begin
    case C of
      '0'..'9': result := byte(c) - byte('0');
      'a'..'f': result := (byte(c) - byte('a')) + 10;
      'A'..'F': result := (byte(c) - byte('A')) + 10;
    else        raise Exception.CreateFmt(ERR_InvalidGUID,[Value]);
    end;
  end;

  function _Hexbyte(const P:PAnsiChar):  AnsiChar;
  begin
    result := AnsiChar((_HexChar(p[0]) shl 4)+_HexChar(p[1]));
  end;

begin
  if Length(Value)=38 then
  begin
    dest := @result;
    src := PAnsiChar(Value);
    Inc(src);

    for i := 0 to 3 do
    dest[i] := _Hexbyte(src+(3-i)*2);

    Inc(src, 8);
    Inc(dest, 4);
    if src[0] <> '-' then
    raise Exception.CreateFmt(ERR_InvalidGUID,[Value]);

    Inc(src);
    for i := 0 to 1 do
    begin
      dest^ := _Hexbyte(src+2);
      Inc(dest);
      dest^ := _Hexbyte(src);
      Inc(dest);
      Inc(src, 4);
      if src[0] <> '-' then
      raise Exception.CreateFmt(ERR_InvalidGUID,[Value]);
      inc(src);
    end;

    dest^ := _Hexbyte(src);
    Inc(dest);
    Inc(src, 2);
    dest^ := _Hexbyte(src);
    Inc(dest);
    Inc(src, 2);
    if src[0] <> '-' then
    raise Exception.CreateFmt(ERR_InvalidGUID,[Value]);

    Inc(src);
    for i := 0 to 5 do
    begin
      dest^:=_Hexbyte(src);
      Inc(dest);
      Inc(src, 2);
    end;
  end else
  raise Exception.CreateFmt(ERR_InvalidGUID,[Value]);
end;

procedure HexRegisterRecordField(Aclass:THexRecordFieldclass);
var
  FLen: integer;
begin
  if (Aclass<>NIL)
  and (HexRecordFieldKnown(Aclass)=False) then
  begin
    FLen:=Length(_Fieldclasses);
    Setlength(_Fieldclasses,FLen+1);
    _Fieldclasses[FLen]:=Aclass;
  end;
end;

function HexRecordFieldKnown(Aclass:THexRecordFieldclass):  boolean;
var
  x:  integer;
begin
  result:=Aclass<>NIl;
  if result then
  begin
    result:=Length(_Fieldclasses)>0;
    if result then
    begin
      result:=False;
      for x:=low(_Fieldclasses) to high(_Fieldclasses) do
      begin
        result:=_Fieldclasses[x]=Aclass;
        if result then
        break;
      end;
    end;
  end;
end;

function HexRecordFieldclassFromName(AName: string;
          var Aclass: THexRecordFieldclass):  boolean;
var
  x:  integer;
begin
  Aclass:=NIL;
  result := Length(_Fieldclasses) > 0;
  if result then
  begin
    result := false;
    for x:=low(_Fieldclasses) to high(_Fieldclasses) do
    begin
      result:=_Fieldclasses[x].className=aName;
      if result then
      begin
        Aclass := _Fieldclasses[x];
        break;
      end;
    end;
  end;
end;

function HexRecordInstanceFromName(AName: string;
    out Value:THexRecordField):  boolean;
var
  Fclass: THexRecordFieldclass;
begin
  result := HexRecordFieldclassFromName(aName, Fclass);
  if result then
    Value := FClass.Create(nil);
end;

//##########################################################################
// THexEncoderRC4
//##########################################################################

function  THexEncoderRC4.GetResultSizeOf(const PreSize: int64): int64;
begin
  // RC4 is mutually exclusive, the encoded data is the same size
  // as the decoded data. So same size buffer is ok.
  result := PreSize;
end;

function THexEncoderRC4.EncodePtr(const Source; const Target; ByteLen: int64): int64;
var
  i,j,t: integer;
  Temp,y:   byte;
  FSpare:   THexRC4EncodingTable;
  LSource:  PByte;
  LTarget:  PByte;
  dx: int64;
begin
  result  := 0;
  LSource := @Source;
  LTarget := @Target;

  if  (GetReady()
  and (LSource <> nil)
  and (LTarget <> nil)
  and (Bytelen > 0) ) then
  begin
    // Fire begins event
    if assigned(OnEncodingBegins) then
    OnEncodingBegins(self, ByteLen);

    (* duplicate table *)
    FSpare := THexKeyRC4(Key).Table;
    try
      i := 0;
      j := 0;
      dx := 0;
      while (dx < ByteLen) do
      begin
        i := (i + 1) mod 256;
        j := (j + FSpare.etShr[i]) mod 256;
        temp := FSpare.etShr[i];
        FSpare.etShr[i] := FSpare.etShr[j];
        FSpare.etShr[j] := temp;
        t := (FSpare.etShr[i] + (FSpare.etShr[j] mod 256)) mod 256;
        y := FSpare.etShr[t];

        // Fire progress event
        if assigned(OnEncodingProgress) then
        OnEncodingProgress(Self, dx, ByteLen);

        LTarget^ := Byte( LSource^ xor y );
        inc(LTarget);
        inc(LSource);
        dx := dx + 1;
      end;

      result := Bytelen;

      // Fire completion event
      if assigned(OnEncodingEnds) then
      OnEncodingEnds(Self, ByteLen);

    except
      on exception do
      result := 0;
    end;
  end;
end;

function THexEncoderRC4.EncodeStream(Source, Target: TStream): int64;
var
  i,j,t:    integer;
  Temp,y:   byte;
  FDat:     byte;
  FSpare:   THexRC4EncodingTable;
  dx:       int64;
  ByteLen:  int64;
begin
  result := 0;

  if  (GetReady()
  and (Source <> nil)
  and (Target <> nil)
  and (Source.Size > 0) ) then
  begin
    // rewind stream?
    if Source.Position <> 0 then
    Source.Position := 0;

    // grab the size
    ByteLen := Source.Size;

    (* duplicate table *)
    FSpare := THexKeyRC4(Key).Table;

    try
      // Fire begins event
      if assigned(OnEncodingBegins) then
      OnEncodingBegins(self, ByteLen);

      i:=0;
      j:=0;
      dx := 0;
      while dx < Source.Size do
      Begin
        i := (i + 1) mod 256;
        j := (j + FSpare.etShr[i]) mod 256;
        temp := FSpare.etShr[i];
        FSpare.etShr[i] := FSpare.etShr[j];
        FSpare.etShr[j] := temp;
        t := (FSpare.etShr[i] + (FSpare.etShr[j] mod 256)) mod 256;
        y := FSpare.etShr[t];

        // Fire progress event
        if assigned(OnEncodingProgress) then
          OnEncodingProgress(Self, dx, ByteLen);

        if source.Read(FDat, SizeOf(FDat)) = SizeOf(FDat) then
        Begin
          FDat := FDat xor y;
          if Target.Write(FDat, SizeOf(FDat)) <> SizeOf(FDat) then
          exit;
        end else
        exit;
        dx := dx + 1;
      end;

      result := ByteLen;

      // Fire completion event
      if assigned(OnEncodingEnds) then
      OnEncodingEnds(Self, ByteLen);

    except
      on exception do
      result := 0;
    end;
  end;
end;

function THexEncoderRC4.DecodePtr(const Source; const Target; ByteLen: int64): int64;
var
  i,j,t: integer;
  Temp,y:   byte;
  FSpare:   THexRC4EncodingTable;
  LSource:  PByte;
  LTarget:  PByte;
  dx: int64;
begin
  result  := 0;
  LSource := @Source;
  LTarget := @Target;

  if  (GetReady()
  and (LSource <> nil)
  and (LTarget <> nil)
  and (Bytelen > 0) ) then
  begin
    // Fire begins event
    if assigned(OnDecodingBegins) then
      OnDecodingBegins(self, ByteLen);

    (* duplicate table *)
    FSpare := THexKeyRC4(Key).Table;
    try
      i := 0;
      j := 0;
      dx := 0;
      while (dx < ByteLen) do
      begin
        i := (i + 1) mod 256;
        j := (j + FSpare.etShr[i]) mod 256;
        temp := FSpare.etShr[i];
        FSpare.etShr[i] := FSpare.etShr[j];
        FSpare.etShr[j] := temp;
        t := (FSpare.etShr[i] + (FSpare.etShr[j] mod 256)) mod 256;
        y := FSpare.etShr[t];

        // Fire progress event
        if assigned(OnDecodingProgress) then
          OnDecodingProgress(Self, dx, ByteLen);

        LTarget^ := Byte( LSource^ xor y );
        inc(LTarget);
        inc(LSource);
        dx := dx + 1;
      end;

      result := ByteLen;

      // Fire completion event
      if assigned(OnDecodingEnds) then
      OnDecodingEnds(Self, ByteLen);

    except
      on exception do
      result := 0;
    end;
  end;
end;

function THexEncoderRC4.DecodeStream(Source, Target: TStream): int64;
var
  i,j,t:    integer;
  Temp,y:   byte;
  FDat:     byte;
  FSpare:   THexRC4EncodingTable;
  dx:       int64;
  ByteLen:  int64;
begin
  result := 0;

  if  (GetReady()
  and (Source <> nil)
  and (Target <> nil)
  and (Source.Size > 0) ) then
  begin
    // rewind stream?
    if Source.Position <> 0 then
    Source.Position := 0;

    // grab the size
    ByteLen := Source.Size;

    (* duplicate table *)
    FSpare := THexKeyRC4(Key).Table;

    try
      // Fire begins event
      if assigned(OnDecodingBegins) then
      OnDecodingBegins(self, ByteLen);

      i:=0;
      j:=0;
      dx := 0;
      while dx < Source.Size do
      Begin
        i := (i + 1) mod 256;
        j := (j + FSpare.etShr[i]) mod 256;
        temp := FSpare.etShr[i];
        FSpare.etShr[i] := FSpare.etShr[j];
        FSpare.etShr[j] := temp;
        t := (FSpare.etShr[i] + (FSpare.etShr[j] mod 256)) mod 256;
        y := FSpare.etShr[t];

        // Fire progress event
        if assigned(OnDecodingProgress) then
        OnDecodingProgress(Self, dx, ByteLen);

        if source.Read(FDat, SizeOf(FDat)) = SizeOf(FDat) then
        Begin
          FDat := FDat xor y;
          if Target.Write(FDat, SizeOf(FDat)) <> SizeOf(FDat) then
          exit;
        end else
        exit;
        dx := dx + 1;
      end;

      result := ByteLen;

      // Fire completion event
      if assigned(OnDecodingEnds) then
        OnDecodingEnds(Self, ByteLen);

    except
      on exception do
      result := 0;
    end;
  end;
end;

//##########################################################################
// THexKeyRC4
//##########################################################################

function THexKeyRC4.GetReady: boolean;
begin
  result := FReady;
end;

procedure THexKeyRC4.DoReset;
begin
  FReady := false;
  fillchar(FTable, SizeOf(FTable), #0);
end;

procedure THexKeyRC4.DoBuild(const Data: TStream);
var
  FLen:   Integer;
  FData:  Pointer;
Begin
  if (Data <> NIL) and (Data.Size >= 256) then
  begin
    Data.Position:=0;
    FData := AllocMem(256);
    try
      fillchar(FData^,256,#0);
      FLen := Data.Read(FData^,256);
      if FLen > 0 then
      DoBuild(FData^, FLen);
    finally
      FreeMem(FData);
    end;
  end else
  DoReset();
end;

procedure THexKeyRC4.DoBuild(const Data; const ByteSize: integer);
var
  i,j:    Integer;
  temp:   Byte;
  FData:  PRCByteArray;
begin
  (* reset key data *)
  DoReset();

  FData := @Data;

  if (FData <> NIL) and (ByteSize > 0) then
  begin
    J := 0;

    { Generate internal shift table based on key }
    for I:=0 to 255 do
    begin
      FTable.etShr[i] := i;
      If J = ByteSize then
        j := 1
      else
        inc(J);
      FTable.etMod[i] := FData[j-1];
    end;

    { Modulate shift table }
    J:=0;
    For i:=0 to 255 do
    begin
      j:=(j+FTable.etShr[i] + FTable.etMod[i]) mod 256;
      temp:=FTable.etShr[i];
      FTable.etShr[i]:=FTable.etShr[j];
      FTable.etShr[j]:=Temp;
    end;

    FReady := True;
  end else
  DoReset();
end;

//##########################################################################
// THexEncoder
//##########################################################################

procedure THexEncoder.Reset;
begin
  if assigned(FCipherKey) then
  begin
    FCipherKey.Reset();
  end else
  raise EHexEncoder.Create('Reset failed, no encryption-key has been assigned error');
end;

procedure THexEncoder.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  If (AComponent is THexEncodingKey) then
  begin
    Case Operation of
    opRemove: SetKey(NIL);
    opInsert: SetKey(THexEncodingKey(AComponent));
    end;
  end;
end;

procedure THexEncoder.SetKey(const NewKey: THexEncodingKey);
begin
  if (NewKey <> FCipherKey) then
  begin
    if (FCipherKey <> nil) then
    FCipherKey.RemoveFreeNotification(self);

    FCipherKey := newKey;

    if (FCipherKey <> nil) then
    FCipherKey.RemoveFreeNotification(self);
  end;
end;

function THexEncoder.GetReady: boolean;
begin
  result := assigned(FCipherKey) and FCipherKey.Ready;
end;

// Override this when making new encoders!
function THexEncoder.GetResultSizeOf(const PreSize: int64): int64;
begin
  result := PreSize;
end;

function THexEncoder.EncodeBuffer(const Source, Target: THexBuffer): int64;
var
  LSource: THexStreamAdapter;
  LTarget: THexStreamAdapter;
begin
  result := 0;

  if GetReady() then
  begin
    if (source <> nil) then
    begin
      if (target <> nil) then
      begin
        // Flush target if not empty
        if not Target.Empty then
          Target.Release();

        LSource := THexStreamAdapter.Create(source);
        try
          LTarget := THexStreamAdapter.Create(Target);
          try
            result := EncodeStream(LSource, LTarget);
          finally
            LTarget.Free;
          end;
        finally
          LSource.Free;
        end;

      end;
    end;
  end;
end;

function THexEncoder.DecodeBuffer(const Source, Target: THexBuffer): int64;
var
  LSource: THexStreamAdapter;
  LTarget: THexStreamAdapter;
begin
  result := 0;

  if GetReady() then
  begin
    if (source <> nil) then
    begin
      if (target <> nil) then
      begin
        if not Target.Empty then
        Target.Release();

        LSource := THexStreamAdapter.Create(source);
        try
          LTarget := THexStreamAdapter.Create(Target);
          try
            result := DecodeStream(LSource, LTarget);
          finally
            LTarget.Free;
          end;
        finally
          LSource.Free;
        end;

      end;
    end;
  end;
end;

//##########################################################################
// THexEncodingKey
//##########################################################################

destructor THexEncodingKey.Destroy;
begin
  if GetReady() then
    DoReset();
  inherited;
end;

procedure THexEncodingKey.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  If (AComponent is THexEncoder) then
  begin
    Case Operation of
    opRemove: SetEncoder(NIL);
    opInsert: SetEncoder(THexEncoder(AComponent));
    end;
  end;
end;

procedure THexEncodingKey.SetEncoder(const NewEncoder: THexEncoder);
begin
  if NewEncoder <> FEncoder then
  begin
    if FEncoder <> nil then
    FEncoder.RemoveFreeNotification(self);

    FEncoder := NewEncoder;

    if FEncoder<>nil then
    FEncoder.FreeNotification(self);
  end;
end;

procedure THexEncodingKey.Build(const Data; const ByteSize: integer);
begin
  if GetReady() then
    DoReset();

  if assigned(FOnBefore) then
    FOnBefore(self);
  try
    DoBuild(Data, ByteSize);
  finally
    if assigned(FOnAfter) then
    FOnAfter(Self);
  end;
end;

procedure THexEncodingKey.Reset;
begin
  if GetReady then
    DoReset();
end;

//##########################################################################
// THexBufferFile
//##########################################################################

constructor THexBufferFile.CreateEx(aFilename: string;StreamFlags:Word);
begin
  inherited Create(nil);

  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  self.Open(aFilename,StreamFlags);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Create',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.BeforeDestruction;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FFile<>NIL then
  begin
    FreeAndNIL(FFile);
    FFilename:='';
  end;

  inherited;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['BeforeDestruction',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBufferFile.DoGetCapabilities:THexBufferCapabilities;
begin
  result:=[mcScale,mcOwned,mcRead,mcWrite];
end;

function THexBufferFile.GetEmpty: boolean;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FFile<>NIL then
  result:=(FFile.Size=0) else
  result:=True;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['GetEmpty',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBufferFile.GetActive: boolean;
begin
  result:=assigned(FFile);
end;

procedure THexBufferFile.Open(aFilename: string;StreamFlags:Word);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if assigned(FFile) then
  Close;

  try
    FFile:=TFileStream.Create(aFilename,StreamFlags);
  except
    on e: exception do
    raise EHexBufferError.Create(e.message);
  end;

  FFileName:=aFilename;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Open',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.Close;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FFile<>NIL then
  begin
    FreeAndNIL(FFile);
    FFilename:='';
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Close',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBufferFile.DoGetDataSize:Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FFile<>NIL then
  result:=FFile.Size else
  result:=0;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoGetDataSize',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.DoReleaseData;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FFile<>NIL then
  FFile.Size:=0;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoGetDataSize',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.DoReadData(Start:Int64;var Buffer;BufLen:integer);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if assigned(FFile) then
  begin
    FFile.Position:=Start;
    FFile.ReadBuffer(Buffer,BufLen);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_NOTACTIVE);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoReadData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.DoWriteData(Start:Int64;const Buffer;
          BufLen:integer);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if assigned(FFile) then
  begin
    FFile.Position:=Start;
    FFile.WriteBuffer(Buffer,BufLen);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_NOTACTIVE);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoWriteData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.DoGrowDataBy(const Value:integer);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if assigned(FFile) then
  FFile.Size:=FFile.Size + Value else
  raise EHexBufferError.Create(CNT_ERR_BTRG_NOTACTIVE);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoGrowDataBy',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferFile.DoShrinkDataBy(const Value:integer);
var
  mNewSize: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if assigned(FFile) then
  begin
    mNewSize:=FFile.Size - Value;
    if mNewSize>0 then
    FFile.Size:=mNewSize else
    DoReleaseData;
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_NOTACTIVE);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoShrinkDataBy',e.classname,e.message]);
  end;
  {$ENDIF}
end;

//##########################################################################
// THexStreamAdapter
//##########################################################################

function THexBufferMemory.BasePTR:Pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* Any pointer to return? *)
  if FDataPTR<>NIL then
  result:=FDataPTR else
  raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['BasePTR',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBufferMemory.AddrOf(const byteIndex:Int64): Pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* Are we within range of the buffer? *)
  if (byteIndex>=0) and (byteIndex<FDataLen) then
  begin
    (* Note: if you have modified this class to working with
    memory-mapped files and go beyond MAXINT in the byteindex,
    Delphi can raise an EIntOverFlow exception *)
    result:=FDataPTR;
    inc(result,byteIndex);
  end else
  raise EHexBufferError.CreateFmt
  (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,FDataLEN,byteIndex]);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['AddrOf',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBufferMemory.DoGetCapabilities:THexBufferCapabilities;
begin
  result:=[mcScale,mcOwned,mcRead,mcWrite];
end;

function THexBufferMemory.DoGetDataSize:Int64;
begin
  if FDataPTR<>NIL then
  result:=FDataLen else
  result:=0;
end;

procedure THexBufferMemory.DoReleaseData;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  try
    if FDataPTR<>NIL then
    Freemem(FDataPTR);
  finally
    FDataPTR:=NIL;
    FDataLEN:=0;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoReleaseData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoReadData(Start:Int64;
          var Buffer;BufLen:integer);
var
  mSource:    Pbyte;
  mTarget:    Pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* Calculate PTR's *)
  mSource:=AddrOf(Start);
  mTarget:=Addr(Buffer);
  move(mSource^,mTarget^,BufLen);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoReadData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoWriteData(Start:Int64;
          const Buffer;BufLen:integer);
var
  mSource:    Pbyte;
  mTarget:    Pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* Calculate PTR's *)
  mSource:=Addr(Buffer);
  mTarget:=AddrOf(start);
  move(mSource^,mTarget^,BufLen);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoWriteData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoGrowDataBy(const Value:integer);
var
  mNewSize: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  try
    if FDataPTR<>NIL then
    begin
      (* Re-scale current memory *)
      mNewSize:=FDataLEN + Value;
      ReAllocMem(FDataPTR,mNewSize);
      FDataLen:=mNewSize;
    end else
    begin
      (* Allocate new memory *)
      FDataPTR:=AllocMem(Value);
      FDataLen:=Value;
    end;
  except
    on e: exception do
    begin
      FDataLen:=0;
      FDataPTR:=NIL;
      raise EHexBufferError.CreateFmt
      (CNT_ERR_BTRG_SCALEFAILED,[e.message]);
    end;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoGrowDataBy',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoShrinkDataBy(const Value:integer);
var
  mNewSize: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FDataPTR<>NIL then
  begin
    mNewSize:=EnsureRange(FDataLEN - Value,0,FDataLen);
    if mNewSize>0 then
    begin
      if mNewSize<>FDataLen then
      begin
        try
          ReAllocMem(FDataPTR,mNewSize);
          FDataLen:=mNewSize;
        except
          on e: exception do
          begin
            raise EHexBufferError.CreateFmt
            (CNT_ERR_BTRG_SCALEFAILED,[e.message]);
          end;
        end;
      end;
    end else
    DoReleaseData;
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoShrinkDataBy',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoZeroData;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if FDataPTR<>NIL then
  THexBuffer.Fillbyte(FDataPTR,FDataLen,0) else
  raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoZeroData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBufferMemory.DoFillData(Start:Int64;
          FillLength:Int64;const Data;DataLen:integer);
var
  FSource:    Pbyte;
  FTarget:    Pbyte;
  FLongs:     integer;
  FSingles:   integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize pointers *)
  FSource:=Addr(Data);
  FTarget:=self.AddrOf(Start);

  (* EVEN copy source into destination *)
  FLongs:=FillLength div DataLen;
  While FLongs>0 do
  begin
    Move(FSource^,FTarget^,DataLen);
    inc(FTarget,DataLen);
    dec(FLongs);
  end;

  (* ODD copy of source into destination *)
  FSingles:=FillLength mod DataLen;
  if FSingles>0 then
  begin
    Case FSingles of
    1: FTarget^:=FSource^;
    2: PWord(FTarget)^:=PWord(FSource)^;
    3: PBRTriplebyte(FTarget)^:=PBRTriplebyte(FSource)^;
    4: PLongword(FTarget)^:=PLongword(FSource)^;
    else
      Move(FSource^,FTarget^,FSingles);
    end;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoFillData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

//##########################################################################
// THexBuffer
//##########################################################################

procedure THexBuffer.Afterconstruction;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  inherited;

  (* Get memory capabillities *)
  FCaps := DoGetCapabilities;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Afterconstruction',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.BeforeDestruction;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* release memory if capabillities allow it *)
  Release;
  inherited;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['BeforeDestruction',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.SetEncryption(const NewEncoder: THexEncoder);
begin
  if NewEncoder <> FEncryption then
  begin
    { we already have one }
    If assigned(FEncryption) then
    FEncryption.RemoveFreeNotification(self);

    FEncryption := NewEncoder;

    { Set free notification }
    if Assigned(FEncryption) then
    FEncryption.FreeNotification(self);
  end;
end;

procedure THexBuffer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);

  If (AComponent is THexEncoder) then
  begin
    Case Operation of
    opRemove: SetEncryption(NIL);
    opInsert: SetEncryption(THexEncoder(AComponent));
    end;
  end;
end;

{$IFDEF HEX_SUPPORT_INTERNET}
procedure THexBuffer.HttpGet(RemoteURL: string);
var
  LHttp:  TIdHTTP;
  LZLib:  TIdCompressorZLib;
  LStream: TStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  // Release current content
  if not Empty then
    Release();

  // Setup a stream interface for the buffer. This maps directly to our
  // content so we dont have to do anything - it will fill itself :)
  LStream := THexStreamAdapter.Create(self);
  try
    LHttp := TIdHTTP.Create(nil);
    try
      LZLib := TIdCompressorZLib.Create(nil);
      try
        // Add support for compressed streams, this will show up in
        // the http request headers generated by Indy
        LHttp.Compressor := LZLib;

        try
          LHttp.Get(RemoteUrl, LStream);
        except
          on e: exception do
          raise EHexBufferError.CreateFmt
          ('Failed to download file [%s], system threw exception %s with message %s',
          [RemoteURL, e.ClassName, e.Message]);
        end;

      finally
        LZLib.Free;
      end;
    finally
      LHttp.Free;
    end;
  finally
    LStream.Free;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HttpGet',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.HttpPost(RemoteURL: string;
          const Populate: THexMultipartCallback);
var
  LHttp:  TIdHTTP;
  LZLib:  TIdCompressorZLib;
  LStream: TStream;
  LParts: TIdMultiPartFormDataStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  // Flush this buffer if it's not empty
  if not Empty then
    Release();

  // Make sure anonymous callback is valid
  if not assigned(Populate) then
  raise EHexBufferError.Create('HttpPost failed, no multipartform callback provided error');

  // Setup the multipart stream
  LParts := TIdMultiPartFormDataStream.Create;
  try
    // Setup a stream interface for this buffer. Data to post will be
    // in the multipart-stream, while the response ends up in this buffer
    LStream := THexStreamAdapter.Create(self);
    try
      LHttp := TIdHTTP.Create(nil);
      try
        LZLib := TIdCompressorZLib.Create(nil);
        try
          // Add support for compressed streams, this will show up in
          // the http request headers generated by Indy
          LHttp.Compressor := LZLib;

          // Execute the callback
          Populate(self, LParts);

          try
            LHttp.Post(RemoteUrl, LParts, LStream);
          except
            on e: exception do
            raise EHexBufferError.CreateFmt
            ('Failed to download file [%s], system threw exception %s with message %s',
            [RemoteURL, e.ClassName, e.Message]);
          end;

        finally
          LZLib.Free;
        end;
      finally
        LHttp.Free;
      end;
    finally
      LStream.Free;
    end;
  finally
    LParts.Free;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HttpPost',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.HttpPost(RemoteURL: string; const FormFields: TStrings);
var
  LHttp:  TIdHTTP;
  LZLib:  TIdCompressorZLib;
  LTarget: TStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if (FormFields = nil) then
  raise EHexError.Create('HttpPost failed, http form-fields cannot be nil error');

  // Setup a stream interface for the target buffer, indy will drop data there
  LTarget := THexStreamAdapter.Create(self);
  try
    LHttp := TIdHTTP.Create(nil);
    try
      LZLib := TIdCompressorZLib.Create(nil);
      try
        // Add support for compressed streams, this will show up in
        // the http request headers generated by Indy
        LHttp.Compressor := LZLib;

        try
          LHttp.Post(RemoteUrl, FormFields, LTarget);
        except
          on e: exception do
          raise EHexBufferError.CreateFmt
          ('Failed to download file [%s], system threw exception %s with message %s',
          [RemoteURL, e.ClassName, e.Message]);
        end;

      finally
        LZLib.Free;
      end;
    finally
      LHttp.Free;
    end;
  finally
    LTarget.Free;
  end;


  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HttpPost',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.HttpPost(RemoteURL: string; const Response: THexBuffer; const ContentType: string);
var
  LHttp:  TIdHTTP;
  LZLib:  TIdCompressorZLib;
  LStream: TStream;
  LTarget: TStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if Response = nil then
    raise EHexBufferError.Create('HttpPost failed, response buffer must be set');

  if (Response = self) then
    raise EHexBufferError.Create('HttpPost failed, response buffer cannot be same as send buffer');

  // Setup a stream interface for the buffer. Indy will send the content
  LStream := THexStreamAdapter.Create(self);
  try
    LTarget := THexStreamAdapter.Create(Response);
    try

      LHttp := TIdHTTP.Create(nil);
      try
        LZLib := TIdCompressorZLib.Create(nil);
        try
          // Add support for compressed streams, this will show up in
          // the http request headers generated by Indy
          LHttp.Compressor := LZLib;


          try
            LHttp.Post(RemoteUrl, LStream, LTarget);
          except
            on e: exception do
            raise EHexBufferError.CreateFmt
            ('Failed to post data [%s], system threw exception %s with message %s',
            [RemoteURL, e.ClassName, e.Message]);
          end;

        finally
          LZLib.Free;
        end;
      finally
        LHttp.Free;
      end;

    finally
      LTarget.Free;
    end;
  finally
    LStream.Free;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HttpPost',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.HttpPost(RemoteURL: string; const ContentType: string);
var
  LHttp:  TIdHTTP;
  LZLib:  TIdCompressorZLib;
  LStream: TStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  // Setup a stream interface for the buffer. Indy will send the content
  LStream := THexStreamAdapter.Create(self);
  try
    LHttp := TIdHTTP.Create(nil);
    try
      LZLib := TIdCompressorZLib.Create(nil);
      try
        // Add support for compressed streams, this will show up in
        // the http request headers generated by Indy
        LHttp.Compressor := LZLib;

        try
          LHttp.Post(RemoteUrl, LStream);
        except
          on e: exception do
          raise EHexBufferError.CreateFmt
          ('Failed to post data [%s], system threw exception %s with message %s',
          [RemoteURL, e.ClassName, e.Message]);
        end;

      finally
        LZLib.Free;
      end;
    finally
      LHttp.Free;
    end;
  finally
    LStream.Free;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HttpPost',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}


//Note: This version is reentrant, The Adler parameter is
//      typically set to zero on the first call, and then
//      the result for the next calls until the buffer has been hashed
class function THexBuffer.AdlerHash(const Adler: Cardinal;
  const Data; DataLength: integer):  longword;
var
  s1, s2: cardinal;
  i, n: integer;
  p: Pbyte;
begin
  if DataLength>0 then
  begin
    s1 := LongRec(Adler).Lo;
    s2 := LongRec(Adler).Hi;
    p := @Data;
    while DataLength>0 do
    begin
      if DataLength<5552 then
      n := DataLength else
      n := 5552;

      for i := 1 to n do
      begin
        inc(s1,p^);
        inc(p);
        inc(s2,s1);
      end;

      s1 := s1 mod 65521;
      s2 := s2 mod 65521;
      dec(DataLength,n);
    end;
    result := word(s1) + cardinal(word(s2)) shl 16;
  end else
  result := Adler;
end;

class function THexBuffer.AdlerHash(const Data; DataLength: integer):  longword;
var
  LAdler: Cardinal;
begin
  LAdler := $0;
  result :=AdlerHash(LAdler, Data, DataLength);
end;

class function THexBuffer.AdlerHash(const Text: string):  longword;
var
  FLen:   integer;
  {$IFNDEF DELPHI_CLASSIC}
  LBytes: TBytes;
  {$ELSE}
  FAddr:  PByte;
  {$ENDIF}
begin
  result:=0;
  FLen := Length(Text);
  if FLen>0 then
  begin
    {$IFDEF DELPHI_CLASSIC}
    FAddr := @Text[1];
    result:=KAndRHash(FAddr^,FLen * Sizeof(Char));
    {$ELSE}
    LBytes := TEncoding.UTF8.GetBytes(Text);
    result := KAndRHash(LBytes[0], Length(LBytes) );
    {$ENDIF}
  end;
end;

class function THexBuffer.BobJenkinsHash(const Data; DataLength: integer):  longword;
var
  x: integer;
  LHash: longword;
  P: PByte;
begin
  LHash := 0;
  if (DataLength > 0) then
  begin
    P := @Data;
    for x:=1 to Datalength do
    begin
      LHash := LHash + p^;
      LHash := LHash shl 10;
      LHash := LHash shr 6;
      inc(p);
    end;

    LHash := LHash + (LHash shl 3);
    LHash := LHash + (LHash shr 11);
    LHash := LHash + (LHash shl 15);
  end;
  result := LHash;
end;

class function THexBuffer.BobJenkinsHash(const Text: string):  longword;
var
  FLen:   integer;
  {$IFNDEF DELPHI_CLASSIC}
  LBytes: TBytes;
  {$ELSE}
  FAddr:  PByte;
  {$ENDIF}
begin
  result:=0;
  FLen := Length(Text);
  if FLen>0 then
  begin
    {$IFDEF DELPHI_CLASSIC}
    FAddr := @Text[1];
    result:=BorlandHash(FAddr^,FLen * Sizeof(Char));
    {$ELSE}
    LBytes := TEncoding.UTF8.GetBytes(Text);
    result := BorlandHash(LBytes[0], Length(LBytes) );
    {$ENDIF}
  end;
end;

class function THexBuffer.BorlandHash(const Data; DataLength: integer):  longword;
var
  I: integer;
  p: Pbyte;
begin
  result := 0;
  if DataLength>0 then
  begin
    p := @Data;
    for I := 1 to DataLength do
    begin
      result := ((result shl 2) or (result shr ( SizeOf(result) * 8 - 2))) xor p^;
      inc(p);
    end;
  end;
end;

class function THexBuffer.BorlandHash(const Text: string):  longword;
var
  FLen:   integer;
  {$IFNDEF DELPHI_CLASSIC}
  LBytes: TBytes;
  {$ELSE}
  FAddr:  PByte;
  {$ENDIF}
begin
  result:=0;
  FLen := Length(Text);
  if FLen>0 then
  begin
    {$IFDEF DELPHI_CLASSIC}
    FAddr := @Text[1];
    result:=BorlandHash(FAddr^,FLen * Sizeof(Char));
    {$ELSE}
    LBytes := TEncoding.UTF8.GetBytes(Text);
    result := BorlandHash(LBytes[0], Length(LBytes) );
    {$ENDIF}
  end;
end;

class function THexBuffer.KAndRHash(const Data; DataLength: integer):  longword;
var
  x:  integer;
  LAddr: PByte;
  LCrc: longword;
begin
  LCrc := $0;
  if DataLength>0 then
  begin
    LAddr := @Data;
    for x:=1 to datalength do
    begin
      LCrc := ( (LAddr^ + LCrc) * 31);
    end;
  end;
  result := LCrc;
end;

class function THexBuffer.KAndRHash(const Text: string):  longword;
var
  FLen:   integer;
  {$IFNDEF DELPHI_CLASSIC}
  LBytes: TBytes;
  {$ELSE}
  FAddr:  PByte;
  {$ENDIF}
begin
  result:=0;
  FLen := Length(Text);
  if FLen>0 then
  begin
    {$IFDEF DELPHI_CLASSIC}
    FAddr := @Text[1];
    result:=KAndRHash(FAddr^,FLen * Sizeof(Char));
    {$ELSE}
    LBytes := TEncoding.UTF8.GetBytes(Text);
    result := KAndRHash(LBytes[0], Length(LBytes) );
    {$ENDIF}
  end;
end;

class function THexBuffer.ElfHash(const Data; DataLength:integer): longword;
var
  i:    integer;
  x:    Cardinal;
  LSrc: Pbyte;
begin
  result:=0;
  if DataLength>0 then
  begin
    LSrc := @Data;
    for i:=1 to DataLength do
    begin
      result := (result shl 4) + LSrc^;
      x := result and $F0000000;
      if (x <> 0) then
      result := result xor (x shr 24);
      result := result and (not x);
      inc(LSrc);
    end;
  end;
end;

class function THexBuffer.ElfHash(const Text: string): longword;
var
  FLen:   integer;
  {$IFNDEF DELPHI_CLASSIC}
  LBytes: TBytes;
  {$ELSE}
  FAddr:  PByte;
  {$ENDIF}
begin
  result:=0;
  FLen := Length(Text);
  if FLen>0 then
  begin
    {$IFDEF DELPHI_CLASSIC}
    FAddr := @Text[1];
    result:= ElfHash(FAddr^,FLen * Sizeof(Char));
    {$ELSE}
    LBytes := TEncoding.UTF8.GetBytes(Text);
    result := ElfHash(LBytes[0], Length(LBytes) );
    {$ENDIF}
  end;
end;

class procedure THexBuffer.Fillbyte(Target: Pbyte;
  const FillSize: integer; const Value: byte);
var
  LBytesToFill: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  LBytesToFill:=FillSize;
  While (LBytesToFill > 0) do
  begin
    Target^:=Value;
    dec(LBytesToFill);
    inc(Target);
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Fillbyte',e.classname,e.message]);
  end;
  {$ENDIF}
end;

class procedure THexBuffer.FillWord(Target: PWord;
          const FillSize: integer; const Value: word);
var
  FTemp:  Longword;
  FLongs: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  FTemp := Value shl 16 or Value;
  FLongs := FillSize shr 3;
  while FLongs>0 do
  begin
    PLongword(Target)^:=FTemp; inc(PLongword(Target));
    PLongword(Target)^:=FTemp; inc(PLongword(Target));
    PLongword(Target)^:=FTemp; inc(PLongword(Target));
    PLongword(Target)^:=FTemp; inc(PLongword(Target));
    dec(FLongs);
  end;

  Case FillSize mod 8 of
  1:  Target^:=Value;
  2:  PLongword(Target)^:=FTemp;
  3:  begin
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        Target^:=Value;
      end;
  4:  begin
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp;
      end;
  5:  begin
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        Target^:=Value;
      end;
  6:  begin
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp;
      end;
  7:  begin
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        PLongword(Target)^:=FTemp; inc(PLongword(Target));
        Target^:=Value;
      end;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['FillWord',e.classname,e.message]);
  end;
  {$ENDIF}
end;


class procedure THexBuffer.FillTriple(dstAddr: PBRTriplebyte;
          const inCount: integer;const Value:THexTriplebyte);
var
  FLongs: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  FLongs:=inCount shr 3;
  While FLongs>0 do
  begin
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dstAddr^:=Value;inc(dstAddr);
    dec(FLongs);
  end;

  Case (inCount mod 8) of
  1:  dstAddr^:=Value;
  2:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  3:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  4:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  5:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  6:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  7:  begin
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;inc(dstAddr);
        dstAddr^:=Value;
      end;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['FillTriple',e.classname,e.message]);
  end;
  {$ENDIF}
end;

class procedure THexBuffer.FillLong(dstAddr:PLongword;
      const inCount: integer;const Value:Longword);
var
  FLongs: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  FLongs:=inCount shr 3;
  While FLongs>0 do
  begin
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dstAddr^:=Value; inc(dstAddr);
    dec(FLongs);
  end;

  Case inCount mod 8 of
  1:  dstAddr^:=Value;
  2:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  3:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  4:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  5:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  6:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  7:  begin
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value; inc(dstAddr);
        dstAddr^:=Value;
      end;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['FillLong',e.classname,e.message]);
  end;
  {$ENDIF}
end;


procedure THexBuffer.Assign(Source:TPersistent);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if Source<>NIl then
  begin
    if (Source is THexBuffer) then
    begin
      Release;
      Append(THexBuffer(source));
    end else
    Inherited;
  end else
  Inherited;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Assign',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBuffer.ObjectHasData: boolean;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result:=DoGetDataSize>0;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ObjectHasData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexBuffer.GetEmpty: boolean;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result:=DoGetDataSize<=0;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['GetEmpty',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.BeforeReadObject;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if (mcOwned in FCaps) then
  Release else
  raise EHexBufferError.Create(CNT_ERR_BTRG_RELEASENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['BeforeReadObject',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.AfterReadObject;
begin
end;

procedure THexBuffer.BeforeWriteObject;
begin
end;

procedure THexBuffer.AfterWriteObject;
begin
end;

procedure THexBuffer.ReadObject(Reader:TReader);
var
  mTotal: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  Reader.Read(mTotal,SizeOf(mTotal));
  if mTotal>0 then
  ImportFrom(0,mTotal,Reader);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ReadObject',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.WriteObject(Writer:TWriter);
var
  mSize:  Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mSize:=Size;
  Writer.write(mSize,SizeOf(mSize));
  if mSize>0 then
  self.ExportTo(0,mSize,Writer);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['WriteObject',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.ReadObjBin(Stream: TStream);
var
  mReader:  TReader;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mReader:=TReader.Create(Stream,1024);
  try
    BeforeReadObject;
    ReadObject(mReader);
  finally
    mReader.free;
    AfterReadObject;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ReadObjBin',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.WriteObjBin(Stream: TStream);
var
  mWriter:  TWriter;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mWriter:=TWriter.Create(Stream,1024);
  try
    BeforeWriteObject;
    WriteObject(mWriter);
  finally
    mWriter.FlushBuffer;
    mWriter.free;
    AfterWriteObject;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['WriteObjBin',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.DefineProperties(Filer:TFiler);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  inherited;
  Filer.DefineBinaryproperty('IO_BIN',ReadObjBin,WriteObjBin,ObjectHasData);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DefineProperties',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.DoFillData(Start:Int64;FillLength:Int64;
          const Data;DataLen:integer);
var
  mToWrite: integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  While FillLength>0 do
  begin
    mToWrite:=EnsureRange(Datalen,1,FillLength);
    DoWriteData(Start,Data,mToWrite);
    FillLength:=FillLength - mToWrite;
    Start:=Start + mToWrite;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoFillData',e.classname,e.message]);
  end;
  {$ENDIF}
end;


function  THexBuffer.Fill(const ByteIndex:Int64;
          const FillLength:Int64;
          const DataSource;const DataSourceLength:integer): Int64;
var
  LTotal: Int64;
  LTemp:  Int64;
  LAddr:  pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Are we empty? *)
  if not Empty then
  begin
    (* Check write capabilities *)
    if mcWrite in FCaps then
    begin
      (* Check length[s] of data *)
      if  (FillLength>0)
      and (DataSourceLength>0) then
      begin
        (* check data-source *)
        LAddr:=addr(DataSource);
        if LAddr<>NIl then
        begin

          (* Get total range *)
          LTotal:=DoGetDataSize;

          (* Check range entrypoint *)
          if (ByteIndex>=0) and (ByteIndex<LTotal) then
          begin

            (* Does fill exceed range? *)
            LTemp:=ByteIndex + FillLength;
            if LTemp>LTotal then
            LTemp:=(LTotal - ByteIndex) else // Yes, clip it
            LTemp:=FillLength;               // No, length is fine

            (* fill range *)
            DoFillData(ByteIndex,LTemp,LAddr^,DataSourceLength);

            (* return size of region filled *)
            result:=LTemp;

          end else
          raise EHexBufferError.CreateFmt
          (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,LTotal-1,ByteIndex]);

        end else
        raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
      end;
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Fill',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.DoZeroData;
var
  mSize:  Int64;
  mAlign: Int64;
  mCache: THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Get size in bytes of buffer *)
  mSize:=DoGetDataSize;

  (* Take widechar into account *)
  mAlign:=mSize div SizeOf(char);

  (* fill our temp buffer *)
  THexBuffer.Fillbyte(@mCache,mAlign,0);

  (* Perform internal fill *)
  Fill(0,mSize,mCache,SizeOf(mCache));
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DoZeroData',e.classname,e.message]);
  end;
  {$ENDIF}
end;

{$WARNINGS OFF}
function  THexBuffer.ToString(BytesPerRow: integer = 16;
          const Options: THexDumpOptions = [hdSign, hdZeroPad]): string;
var
  x, y:   integer;
  LCount: integer;
  LPad:   integer;
  LDump:  array of byte;
  LCache: byte;

  procedure AddToCache(const Value: byte);
  var
    _len: integer;
  begin
    _Len := length(LDump);
    SetLength(LDump, _Len+1);
    LDump[_len] := Value;
  end;

begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  if not Empty then
  Begin
    BytesPerRow := EnsureRange(BytesPerRow, 2, 64);
    LCount:=0;
    result := '';

    for x:=0 to Size-1 do
    begin

      if Read(x, SizeOf(LCache), LCache) = SizeOf(LCache) then
      AddToCache(LCache) else
      break;

      if (hdSign in Options) then
      result := result + '$' + IntToHex(LCache,2) else
      result := result + IntToHex(LCache,2);
      inc(LCount);
      if LCount >= BytesPerRow then
      begin
        if Length(LDump) > 0 then
        begin
          result := result + ' ';
          for y:=0 to length(LDump)-1 do
          begin
            if chr(LDump[y]) in
              ['A'..'Z',
               'a'..'z',
               '0'..'9',
               ',',';','<','>','{','}','[',']','-','_','#','$','%','&','/',
              '(',')','!','�','^',':',',','?'] then
            result := result + chr(LDump[y]) else
            result := result + '_';
          end;
        end;
        setlength(LDump,0);

        result := result + #13 + #10;
        LCount := 0;
      end else
      result := result + ' ';
    end;

    if (hdZeroPad in Options) and (LCount >0 ) then
    begin
      LPad := BytesPerRow - lCount;
      for x:=1 to LPad do
      Begin
        result := result + '--';
        if (hdSign in Options) then
        result := result + '-';

        inc(LCount);
        if LCount>=BytesPerRow then
        begin
          result := result + #13 + #10;
          LCount := 0;
        end else
        result := result + ' ';
      end;
    end;
  end;

  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ToString',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$WARNINGS ON}

procedure THexBuffer.Zero;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if not Empty then
  begin
    if mcWrite in FCaps then
    DoZeroData else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Zero',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.Append(const Buffer:THexBuffer);
var
  mOffset:      Int64;
  mTotal:       Int64;
  mRead:        integer;
  mbytesToRead: integer;
  mCache:       THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if mcScale in FCaps then
  begin
    if mcWrite in FCaps then
    begin
      if Buffer<>NIL then
      begin
        (* does the source support read caps? *)
        if (mcRead in Buffer.Capabilities) then
        begin

          mOffset:=0;
          mTotal:=Buffer.Size;

          Repeat
            mbytesToRead:=EnsureRange(SizeOf(mCache),0,mTotal);
            mRead:=Buffer.Read(mOffset,mbytesToRead,mCache);
            if mRead>0 then
            begin
              Append(mCache,mRead);
              mTotal:=mTotal - mRead;
              mOffset:=mOffset + mRead;
            end;
          Until (mbytesToRead<1) or (mRead<1);

        end else
        raise EHexBufferError.Create(CNT_ERR_BTRG_SOURCEREADNOTSUPPORTED);

      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Append',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.Append(const Stream: TStream);
var
  mTotal:       Int64;
  mRead:        integer;
  mbytesToRead: integer;
  mCache:       THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if mcScale in FCaps then
  begin
    if mcWrite in FCaps then
    begin
      if Stream<>NIL then
      begin
        mTotal:=(Stream.Size-Stream.Position);
        if mTotal>0 then
        begin

          Repeat
            mbytesToRead:=EnsureRange(SizeOf(mCache),0,mTotal);
            mRead:=Stream.Read(mCache,mbytesToRead);
            if mRead>0 then
            begin
              Append(mCache,mRead);
              mTotal:=mTotal - mRead;
            end;
          Until (mbytesToRead<1) or (mRead<1);

        end;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Append',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.Append(const Data;const DataLength:integer);
var
  mOffset: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if mcScale in FCaps then
  begin
    if mcWrite in FCaps then
    begin
      if DataLength>0 then
      begin
        mOffset:=DoGetDataSize;
        DoGrowDataBy(DataLength);
        DoWriteData(mOffset,Data,DataLength);
      end;
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Append',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Release()
    Purpose:  This method releases any content contained by the
              buffer. It is equal to Freemem in function *)
procedure THexBuffer.Release;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Is the content owned/managed by us? *)
  if mcOwned in FCaps then
  DoReleaseData else
  raise EHexBufferError.Create(CNT_ERR_BTRG_RELEASENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Release',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Search()
    Purpose:  This method is used to define a new size of the current
              buffer. It will scale the buffer to fit the new size,
              including grow or shrink the data *)
procedure THexBuffer.SetSize(const NewSize: Int64);
var
  mFactor:  Int64;
  mOldSize: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if (mcScale in FCaps) then
  begin
    if NewSize>0 then
    begin
      (* Get current size *)
      mOldSize:=DoGetDataSize;

      (* Get difference between current size & new size *)
      mFactor:=abs(mOldSize-NewSize);

      (* only act if we need to *)
      if mFactor>0 then
      begin
        try
          (* grow or shrink? *)
          if NewSize>mOldSize then
          DoGrowDataBy(mFactor) else

          if NewSize<mOldSize then
          DoShrinkDataBy(mFactor);
        except
          on e: exception do
          raise EHexBufferError.CreateFmt
          (CNT_ERR_BTRG_SCALEFAILED,[e.message]);
        end;
      end;
    end else
    Release;
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['SetSize',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Search()
    Purpose:  The search method allows you to perform a simple binary
              search inside the buffer.
    Comments: The search does not yet deploy caching of data, so on
              larger buffers it may be slow *)
function  THexBuffer.Search(const Data; const DataLength: integer;
    var FoundbyteIndex: int64):  boolean;
var
  mTotal:   Int64;
  mToScan:  Int64;
  src:      Pbyte;
  mbyte:    byte;
  mOffset:  Int64;
  x:        Int64;
  y:        Int64;
  mRoot:    Pbyte;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=False;
  FoundbyteIndex:=-1;

  (* Get search pointer *)
  mRoot:=addr(Data);

  (* Valid pointer? *)
  if (mRoot<>NIl) and (DataLength>0) then
  begin

    (* Check read capabilities of buffer *)
    if (mcRead in FCaps) then
    begin
      (* get total size to scan *)
      mTotal:=doGetDataSize;

      (* do we have anything to work with? *)
      if (mTotal>0) and (mTotal>=DataLength) then
      begin

        (* how many bytes must we scan? *)
        mToScan:=mTotal - DataLength;

        x:=0;
        While (x<=mToScan) do
        begin
          (* setup source PTR *)
          src:=Addr(Data);

          (* setup target offset *)
          mOffset:=x;

          (* check memory by sampling *)
          y:=1;
          while y<DataLength do
          begin
            (* break if not equal *)
            Read(mOffset,1,mbyte);
            result:=src^=mbyte;
            if not result then
            break;

            inc(src);
            mOffset:=mOffset + 1;
            Y:=Y + 1;
          end;

          (* success? *)
          if result then
          begin
            FoundbyteIndex:=x;
            Break;
          end;

          x:=x + 1;
        end;
      end;
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Search',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Insert()
    Purpose:  This function allows you to insert the content of another
              buffer anywhere in the current buffer. This operation does
              not overwrite any data currently in the buffer, but rather
              the new data is injected into the buffer - expanding the size
              and pushing the succeeding data forward *)
procedure THexBuffer.Insert(ByteIndex:Int64;const Source: THexBuffer);
var
  mTotal:   Int64;
  mCache:   THexIOCache;
  mRead:    integer;
  mToRead:  integer;
  mEntry:   Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Validate source PTR *)
  if Source<>NIl then
  begin
    (* Check that buffer supports scaling *)
    if (mcScale in FCaps) then
    begin
      (* Check that buffer support write access *)
      if (mcWrite in FCaps) then
      begin
        (* Check for read-access *)
        if (mcRead in Source.Capabilities) then
        begin
          (* Get size of source *)
          mTotal:=Source.Size;

          (* Validate entry index *)
          if (ByteIndex>=0) then
          begin

            (* anything to work with? *)
            if mTotal>0 then
            begin

              mEntry:=0;
              While mTotal>0 do
              begin
                (* Clip data to read *)
                mToRead:=SizeOf(mCache);
                if mToRead>mTotal then
                mToRead:=mTotal;

                (* Read data from buffer *)
                mRead:=Source.Read(mEntry,mToRead,mCache);
                if mRead>0 then
                begin
                  (* Insert data into our buffer *)
                  Insert(ByteIndex,mCache,mRead);

                  (* update positions *)
                  mEntry:=mEntry + mRead;
                  ByteIndex:=ByteIndex + mRead;
                  mTotal:=mTotal - mRead;
                end else
                Break;
              end;
            end;

          end else
          raise EHexBufferError.CreateFmt
          (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,mTotal-1,ByteIndex]);

        end else
        raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Insert',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Insert()
    Purpose:  This function allows you to insert X number of bytes
              anywhere in the buffer. This operation does not overwrite
              any data currently in the buffer, but rather the new
              data is injected into the buffer - expanding the size
              and pushing the succeeding data forward *)
procedure THexBuffer.Insert(const ByteIndex: int64;const Source; DataLength: integer);
var
  mTotal:       Int64;
  mbytesToPush: Int64;
  mbytesToRead: integer;
  mPosition:    Int64;
  mFrom:        Int64;
  mTo:          Int64;
  mData:        Pbyte;
  mCache:       THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Check that buffer supports scaling *)
  if (mcScale in FCaps) then
  begin
    (* Check that buffer support write access *)
    if (mcWrite in FCaps) then
    begin
      (* Make sure buffer supports read operations *)
      if (mcRead in FCaps) then
      begin
        (* Check length *)
        if DataLength>0 then
        begin
          (* Check data-source *)
          mData:=@Source;
          if mData<>NIL then
          begin

            (* get current size *)
            mTotal:=DoGetDataSize;

            (* Insert into data? *)
            if (ByteIndex>=0) and (ByteIndex<mTotal) then
            begin
              (* How many bytes should we push? *)
              mbytesToPush:=mTotal - ByteIndex;
              if mbytesToPush>0 then
              begin
                (* grow media to fit new data *)
                DoGrowDataBy(DataLength);

                (* calculate start position *)
                mPosition:=ByteIndex + mbytesToPush;

                While mbytesToPush>0 do
                begin
                  (* calculate how much data to read *)
                  mbytesToRead:=EnsureRange(SizeOf(mCache),0,mbytesToPush);

                  (* calculate read & write positions *)
                  mFrom:=mPosition - mbytesToRead;
                  mTo:=mPosition - (mbytesToRead - DataLength);

                  (* read data from the end *)
                  DoReadData(mFrom,mCache,mbytesToRead);

                  (* write data upwards *)
                  DoWriteData(mTo,mCache,mbytesToRead);

                  (* update offset values *)
                  mPosition:=mPosition - mbytesToRead;
                  mbytesToPush:=mbytesToPush - mbytesToRead;
                end;

                (* insert new data *)
                DoWriteData(mPosition,Source,DataLength);

              end else
              DoWriteData(mTotal,Source,DataLength);
            end else

            (* if @ end, use append instead *)
            if (ByteIndex = mTotal) then
            Append(Source,DataLength) else

            (* outside of memory scope, raise exception *)
            raise EHexBufferError.CreateFmt
            (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,mTotal-1,ByteIndex]);

          end else
          raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);

        end; {:length}
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Insert',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Remove()
    Purpose:  This function allows you to remove X bytes of data from
              anywhere within the buffer. This is extremely handy
              when working with binary files, cabinet-files and other
              advanced file operations *)
procedure THexBuffer.Remove(const ByteIndex: int64; DataLength: integer);
var
  mTemp:      integer;
  mTop:       Int64;
  mBottom:    Int64;
  mToRead:    integer;
  mToPoll:    Int64;
  mPosition:  Int64;
  mTotal:     Int64;
  mCache:     THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Check that buffer supports scaling *)
  if (mcScale in FCaps) then
  begin
    (* Check that buffer support write access *)
    if (mcWrite in FCaps) then
    begin
      (* Make sure buffer supports read operations *)
      if mcRead in FCaps then
      begin
        (* Validate remove length *)
        if DataLength>0 then
        begin
          (* get current size *)
          mTotal:=DoGetDataSize;

          (* Remove from data, or the whole thing? *)
          if (ByteIndex>=0) and (ByteIndex<mTotal) then
          begin
            mTemp:=ByteIndex + DataLength;
            if DataLength<>mTotal then
            begin
              if mTemp<mTotal then
              begin
                mToPoll:=mTotal - (ByteIndex + DataLength);
                mTop:=ByteIndex;
                mBottom:=ByteIndex + DataLength;

                While mToPoll>0 do
                begin
                  mPosition:=mBottom;
                  mToRead:=EnsureRange(SizeOf(mCache),0,mToPoll);

                  DoReadData(mPosition,mCache,mToRead);
                  DoWriteData(mTop,mCache,mToRead);

                  mTop:=mTop + mToRead;
                  mBottom:=mBottom + mToRead;
                  mToPoll:=mToPoll - mToRead;
                end;
                DoShrinkDataBy(DataLength);
              end else
              Release;
            end else
            begin
              (* Release while buffer? Or just clip at the end? *)
              if mTemp>mTotal then
              Release else
              DoShrinkDataBy(mTotal - DataLength);
            end;

          end else
          raise EHexBufferError.CreateFmt
          (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,mTotal-1,ByteIndex]);
        end;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Remove',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Push()
    Purpose:  Allows you to insert X number of bytes at the beginning
              of the buffer. This is very handy and allows a buffer to
              be used in a "stack" fashion. *)
function THexBuffer.Push(const Source; DataLength: integer):  integer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if not Empty then
  Insert(0,Source,DataLength) else
  Append(Source,DataLength);
  result:=DataLength;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Push',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Pull()
    Purpose:  Allows you to extract X number of bytes from the buffer,
              the buffer will then re-scale itself and remove the bytes
              you polled automatically. Very handy "stack" function *)
function THexBuffer.Pull(var Target; DataLength: integer):  integer;
var
  mTotal:   Int64;
  mRemains: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Make sure buffer supports scaling *)
  if mcScale in FCaps then
  begin
    (* check write rights *)
    if mcWrite in FCaps then
    begin
      (* check read rights *)
      if mcRead in FCaps then
      begin
        (* validate length of data to poll *)
        if DataLength>0 then
        begin
          (* get current size *)
          mTotal:=DoGetDataSize;
          if mTotal>0 then
          begin
            (* calc how much data will remain *)
            mRemains:=mTotal - DataLength;

            (* anything left afterwards? *)
            if mRemains>0 then
            begin
              (* return data, keep the stub *)
              result:=Read(0,DataLength,Target);
              Remove(0,DataLength);
            end else
            begin
              (* return data, deplete buffer *)
              result:=mTotal;
              DoReadData(0,Target,mTotal);
              Release;
            end;
          end;
        end;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Pull',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   HashCode()
    Purpose:  Generate an Elf-hashcode [long] from buffer. *)
function THexBuffer.HashCode: longword;
var
  i:        integer;
  x:        Longword;
  mTotal:   Int64;
  mRead:    integer;
  mToRead:  integer;
  mIndex:   Int64;
  mCache:   THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Check that buffer supports reading *)
  if (mcRead in FCaps) then
  begin
    (* Get current datasize *)
    mTotal:=DoGetDataSize;

    (* anything to work with? *)
    if mTotal>0 then
    begin
      (* start at the beginning *)
      mIndex:=0;

      (* keep going while we have data *)
      while mTotal>0 do
      begin
        (* clip prefetch to cache range *)
        mToRead:=SizeOf(mCache);
        if mToRead>mTotal then
        mToRead:=mTotal;

        (* read a chunk of data *)
        mRead:=read(mIndex,mToRead,mCache);

        (* anything to work with? *)
        if mRead>0 then
        begin
          (* go through the cache *)
          for i:=0 to mRead do
          begin
            result := (result shl 4) + mCache[i];
            x := result and $F0000000;
            if (x <> 0) then
            result := result xor (x shr 24);
            result := result and (not x);
          end;

          (* update variables *)
          mTotal:=mTotal - mRead;
          mIndex:=mIndex + mRead;
        end else
        Break;
      end;

    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['HashCode',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   LoadFromFile()
    Purpose:  Loads the content of a file into our buffer *)
procedure THexBuffer.LoadFromFile(Filename: string);
var
  mFile:  TFileStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mFile:=TFileStream.Create(filename,fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(mFile);
  finally
    mFile.free;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['LoadFromFile',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   SaveToFile()
    Purpose:  Saves the current content of the buffer to a file. *)
procedure THexBuffer.SaveToFile(Filename: string);
var
  mFile:  TFileStream;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mFile:=TFileStream.Create(filename,fmCreate or fmShareDenyNone);
  try
    SaveToStream(mFile);
  finally
    mFile.free;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['SaveToFile',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   SaveToStream()
    Purpose:  Saves the current content of the buffer to a stream. *)
procedure THexBuffer.SaveToStream(Stream: TStream);
var
  mWriter:  TWriter;
  mTotal:   Int64;
  mToRead:  integer;
  mRead:    integer;
  mOffset:  Int64;
  mCache:   THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Check that buffer supports reading *)
  if (mcRead in FCaps) then
  begin
    (* make sure targetstream is valid *)
    if (Stream<>NIL) then
    begin
      (* create a TWriter to benefit from cache *)
      mWriter:=TWriter.Create(Stream,1024);
      try
        (* get current buffersize *)
        mTotal:=DoGetDataSize;
        mOffset:=0;

        (* Keep going while there is data *)
        While mTotal>0 do
        begin
          (* Clip prefetch size so not to exceed range *)
          mToRead:=SizeOf(mCache);
          if mToRead>mTotal then
          mToRead:=mTotal;

          (* attempt to read the spec. size *)
          mRead:=Read(mOffset,mToRead,mCache);
          if mRead>0 then
          begin
            (* output data to our writer *)
            mWriter.Write(mCache,mRead);

            (* update variables *)
            mOffset:=mOffset + mRead;
            mTotal:=mTotal - mRead;
          end else
          Break;
        end;
      finally
        (* flush our stream cache to medium *)
        mWriter.FlushBuffer;

        (* release writer object *)
        mWriter.free;
      end;
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATATARGET);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['SaveToStream',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   LoadFromStream()
    Purpose:  Loads the entire content of a stream into the current buffer.
    Comments: This method releases the current buffer and use Append()
              to insert data. Also, it takes height for the current
              position of the source stream - so make sure position is
              set to zero if you want to load the whole content. *)
procedure THexBuffer.LoadFromStream(Stream: TStream);
var
  mReader:  TReader;
  mTotal:   Int64;
  mToRead:  integer;
  mCache:   THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Check that buffer supports writing *)
  if (mcWrite in FCaps) then
  begin
    (* Check that buffer supports scaling *)
    if (mcScale in FCaps) then
    begin
      (* Validate source PTR *)
      if Stream<>NIL then
      begin
        (* Release current buffer *)
        Release;

        (* create our reader object to benefit from cache *)
        mReader:=TReader.Create(Stream,1024);
        try
          mTotal:=(Stream.Size - Stream.Position);
          While mTotal>0 do
          begin
            (* Clip chunk to read *)
            mToRead:=SizeOf(mCache);
            if mToRead>mTotal then
            mToRead:=mTotal;

            (* Read data *)
            mReader.read(mCache,mToRead);

            (* Append data to current *)
            self.Append(mCache,mToRead);

            (* Update count *)
            mTotal:=mTotal - mToRead;
          end;
        finally
          mReader.free;
        end;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['LoadFromStream',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexBuffer.EncryptTo(const Target: THexBuffer);
var
  LSource, LTarget: THexStreamAdapter;
begin
  if Target <> nil then
  begin
    LSource := THexStreamAdapter.Create(self);
    try
      LTarget := THexStreamAdapter.Create(Target);
      try
        if not (FEncryption.EncodeStream(LSource, LTarget) > 0) then
        raise EHexBufferError.Create('EncryptTo failed, internal encryption error');
      finally
        LTarget.Free;
      end;
    finally
      LSource.Free;
    end;
  end else
  raise EHexBufferError.Create('EncryptTo failed, target buffer cannot be NIL error');
end;

procedure THexBuffer.DecryptFrom(const Source: THexBuffer);
var
  LSource, LTarget: THexStreamAdapter;
begin
  if Source <> nil then
  begin
    LSource := THexStreamAdapter.Create(Source);
    try
      LTarget := THexStreamAdapter.Create(self);
      try

        if not Empty then
          Release();

        if not (FEncryption.DecodeStream(LSource, LTarget) > 0) then
        raise EHexBufferError.Create('DecryptFrom failed, internal encryption error');
      finally
        LTarget.Free;
      end;
    finally
      LSource.Free;
    end;
  end else
  raise EHexBufferError.Create('DecryptFrom failed, source buffer cannot be NIL error');
end;

function THexBuffer.EncryptTo: THexBuffer;
var
  LSource, LTarget: THexStreamAdapter;
begin
  result := THexBufferMemory.Create(nil);
  if not Empty then
  begin
    LSource := THexStreamAdapter.Create(self);
    try
      LTarget := THexStreamAdapter.Create(result);
      try
        if not (FEncryption.EncodeStream(LSource, LTarget) > 0) then
        raise EHexBufferError.Create('EncryptTo failed, internal encryption error');
      finally
        LTarget.Free;
      end;
    finally
      LSource.Free;
    end;
  end;
end;

function THexBuffer.DecryptTo: THexBuffer;
var
  LSource, LTarget: THexStreamAdapter;
begin
  result := THexBufferMemory.Create(nil);
  if not Empty then
  begin
    LSource := THexStreamAdapter.Create(self);
    try
      LTarget := THexStreamAdapter.Create(result);
      try
        if not (FEncryption.DecodeStream(LSource, LTarget) > 0) then
        raise EHexBufferError.Create('DecryptTo failed, internal encryption error');
      finally
        LTarget.Free;
      end;
    finally
      LSource.Free;
    end;
  end;
end;

procedure THexBuffer.Encrypt;
var
  LTemp:  THexBufferMemory;
begin
  LTemp := THexBufferMemory.Create(nil);
  try
    self.EncryptTo(LTemp);
    self.Release();
    self.Append(LTemp);
  finally
    LTemp.Free;
  end;
end;

procedure THexBuffer.Decrypt;
var
  LTemp:  THexBufferMemory;
begin
  LTemp := THexBufferMemory.Create(nil);
  try
    LTemp.DecryptFrom(self);
    self.Release();
    self.Append(LTemp);
  finally
    LTemp.Free;
  end;
end;

{$IFDEF HEX_SUPPORT_ZLIB}
function THexBuffer.CompressTo:THexBuffer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result := THexBufferMemory.Create(nil);
  self.CompressTo(result);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['CompressTo',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF HEX_SUPPORT_ZLIB}
procedure THexBuffer.Compress;
var
  mTemp:  THexBuffer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mTemp:=CompressTo;
  try
    self.Release;
    self.Append(mTemp);
  finally
    mTemp.Free;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Compress',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF HEX_SUPPORT_ZLIB}
procedure THexBuffer.Decompress;
var
  mTemp:  THexBuffer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  mTemp:=self.DecompressTo;
  try
    self.Release;
    self.Append(mTemp);
  finally
    mTemp.Free;
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Decompress',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF HEX_SUPPORT_ZLIB}
function THexBuffer.DecompressTo:THexBuffer;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result:=THexBufferMemory.Create(nil);
  result.DeCompressFrom(self);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DecompressTo',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF HEX_SUPPORT_ZLIB}
procedure THexBuffer.DeCompressFrom(const Source:THexBuffer);
var
  FZRec:      TZStreamRec;
  FInput:     Packed array [word] of Byte;
  FOutput:    Packed array [word] of Byte;
  FReader:    THexReaderBuffer;
  FWriter:    THexWriterBuffer;
  FBytes:     integer;

  procedure CCheck(const Code:integer);
  begin
    if Code<0 then
    begin
      Case Code of
      Z_STREAM_ERROR:
        raise EHexBufferError.CreateFmt('ZLib stream error #%d',[code]);
      Z_DATA_ERROR:
        raise EHexBufferError.CreateFmt('ZLib data error #%d',[code]);
      Z_BUF_ERROR:
        raise EHexBufferError.CreateFmt('ZLib buffer error #%d',[code]);
      Z_VERSION_ERROR:
        raise EHexBufferError.CreateFmt('ZLib version conflict [#%d]',[code]);
      else
        raise EHexBufferError.CreateFmt('Unspecified ZLib error #%d',[Code]);
      end;
    end;
  end;

begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}

  (* Populate ZLIB header *)
  Fillchar(FZRec,SizeOf(FZRec),0);
  FZRec.zalloc:=zlibAllocMem;
  FZRec.zfree:=zlibFreeMem;

  FzRec.next_in:=Addr(FInput);
  FzRec.next_out:=Addr(FOutput);

  (* release current content if any *)
  If not Empty then
  Release;

  (* initialize ZLIB compression *)
  CCheck(inflateInit_(FZRec,zlib_version,sizeof(FZRec)));
  try
    FReader:=THexReaderBuffer.Create(Source);
    try
      FWriter:=THexWriterBuffer.Create(self);
      try

        (* Signal Uncompress begins *)
        if assigned(OnDeCompressionBegins) then
        OnDeCompressionBegins(self,size);

        Repeat
          (* Get more input *)
          If FzRec.avail_in=0 then
          begin
            FzRec.avail_in:=FReader.Read(FInput,SizeOf(FInput));
            If FzRec.avail_in>0 then
            FzRec.next_in:=Addr(FInput) else
            Break;
          end;

          (* decompress input *)
          Repeat
            FzRec.next_out:=Addr(FOutput);
            FzRec.avail_out:=SizeOf(FOutput);
            CCheck(inflate(FZRec,Z_NO_FLUSH));
            FBytes:=SizeOf(FOutput) - FzRec.avail_out;
            if FBytes>0 then
            begin
              FWriter.Write(FOutput,FBytes);
              FzRec.next_out:=Addr(FOutput);
              FzRec.avail_out:=SizeOf(FOutput);
            end;
          Until FzRec.avail_in=0;

          (* Signal Inflate progress *)
          if assigned(OnDeCompressionUpdate) then
          OnDeCompressionUpdate(self,FReader.Position,Size);
        Until False;

        (* Signal Compression Ends event *)
        if assigned(OnDeCompressionEnds) then
        OnDeCompressionEnds(self,FReader.Position,FWriter.Position);
      finally
        FWriter.free;
      end;
    finally
      FReader.free;
    end;
  finally
    (* end Zlib compression *)
    inflateEnd(FZRec);
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['DeCompressFrom',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF HEX_SUPPORT_ZLIB}
procedure THexBuffer.CompressTo(const Target:THexBuffer);
var
  FZRec:      TZStreamRec;
  FInput:     Packed array [Word] of Byte;
  FOutput:    Packed array [Word] of Byte;
  FReader:    THexReaderBuffer;
  FWriter:    THexWriterBuffer;
  FMode:      integer;
  FBytes:     integer;

  procedure CCheck(const Code:integer);
  begin
    if Code<0 then
    begin
      Case Code of
      Z_STREAM_ERROR:
        raise EHexBufferError.CreateFmt('ZLib stream error #%d',[code]);
      Z_DATA_ERROR:
        raise EHexBufferError.CreateFmt('ZLib data error #%d',[code]);
      Z_BUF_ERROR:
        raise EHexBufferError.CreateFmt('ZLib buffer error #%d',[code]);
      Z_VERSION_ERROR:
        raise EHexBufferError.CreateFmt('ZLib version conflict [#%d]',[code]);
      else
        raise EHexBufferError.CreateFmt('Unspecified ZLib error #%d',[Code]);
      end;
    end;
  end;

begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Populate ZLIB header *)
  Fillchar(FZRec,SizeOf(FZRec),0);
  FZRec.zalloc:=zlibAllocMem;
  FZRec.zfree:=zlibFreeMem;
  FzRec.next_in:=Addr(FInput);
  FZRec.next_out := Addr(FOutput);
  FZRec.avail_out := sizeof(FOutput);

  (* initialize ZLIB compression *)
  CCheck(deflateInit_(FZRec,Z_BEST_COMPRESSION,
  zlib_version,sizeof(FZRec)));

  try
    FReader:=THexReaderBuffer.Create(self);
    try
      FWriter:=THexWriterBuffer.Create(target);
      try

        FMode:=Z_NO_Flush;

        (* Signal Compression begins *)
        if assigned(OnCompressionBegins) then
        OnCompressionBegins(self,Size);

        Repeat
          (* more data required? If not, finish *)
          If FzRec.avail_in=0 then
          begin
            If FReader.Position<Size then
            begin
              FzRec.avail_in:=FReader.Read(FInput,SizeOf(FInput));
              FzRec.next_in:=@FInput
            end else
            FMode:=Z_Finish;
          end;

          (* Continue compression operation *)
          CCheck(deflate(FZRec,FMode));

          (* Write compressed data if any.. *)
          FBytes:=SizeOf(FOutput) - FzRec.avail_out;
          if FBytes>0 then
          begin
            FWriter.Write(FOutput,FBytes);
            FzRec.next_out:=@FOutput;
            FzRec.avail_out:=SizeOf(FOutput);
          end;

          (* Signal Compression Progress Event *)
          if assigned(OnCompressionUpdate) then
          OnCompressionUpdate(self,FReader.Position,Size);

        Until (FBytes=0) and (FMode=Z_Finish);

        (* Signal Compression Ends event *)
        if assigned(OnCompressionEnds) then
        OnCompressionEnds(self,FReader.Position,Size);

      finally
        FWriter.free;
      end;
    finally
      FReader.free;
    end;
  finally
    (* end Zlib compression *)
    deflateEnd(FZRec);
  end;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['CompressTo',e.classname,e.message]);
  end;
  {$ENDIF}
end;
{$ENDIF}


(*  Method:   ExportTo()
    Purpose:  The ExportTo method allows you to read from the buffer,
              but output the data to an alternative target. In this case
              a TWriter class, which comes in handy when working
              with persistence.
    Comments: This method calls Write() to do the actual reading *)
function  THexBuffer.ExportTo(ByteIndex: Int64;
          DataLength: integer;const Writer:TWriter):  integer;
var
  mToRead:  integer;
  mRead:    integer;
  mCache:   THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Check that buffer supports reading *)
  if (mcRead in FCaps) then
  begin
    (* Check length of export *)
    if DataLength>0 then
    begin
      (* Validate writer PTR *)
      if Writer<>NIL then
      begin
        (* Keep going while there is data *)
        While DataLength>0 do
        begin
          (* Clip prefetch to actual length *)
          mToRead:=EnsureRange(SizeOf(mCache),0,DataLength);

          (* read from our buffer *)
          mRead:=Read(ByteIndex,mToRead,mCache);

          (* Anything read? *)
          if mRead>0 then
          begin
            (* output data to writer *)
            Writer.Write(mCache,mRead);

            (* update variables *)
            ByteIndex:=ByteIndex + mRead;
            DataLength:=DataLength - mRead;
            result:=result + mRead;
          end else
          Break;
        end;

        (* flush writer cache to medium, this is important *)
        Writer.FlushBuffer;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATATARGET);
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ExportTo',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Read()
    Purpose:  The read method allows you to read from the buffer into
              an untyped targetbuffer. *)
function  THexBuffer.Read(const ByteIndex:Int64;
          DataLength: integer;var Data):  integer;
var
  mTotal:   Int64;
  mRemains: Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Check that our buffer supports reading *)
  if (mcRead in FCaps) then
  begin
    (* Check length of read *)
    if DataLength>0 then
    begin
      (* Get current size of buffer *)
      mTotal:=DoGetDataSize;

      (* anything to read from? *)
      if mTotal>0 then
      begin
        (* make sure entry is within range *)
        if (ByteIndex>=0) and (ByteIndex<mTotal) then
        begin
          (* Check that copy results in data move *)
          mRemains:=mTotal - ByteIndex;
          if mRemains>0 then
          begin
            (* clip copylength to edge of buffer if we need to *)
            if DataLength>mRemains then
            DataLength:=mRemains;

            (* Read data into buffer *)
            DoReadData(ByteIndex,Data,DataLength);

            (* return bytes moved *)
            result:=DataLength;
          end;
        end;
      end else
      raise EHexBufferError.Create(CNT_ERR_BTRG_EMPTY);
    end;
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Read',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   ImportFrom()
    Purpose:  The ImportFrom method allows you to write to the buffer,
              but using an alternative datasource. In this case a TReader
              class, which comes in handy when working with persistence.
    Comments: This method calls Write() to do the actual writing  *)
function  THexBuffer.ImportFrom(ByteIndex: Int64;DataLength: integer;const Reader: TReader):  integer;
var
  mToRead:  integer;
  mCache:   THexIOCache;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Check that buffer supports writing *)
  if (mcWrite in FCaps) then
  begin
    (* Check that Reader PTR is valid *)
    if (Reader<>NIL) then
    begin
      (* keep going until no more data *)
      While DataLength>0 do
      begin
        (* Clip prefetch to make sure we dont read to much *)
        mToRead:=EnsureRange(SizeOf(mCache),0,DataLength);

        (* Anything to read after clipping? *)
        if mToRead>0 then
        begin
          (* read from source *)
          Reader.Read(mCache,mToRead);

          (* write to target *)
          Write(ByteIndex,mToRead,mCache);

          (* update variables *)
          result:=result + mToRead;
          ByteIndex:=ByteIndex + mToRead;
          DataLength:=DataLength - mToRead;
        end else
        Break;
      end;
    end else
    raise EHexBufferError.Create(CNT_ERR_BTRG_INVALIDDATASOURCE);
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['ImportFrom',e.classname,e.message]);
  end;
  {$ENDIF}
end;

(*  Method:   Write()
    Purpose:  The write method allows you to write data into the buffer.
              It uses the internal mechanisms to do the actual writing,
              which means that how the data is written depends on the
              buffer implementation and medium.
    Comments: This method supports scaling and will automatically
              resize the buffer to fit the new data. if the byteindex is
              within range of the current buffer - the trailing data will
              be overwritten (same as a normal MOVE operation in memory). *)
function  THexBuffer.Write(const ByteIndex: Int64; DataLength: integer; const Data):  integer;
var
  mTotal:   Int64;
  mending:  Int64;
  mExtra:   Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  (* Initialize *)
  result:=0;

  (* Check that buffer supports writing *)
  if (mcWrite in FCaps) then
  begin
    (* Make sure there is data to write *)
    if DataLength>0 then
    begin
      (* Get current data size. if it's empty we will go for
         a straight append instead, see further down *)
      mTotal:=DoGetDataSize;
      if mTotal>0 then
      begin
        (* offset within range of allocation? *)
        if (ByteIndex>=0) and (ByteIndex<mTotal) then
        begin
          (* does this write exceed the current buffer size? *)
          mending:=ByteIndex + DataLength;
          if mending>mTotal then
          begin
            (* by how much? *)
            mExtra:=mending - mTotal;

            (* Check that we support scaling, grow if we can.
               Otherwise just clip the data to the current buffer size *)
            if (mcScale in FCaps) then
            DoGrowDataBy(mExtra) else
            DataLength:=EnsureRange(DataLength - mExtra,0,MAXINT);
          end;

          (* Anything to work with? *)
          if DataLength>0 then
          DoWriteData(ByteIndex,Data,DataLength);

          (* retun bytes written *)
          result:=DataLength;
        end else
        raise EHexBufferError.CreateFmt
        (CNT_ERR_BTRG_BYTEINDEXVIOLATION,[0,mTotal-1,ByteIndex]);
      end else
      begin
        (* Check that buffer supports scaling *)
        if (mcScale in FCaps) then
        begin
          (* Grow the current buffer to new size *)
          DoGrowDataBy(DataLength);

          (* write data *)
          DoWriteData(0,Data,DataLength);

          (* return bytes written *)
          result:=DataLength;
        end else
        raise EHexBufferError.Create(CNT_ERR_BTRG_SCALENOTSUPPORTED);
      end;
    end;
  end else
  raise EHexBufferError.Create(CNT_ERR_BTRG_WRITENOTSUPPORTED);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Write',e.classname,e.message]);
  end;
  {$ENDIF}
end;


//##########################################################################
// THexStreamAdapter
//##########################################################################

constructor THexStreamAdapter.Create(const SourceBuffer:THexBuffer);
begin
  inherited Create;
  if (SourceBuffer <> nil) then
  FBufObj := SourceBuffer else
  raise EHexStreamAdapter.Create(CNT_ERR_BTRGSTREAM_INVALIDBUFFER);
end;

function THexStreamAdapter.GetSize:Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result:=FBufObj.Size;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['GetSize',e.classname,e.message]);
  end;
  {$ENDIF}
end;

procedure THexStreamAdapter.SetSize(const NewSize: Int64);
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  FBufObj.Size:=NewSize;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['SetSize',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexStreamAdapter.Read(var Buffer;Count: longint):  longint;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  result:=FBufObj.Read(FOffset,Count,Buffer);
  inc(FOffset,result);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Read',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexStreamAdapter.Write(const Buffer;Count:longint):  longint;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  if FOffset=FBufObj.Size then
  begin
    FBufObj.Append(Buffer,Count);
    result:=Count;
  end else
  result:=FBufObj.Write(FOffset,Count,Buffer);
  inc(FOffset,result);
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Write',e.classname,e.message]);
  end;
  {$ENDIF}
end;

function THexStreamAdapter.Seek(const Offset:Int64;
         Origin:TSeekOrigin): Int64;
begin
  {$IFDEF HEX_DEBUG}
  try
  {$ENDIF}
  Case Origin of
  sobeginning:
    begin
      if Offset>=0 then
      FOffset:=EnsureRange(Offset,0,FBufObj.Size);
    end;
  soCurrent:
    begin
      FOffset:=EnsureRange(FOffset + Offset,0,FBufObj.Size);
    end;
  soEnd:
    begin
      if Offset>0 then
      FOffset:=FBufObj.Size-1 else
      FOffset:=EnsureRange(FOffset-(abs(Offset)),0,FBufObj.Size);
    end;
  end;
  result:=FOffset;
  {$IFDEF HEX_DEBUG}
  except
    on e: exception do
    raise EHexBufferError.CreateFmt
    (CNT_ERR_BTRG_BASE,['Seek',e.classname,e.message]);
  end;
  {$ENDIF}
end;


//##########################################################################
// THexWriterStream
//##########################################################################

constructor THexWriterStream.Create(const Target: TStream);
begin
  inherited Create;
  TextEncoding := TEncoding.Default;
  if Target<>NIL then
  FStream:=target else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDTARGET);
end;

function THexWriterStream.Write(const Data;
         DataLen:integer):  integer;
begin
  if DataLen>0 then
  begin
    result:=FStream.Write(Data,DataLen);
    Advance(result);
  end else
  result:=0;
end;

//##########################################################################
// THexReaderStream
//##########################################################################

constructor THexReaderStream.Create(const Source: TStream);
begin
  inherited Create;
  TextEncoding := TEncoding.Default;
  if source<>NIL then
  FStream:=Source else
  raise EHexReader.Create(ERR_HEX_READER_INVALIDSOURCE);
end;

function THexReaderStream.Read(var Data;DataLen:integer):  integer;
begin
  if DataLen>0 then
  begin
    result:=FStream.Read(Data,DataLen);
    Advance(result);
  end else
  result:=0;
end;

//##########################################################################
// TSRLDataWriter
//##########################################################################

constructor THexWriterBuffer.Create(const Target:THexBuffer);
begin
  inherited Create;
  TextEncoding := TEncoding.Default;
  if Target<>NIl then
  FData:=Target else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDTARGET);
end;

function THexWriterBuffer.Write(const Data;DataLen:integer):  integer;
var
  FTotal: Int64;
begin
  if DataLen>0 then
  begin
    FTotal:=FData.Size;
    if (FTotal>0) and (Position<FTotal) then
    FData.Write(Position,DataLen,Data) else
    FData.Append(Data,DataLen);

    Advance(DataLen);
    result:=DataLen;
  end else
  result:=0;
end;

//##########################################################################
// THexReaderBuffer
//##########################################################################

constructor THexReaderBuffer.Create(const Source:THexBuffer);
begin
  inherited Create;
  TextEncoding := TEncoding.Default;
  if Source=NIl then
  raise EHexReader.Create(ERR_HEX_READER_INVALIDSOURCE) else
  FData:=Source;
end;

function THexReaderBuffer.Read(var Data;DataLen:integer):  integer;
begin
  if DataLen>0 then
  begin
    result:=FData.Read(Position,DataLen,data);
    Advance(result);
  end else
  result:=0;
end;

//##########################################################################
// THexReader
//##########################################################################

procedure THexReader.Reset;
begin
  FOffset:=0;
end;

procedure THexReader.Advance(const Value:integer);
begin
  if Value>0 then
  FOffset:=FOffset + Value;
end;

function THexReader.Readbyte:byte;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadBool: boolean;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadWord:Word;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadSmall:SmallInt;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadPointer:Pointer;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadInt: integer;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadLong:longword;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadInt64:Int64;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadCurrency:Currency;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadGUID:TGUID;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadShort:Shortint;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadSingle:Single;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadDouble:Double;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function THexReader.ReadDateTime:TDateTime;
begin
  if Read(result,SizeOf(result))<SizeOf(result) then
  raise EHexReader.Create(ERR_HEX_READER_FAILEDREAD);
end;

function  THexReader.CopyTo(const Writer:THexWriter;
          CopyLen:integer):  integer;
var
  FRead:        integer;
  FbytesToRead: integer;
  FWritten:     integer;
  FCache:       THexIOCache;
begin
  if Writer<>NIL then
  begin
    result:=0;
    While CopyLen>0 do
    begin
      FbytesToRead:=EnsureRange(SizeOf(FCache),0,CopyLen);
      FRead:=Read(FCache,FbytesToRead);
      if FRead>0 then
      begin
        FWritten:=Writer.Write(FCache,FRead);
        dec(CopyLen,FWritten);
        inc(result,FWritten);
      end else
      Break;
    end;
  end else
  raise EHexReader.Create(ERR_HEX_READER_INVALIDOBJECT);
end;

function THexReader.CopyTo(const Binary:THexBuffer;
         const CopyLen:integer):  integer;
var
  FWriter: THexWriter;
begin
  if Binary<>NIL then
  begin
    FWriter:=THexWriterBuffer.Create(Binary);
    try
      result:=CopyTo(FWriter,CopyLen);
    finally
      FWriter.free;
    end;
  end else
  raise EHexReader.Create(ERR_HEX_READER_INVALIDOBJECT);
end;

function  THexReader.CopyTo(const Stream: TStream;
          const CopyLen:integer):  integer;
var
  FWriter: THexWriterStream;
begin
  if Stream<>NIL then
  begin
    FWriter:=THexWriterStream.Create(Stream);
    try
      result:=CopyTo(FWriter,CopyLen);
    finally
      FWriter.free;
    end;
  end else
  raise EHexReader.Create(ERR_HEX_READER_INVALIDOBJECT);
end;

function THexReader.ContentToStream: TStream;
var
  FRead:  integer;
  FCache: THexIOCache;
begin
  result:=TMemoryStream.Create;
  try
    While True do
    begin
      FRead:=Read(FCache,SizeOf(FCache));
      if FRead>0 then
      result.WriteBuffer(FCache,FRead) else
      Break;
    end;
  except
    on e: exception do
    begin
      FreeAndNil(result);
      raise EHexReader.Create(e.message);
    end;
  end;
end;

function THexReader.ReadNone(Length:integer):  integer;
var
  FToRead:  integer;
  FRead:    integer;
  FCache:   THexIOCache;
begin
  result:=0;
  if Length>0 then
  begin
    try
      While Length>0 do
      begin
        FToRead:=EnsureRange(SizeOf(FCache),0,Length);
        FRead:=Read(FCache,FToRead);
        if FRead>0 then
        begin
          Length:=Length - FRead;
          result:=result + FRead;
        end else
        Break;
      end;
    except
      on e: exception do
      raise EHexReader.Create(e.message);
    end;
  end;
end;

function THexReader.ContentToData:THexBuffer;
var
  FRead:  integer;
  FCache: THexIOCache;
begin
  result:=THexBufferMemory.Create(nil);
  try
    While True do
    begin
      FRead:=Read(FCache,SizeOf(FCache));
      if FRead>0 then
      result.Append(FCache,FRead) else
      Break;
    end;
  except
    on e: exception do
    begin
      FreeAndNil(result);
      raise EHexReader.Create(e.message);
    end;
  end;
end;

function THexReader.ReadString: string;
var
  LBytes: integer;
  LEncoding: word;
  LTemp: TBytes;
begin
  // Read the encoding
  LEncoding := ReadWord;

  // Read the length in bytes of the encoded data
  LBytes := ReadInt;

  // Anything to decode?
  if LBytes>0 then
  begin
    //LData := allocmem(LBytes);
    SetLength(LTemp, LBytes);
    try
      // Read the data chunk
      Read(LTemp[0],LBytes);

      case LEncoding of
      CNT_HEX_ANSI_STRING_HEADER:  result := TEncoding.ANSI.Getstring(LTemp);
      CNT_HEX_ASCI_STRING_HEADER:  result := TEncoding.ASCII.Getstring(LTemp);
      CNT_HEX_UNIC_STRING_HEADER:  result := TEncoding.Unicode.Getstring(LTemp);
      CNT_HEX_UTF7_STRING_HEADER:  result := TEncoding.UTF7.Getstring(LTemp);
      CNT_HEX_UTF8_STRING_HEADER:  result := TEncoding.UTF8.Getstring(LTemp);
      CNT_HEX_DEFA_STRING_HEADER:  result := TEncoding.Default.Getstring(LTemp);
      else
        raise EHexReader.CreateFmt
        (ERR_HEX_READER_INVALIDHEADER,[CNT_HEX_DEFA_STRING_HEADER,LEncoding]);
      end;

    finally
      setlength(LTemp, 0);
    end;
  end;
end;

{$IFDEF HEX_SUPPORT_VARIANTS}
function THexReader.ReadVariant:Variant;
var
  FTemp:    Word;
  FKind:    TVarType;
  FCount,x: integer;
  FIsArray: boolean;

  function ReadVariantData:Variant;
  var
    FTyp: TVarType;
  begin
    FTyp:=ReadWord;
    Case FTyp of
    varError:     result:=VarAsError(ReadLong);
    varVariant:   result:=ReadVariant;
    varbyte:      result:=Readbyte;
    varboolean:   result:=ReadBool;
    varShortInt:  result:=ReadShort;
    varWord:      result:=ReadWord;
    varSmallint:  result:=ReadSmall;
    varinteger:   result:=ReadInt;
    varlongword:  result:=ReadLong;
    varInt64:     result:=ReadInt64;
    varSingle:    result:=ReadSingle;
    varDouble:    result:=ReadDouble;
    varCurrency:  result:=ReadCurrency;
    varDate:      result:=ReadDateTime;
    varstring:    result:=Readstring;
    varOleStr:    result:=Readstring;
    end;
  end;

begin
  FTemp := ReadWord;
  if FTemp = CNT_HEX_VARIANT_HEADER then
  begin
    (* read datatype *)
    FKind:=TVarType(ReadWord);

    if not (FKind in [varEmpty,varNull]) then
    begin
      (* read array declaration *)
      FIsArray:=ReadBool;

      if FIsArray then
      begin
        FCount:=ReadInt;
        result:=VarArrayCreate([0,FCount-1],FKind);
        for x:=1 to FCount do
        VarArrayPut(result,ReadVariantData,[0,x-1]);
      end else
      result:=ReadVariantData;
    end else
    result:=NULL;

  end else
  raise EHexReader.CreateFmt(ERR_HEX_READER_INVALIDHEADER,[CNT_HEX_VARIANT_HEADER,FTemp]);
end;
{$ENDIF}

function THexReader.ReadData: THexBuffer;
var
  FTotal:   Int64;
  FToRead:  integer;
  FRead:    integer;
  FCache:   THexIOCache;
begin
  result := THexBufferMemory.Create(nil);
  try
    FTotal:=ReadInt64;
    While FTotal>0 do
    begin
      FToRead:=EnsureRange(SizeOf(FCache),0,FTotal);
      FRead:=Read(FCache,FToRead);
      if FRead>0 then
      begin
        result.Append(FCache,FRead);
        FTotal:=FTotal - FRead;
      end else
      Break;
    end;
  except
    on e: exception do
    begin
      FreeAndNil(result);
      raise EHexReader.Create(e.message);
    end;
  end;
end;

function THexReader.ReadStream: TStream;
var
  FTotal:   Int64;
  FToRead:  integer;
  FRead:    integer;
  FCache:   THexIOCache;
begin
  result:=TMemoryStream.Create;
  try
    FTotal:=ReadInt64;
    While FTotal>0 do
    begin
      FToRead:=EnsureRange(SizeOf(FCache),0,FTotal);
      FRead:=Read(FCache,FToRead);
      if FRead>0 then
      begin
        result.WriteBuffer(FCache,FRead);
        FTotal:=FTotal - FRead;
      end else
      Break;
    end;
    result.Position:=0;
  except
    on e: exception do
    begin
      FreeAndNil(result);
      raise EHexReader.Create(e.message);
    end;
  end;
end;

//##########################################################################
// THexWriter
//##########################################################################

procedure THexWriter.Reset;
begin
  FOffset:=0;
end;

procedure THexWriter.Advance(const Value: integer);
begin
  if Value>0 then
  FOffset:=FOffset + Value;
end;

{$IFDEF HEX_SUPPORT_VARIANTS}
procedure THexWriter.WriteVariant(const Value: variant);
var
  FKind:    TVarType;
  FCount,x: integer;
  FIsArray: boolean;
  //FData:    Pbyte;

  procedure WriteVariantData(const VarValue: variant);
  var
    FAddr:  PVarData;
  begin
    FAddr:=FindVarData(VarValue);
    if FAddr<>NIL then
    begin
      (* write datatype *)
      WriteWord(FAddr^.VType);

      (* write variant content *)
      Case FAddr^.VType of
      varVariant:   WriteVariantData(VarValue);
      varError:     WriteLong(TVarData(varValue).VError);
      varbyte:      Writebyte(FAddr^.Vbyte);
      varboolean:   WriteBool(FAddr^.Vboolean);
      varShortInt:  WriteShort(FAddr^.VShortInt);
      varWord:      WriteWord(FAddr^.VWord);
      varSmallint:  WriteSmall(FAddr^.VSmallInt);
      varinteger:   WriteInt(FAddr^.Vinteger);
      varlongword:  WriteLong(FAddr^.VLongword);
      varInt64:     WriteInt64(FAddr^.VInt64);
      varSingle:    WriteSingle(FAddr^.VSingle);
      varDouble:    WriteDouble(FAddr^.VDouble);
      varCurrency:  WriteCurrency(FAddr^.VCurrency);
      varDate:      WriteDateTime(FAddr^.VDate);
      varstring:    Writestring(string(FAddr^.Vstring));
      varOleStr:    Writestring(string(FAddr^.Vstring));
      end;
    end;
  end;
begin
  (* Extract datatype & exclude array info *)
  FKind:=VarType(Value) and varTypeMask;

  (* Write variant header *)
  WriteWord(CNT_HEX_VARIANT_HEADER);

  (* write datatype *)
  WriteWord(FKind);

  (* Content is array? *)
  FIsArray:=VarIsArray(Value);

  (* write array declaration *)
  if not (FKind in [varEmpty,varNull]) then
  begin
    (* write TRUE if variant is an array *)
    WriteBool(FIsArray);

    (* write each item if array, or just the single one.. *)
    if FIsArray then
    begin
      (* write # of items *)
      FCount:=VarArrayHighBound(Value,1) - VarArrayLowBound(Value,1) + 1;
      WriteInt(FCount);

      (* write each element in array *)
      for x:=VarArrayLowBound(Value,1) to VarArrayHighBound(Value,1) do
      WriteVariantData(VarArrayGet(Value,[1,x-1]));

    end else
    WriteVariantData(Value);
  end;
end;
{$ENDIF}

procedure THexWriter.Writebyte(const Value: byte);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteShort(const Value: shortint);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteBool(const Value: boolean);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteWord(const Value: Word);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteSmall(const Value: smallint);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WritePointer(const Value: pointer);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteInt(const Value: integer);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteLong(const Value: longword);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteGUID(const Value: TGUID);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteInt64(const Value: Int64);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteCurrency(const Value: Currency);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteSingle(const Value: single);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteDouble(const Value: double);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteDateTime(const Value: TDateTime);
begin
  if Write(Value,SizeOf(Value))<SizeOf(Value) then
  raise EHexWriter.Create(ERR_HEX_WRITER_FAILEDWRITE);
end;

procedure THexWriter.WriteFile(const Filename: string);
var
  FFile: TFileStream;
begin
  FFile:=TFileStream.Create(Filename,fmOpenRead or fmShareDenyNone);
  try
    WriteStreamContent(FFile,False);
  finally
    FFile.free;
  end;
end;

procedure THexWriter.WriteStreamContent(const Content: TStream;
  const Disposable: boolean=False);
var
  FTotal:     Int64;
  FRead:      integer;
  FWritten:   integer;
  FCache:     THexIOCache;
begin
  if Content<>NIl then
  begin
    try
      FTotal:=Content.Size;
      if FTotal>0 then
      begin
        Content.Position:=0;
        Repeat
          FRead:=Content.Read(FCache,SizeOf(FCache));
          if FRead>0 then
          begin
            FWritten:=Write(FCache,FRead);
            FTotal:=FTotal - FWritten;
          end;
        Until (FRead<1) or (FTotal<1);
      end;
    finally
      if Disposable then
      Content.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

procedure THexWriter.WriteDataContent(const Content: THexBuffer;
  const Disposable: boolean = false);
var
  Fbytes:   integer;
  FRead:    integer;
  FWritten: integer;
  FOffset:  integer;
  FCache:   THexIOCache;
begin
  if (Content <> NIl) then
  begin
    try
      FOffset:=0;
      Fbytes:=Content.Size;

      Repeat
        FRead:=Content.Read(FOffset,SizeOf(FCache),FCache);
        if FRead>0 then
        begin
          FWritten:=Write(FCache,FRead);
          Fbytes:=Fbytes-FWritten;
          FOffset:=FOffset + FWritten;
        end;
      Until (FRead<1) or (Fbytes<1);

    finally
      if Disposable then
      Content.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

procedure THexWriter.WriteData(const Data: THexBuffer;
  const Disposable: boolean);
var
  FTemp:  Int64;
begin
  if (Data <> nil) then
  begin
    try
      FTemp := Data.Size;
      WriteInt64(FTemp);
      if FTemp>0 then
        WriteDataContent(Data);
    finally
      if Disposable then
      Data.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

procedure THexWriter.WriteStream(const Value: TStream;
          const Disposable: boolean);
begin
  if Value<>NIl then
  begin
    try
      WriteInt64(Value.Size);
      if Value.Size>0 then
      WriteStreamContent(Value);
    finally
      if Disposable then
      Value.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

function THexWriter.CopyFrom(const Reader:THexReader;
          DataLen:Int64): Int64;
var
  FRead:        integer;
  FbytesToRead: integer;
  FCache:       THexIOCache;
begin
  if Reader<>NIL then
  begin
    result:=0;
    While DataLen>0 do
    begin
      {FbytesToRead:=Sizeof(FCache);
      if FbytesToRead>DataLen then
      FbytesToRead:=DataLen; }
      FbytesToRead:=EnsureRange(SizeOf(FCache),0,DataLen);

      FRead:=Reader.Read(FCache,FbytesToRead);
      if FRead>0 then
      begin
        Write(FCache,FRead);
        DataLen:=DataLen - FRead;
        result:=result + FRead;
      end else
      Break;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

function THexWriter.CopyFrom(const Stream: TStream;
         const DataLen:Int64): Int64;
var
  FReader: THexReaderStream;
begin
  if Stream<>NIL then
  begin
    FReader:=THexReaderStream.Create(Stream);
    try
      result:=CopyFrom(FReader,DataLen);
    finally
      FReader.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

function THexWriter.CopyFrom(const Data:THexBuffer;
         const DataLen:Int64): Int64;
var
  FReader: THexReaderBuffer;
begin
  if Data<>NIL then
  begin
    FReader:=THexReaderBuffer.Create(Data);
    try
      result:=CopyFrom(FReader,DataLen);
    finally
      FReader.free;
    end;
  end else
  raise EHexWriter.Create(ERR_HEX_WRITER_INVALIDDATASOURCE);
end;

procedure THexWriter.__FillWord(dstAddr: pword;
  const inCount: integer; const Value: word);
var
  FTemp:  Longword;
  FLongs: integer;
begin
  FTemp:=Value shl 16 or Value;
  FLongs:=inCount shr 3;
  while FLongs>0 do
  begin
    PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
    PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
    PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
    PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
    dec(FLongs);
  end;

  Case inCount mod 8 of
  1:  dstAddr^:=Value;
  2:  PLongword(dstAddr)^:=FTemp;
  3:  begin
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        dstAddr^:=Value;
      end;
  4:  begin
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp;
      end;
  5:  begin
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        dstAddr^:=Value;
      end;
  6:  begin
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp;
      end;
  7:  begin
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        PLongword(dstAddr)^:=FTemp; inc(PLongword(dstAddr));
        dstAddr^:=Value;
      end;
  end;
end;

procedure THexWriter.WriteCRLF(const Times: integer=1);
var
  FLen:   integer;
  FWord:  Word;
  FData:  Pointer;
begin
  if Times>0 then
  begin
    FWord:=2573; // [#13,#10]

    if Times=1 then
    Write(FWord,SizeOf(FWord)) else

    if Times=2 then
    begin
      Write(FWord,SizeOf(FWord));
      Write(FWord,SizeOf(FWord));
    end else

    if Times>2 then
    begin
      FLen:=SizeOf(FWord) * Times;
      FData:=Allocmem(FLen);
      try
        __FillWord(FData, Times, FWord);
        Write(FData^,FLen);
      finally
        FreeMem(FData);
      end;
    end;
  end;
end;

procedure THexWriter.Writestring(const Text: string);
begin
  Writestring(Text, FEncoding);
end;

procedure THexWriter.Writestring(const Text: string;
    const Encoding: TEncoding);
var
  LBytes: TBytes;
  LSize:  integer;
begin
  if Encoding = TEncoding.ANSI then
  begin
    LBytes := TEncoding.ANSI.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_ANSI_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end else
  if Encoding = TEncoding.ASCII then
  begin
    LBytes := TEncoding.ASCII.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_ASCI_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end else
  if Encoding = TEncoding.Unicode then
  begin
    LBytes := TEncoding.Unicode.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_UNIC_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end else
  if Encoding = TEncoding.UTF7 then
  begin
    LBytes := TEncoding.UTF7.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_UTF7_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end else
  if Encoding = TEncoding.UTF8 then
  begin
    LBytes := TEncoding.UTF8.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_UTF8_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end else
  if Encoding = TEncoding.Default then
  begin
    LBytes := TEncoding.Default.GetBytes(Text);
    LSize := length(LBytes);
    WriteWord(CNT_HEX_DEFA_STRING_HEADER);
    WriteInt(LSize);
    if LSize>0 then
    Write(LBytes[0],LSize);
  end;
end;

//############################################################################
// THexBitAccess
//############################################################################

procedure THexBitAccess.SetBuffer(NewBuffer: THexBuffer);
begin
  if FBuffer <> nil then
  FBuffer.RemoveFreeNotification(self);

  FBuffer := NewBuffer;

  if FBuffer <> nil then
  FBuffer.FreeNotification(self);
end;

procedure THexBitAccess.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);

  If (AComponent is THexBuffer) then
  begin
    Case Operation of
    opRemove: SetBuffer(NIL);
    opInsert: SetBuffer(THexBuffer(AComponent));
    end;
  end;
end;

function THexBitAccess.AsString(const CharsPerLine: integer = 32):  string;
var
  x:  NativeUInt;
  LBreak: integer;
begin
  SetLength(result,0);
  if FBuffer <> nil then
  begin
    LBreak := 0;
    for x:=0 to GetCount-1 do
    begin
      inc(LBreak);
      if readBit(x) then
      result := result + '1' else
      result := result + '0';
      if LBreak >= CharsPerLine then
      begin
        result := result + #13#10;
        LBreak := 0;
      end;
    end;
  end else
  raise EHexBitAccess.Create('AsString() failed, no buffer attached error');
end;

function THexBitAccess.FindIdleBit(const FromIndex: NativeUInt;
         out IdleBitIndex: NativeUInt):  boolean;
var
  x:      NativeUInt;
  LCount: NativeUInt;
begin
  if FBuffer <> nil then
  begin
    IdleBitIndex:=0;
    result := false;
    LCount := GetCount;
    if (FromIndex < LCount-1) then
    begin
      for x:=FromIndex to LCount-1 do
      begin
        if not ReadBit(x) then
        begin
          IdleBitIndex := x;
          result := true;
          break;
        end;
      end;
    end;
  end else
  raise EHexBitAccess.Create('FindIdleBit() failed, no buffer attached error');
end;

function THexBitAccess.ReadBit(const BitIndex: NativeInt):  boolean;
var
  mOffset:  NativeUInt;
  mBitOff:  0..255;
  mbyte:    byte;
begin
  if FBuffer <> nil then
  begin
    mOffset:=BitIndex shr 3;
    mBitOff:=BitIndex mod 8;
    if FBuffer.Read(mOffset,SizeOf(byte),mbyte)=SizeOf(byte) then
    result:=(mbyte and (1 shl (mBitOff mod 8)))<>0 else
    result:=False;
  end else
  raise EHexBitAccess.Create('ReadBit() failed, no buffer attached error');
end;

procedure THexBitAccess.WriteBit(const BitIndex: NativeInt;
  const Value: boolean);
var
  mOffset:  NativeUInt;
  mBitOff:  0..255;
  mbyte:    byte;
  mSet: boolean;
begin
  if FBuffer <> nil then
  begin
    mOffset:=BitIndex shr 3;
    mBitOff:=BitIndex mod 8;
    if FBuffer.Read(mOffset,SizeOf(byte),mbyte)=SizeOf(byte) then
    begin
      mSet:=(mbyte and (1 shl (mBitOff mod 8)))<>0;
      if mSet<>Value then
      begin
        case Value of
        True:   mbyte:=(mbyte or (1 shl (mBitOff mod 8)));
        false:  mbyte:=(mbyte and not (1 shl (mBitOff mod 8)));
        end;
        FBuffer.Write(mOffset,1,mbyte);
      end;
    end;
  end else
  raise EHexBitAccess.Create('WriteBit() failed, no buffer attached error');
end;

function THexBitAccess.GetCount: NativeUInt;
begin
  if FBuffer <> nil then
    result := FBuffer.Size shl 3
  else
    result := 0;
end;

//############################################################################
// THexPartsAccess
//############################################################################

procedure THexPartsAccess.Setup(const ReservedHeaderSize: integer; const PartSize: integer);
begin
  if Buffer <> nil then
  FBuffer := Buffer else
  raise EHexPartAccess.Create('Setup failed, buffer cannot be nil error');

  FHeadSize := EnsureRange(ReservedHeaderSize, 0, MaxInt);

  if (PartSize > 0) then
  FPartSize := PartSize else
  raise Exception.Create(CNT_PARTACCESS_PARTSIZEINVALID);
end;


procedure THexPartsAccess.SetBuffer(const NewBuffer: THexBuffer);
begin
  if NewBuffer <> FBuffer then
  begin
    if FBuffer <> nil then
    FBuffer.RemoveFreeNotification(self);

    FBuffer := NewBuffer;

    if FBuffer <> nil then
    FBuffer.FreeNotification(self);
  end;
end;


procedure THexPartsAccess.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
  If (AComponent is THexBuffer) then
  begin
    Case Operation of
    opRemove: SetBuffer(NIL);
    opInsert: SetBuffer(THexBuffer(AComponent));
    end;
  end;
end;

function THexPartsAccess.CalcPartsForData(const DataSize: Int64):  NativeInt;
begin
  result:=0;
  if FBuffer <> nil then
  begin
    if (DataSize>0) and (FPartSize>0) then
    begin
      result:=DataSize div FPartSize;
      if (result * FPartSize) < FBuffer.Size then
      inc(result);
    end;
  end else
  raise EHexPartAccess.Create('CalcPartsForData() failed, buffer is nil error');
end;

function THexPartsAccess.GetOffsetForPart(const PartIndex: integer):  Int64;
begin
  result:=FHeadSize + (PartIndex * FPartSize);
end;

function THexPartsAccess.GetPartCount: integer;
var
  LTotal: Int64;
begin
  result := -1;
  if assigned(FBuffer) then
  begin
    if FBuffer.Size>0 then
    begin
      if FPartSize>0 then
      begin
        LTotal := FBuffer.Size - FheadSize;
        result := LTotal div FPartSize;
        if (result * FPartSize) < LTotal then
        Inc(result);
      end;
    end;
  end;
end;

procedure THexPartsAccess.ReadPart(const PartIndex: integer; var Data);
var
  mOffset:  Int64;
begin
  if assigned(FBuffer) then
  begin
    if (mcRead in FBuffer.Capabilities) then
    begin
      mOffset:=getOffsetForPart(PartIndex);
      FBuffer.Read(mOffset,FPartSize,Data);
    end else
    raise Exception.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  end else
  raise EHexPartAccess.Create('ReadPart() failed, buffer is nil error');
end;

procedure THexPartsAccess.ReadPart(const PartIndex: integer;
  const Data: THexBuffer);
var
  LOffset:  Int64;
  LData:  Pointer;
begin
  if assigned(FBuffer) then
  begin
    if (mcRead in FBuffer.Capabilities) then
    begin
      if (Data <> nil) then
      begin
        Data.Release;
        LOffset:=getOffsetForPart(PartIndex);
        LData:=AllocMem(FPartSize);
        try
          FBuffer.Read(LOffset, FPartSize, LData^);
          Data.Append(LData^,FPartSize);
        finally
          FreeMem(LData);
        end;
      end else
      raise Exception.Create(CNT_PARTACCESS_TARGETBUFFERINVALID);
    end else
    raise Exception.Create(CNT_ERR_BTRG_READNOTSUPPORTED);
  end else
  raise EHexPartAccess.Create('ReadPart() failed, buffer is nil error');
end;

procedure THexPartsAccess.AppendPart(const Data; DataLength: integer);
var
  LData:  Pointer;
begin
  if assigned(FBuffer) then
  begin
    (* Check that buffer can scale and that we have write access *)
    if (mcWrite in FBuffer.Capabilities)
    and (mcScale in FBuffer.Capabilities) then
    begin
      DataLength:=EnsureRange(DataLength,0,FPartSize);
      if DataLength>0 then
      begin
        LData:=AllocMem(FPartSize);
        try
          THexBuffer.Fillbyte(Pbyte(LData),FPartSize,0);
          Move(Data,LData^,DataLength);
          FBuffer.Append(LData^,FPartSize);
        finally
          FreeMem(LData);
        end;
      end;
    end;
  end else
  raise EHexPartAccess.Create('AppendPart() failed, buffer is nil error');
end;

procedure THexPartsAccess.AppendPart(const Data: THexBuffer);
var
  mData:  Pointer;
  mLength:  integer;
begin
  if assigned(FBuffer) then
  begin
    (* Check that buffer can scale and that we have write access *)
    if (mcWrite in FBuffer.Capabilities)
    and (mcScale in FBuffer.Capabilities) then
    begin
      mLength:=EnsureRange(Data.Size,0,FPartSize);
      if mLength>0 then
      begin
        mData:=AllocMem(FPartSize);
        try
          Data.Read(0,mLength,mData^);
          FBuffer.Append(mData^,FPartSize);
        finally
          FreeMem(mData);
        end;
      end;
    end;
  end else
  raise EHexPartAccess.Create('AppendPart() failed, buffer is nil error');
end;

procedure THexPartsAccess.WritePart(const PartIndex: integer; const Data;
  const DataLength: integer);
var
  mOffset:  Int64;
begin
  if assigned(FBuffer) then
  begin
    (* Check that buffer have write access *)
    if (mcWrite in FBuffer.Capabilities) then
    begin
      if DataLength>0 then
      begin
        if FBuffer.Size>0 then
        begin
          mOffset:=getOffsetForPart(PartIndex);
          FBuffer.Write(mOffset,DataLength,Data);
        end;
      end;
    end;
  end else
  raise EHexPartAccess.Create('WritePart() failed, buffer is nil error');
end;

procedure THexPartsAccess.WritePart(const PartIndex: integer;
          const Data: THexBuffer);
var
  LOffset:  Int64;
  LData:  Pointer;
  LToRead:  integer;
begin
  if assigned(FBuffer) then
  begin
    (* Check that buffer have write access *)
    if (mcWrite in FBuffer.Capabilities) then
    begin
      if (Data<>NIL) and (Data.Size>0) then
      begin
        if FBuffer.Size>0 then
        begin
          LOffset:=getOffsetForPart(PartIndex);

          LToRead := EnsureRange(Data.Size,1,FPartSize);

          LData:=AllocMem(LToRead);
          try
            Data.Read(0,LToRead,LData^);
            FBuffer.Write(LOffset,LToRead,LData^);
          finally
            FreeMem(LData);
          end;
        end;
      end;
    end;
  end else
  raise EHexPartAccess.Create('WritePart() failed, buffer is nil error');
end;

//##########################################################################
// THexCustomRecord
//##########################################################################

constructor THexCustomRecord.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFNDEF USE_NEW_UNITNAMES}
  FObjects := TObjectList.Create(true);
  {$ELSE}
  FObjects := TObjectList<THexRecordField>.Create(true);
  {$ENDIF}
end;

destructor THexCustomRecord.Destroy;
begin
  FObjects.free;
  inherited;
end;

procedure THexCustomRecord.Assign(Source: TPersistent);
var
  mStream:  TStream;
begin
  if (Source<>nil)
  and (Source is THexCustomRecord) then
  begin
    mStream:=THexCustomRecord(source).ToStream;
    try
      LoadFromStream(mStream);
    finally
      mStream.Free;
    end;
  end else
  inherited;
end;

procedure THexCustomRecord.Clear;
begin
  FObjects.Clear;
end;

function THexCustomRecord.ToStream: TStream;
begin
  result:=TMemoryStream.Create;
  try
    SaveToStream(result);
    result.Position:=0;
  except
    on exception do
    begin
      FreeAndNIL(result);
      raise;
    end;
  end;
end;

function THexCustomRecord.ToBuffer: THexBuffer;
var
  mAdapter: THexStreamAdapter;
begin
  result:=THexBufferMemory.Create(nil);
  try
    mAdapter:=THexStreamAdapter.Create(result);
    try
      SaveToStream(mAdapter);
    finally
      mAdapter.Free;
    end;
  except
    on exception do
    begin
      FreeAndNIL(result);
      raise;
    end;
  end;
end;

procedure THexCustomRecord.SaveToStream(const Stream: TStream);
var
  x:  integer;
  mWriter:  TWriter;
  mHead:  Longword;
begin
  mWriter:=TWriter.Create(stream,1024);
  try
    mHead:=CNT_RECORD_HEADER;
    mWriter.Write(mHead,SizeOf(mHead));
    mWriter.Writeinteger(FObjects.Count);
    for x:=0 to FObjects.Count-1 do
    begin
      mWriter.Writestring(items[x].className);
      items[x].WriteObject(mWriter);
    end;
  finally
    mWriter.FlushBuffer;
    mWriter.Free;
  end;
end;

procedure THexCustomRecord.LoadFromStream(const Stream: TStream);
var
  x:  integer;
  mReader:  TReader;
  mHead:  Longword;
  mCount: integer;
  mName:  string;
  mField: THexRecordField;
begin
  Clear;
  mReader:=TReader.Create(stream,1024);
  try
    mReader.Read(mHead,SizeOf(mHead));
    if mHead=CNT_RECORD_HEADER then
    begin
      mCount:=mReader.Readinteger;
      for x:=0 to mCount-1 do
      begin
        mName:=mReader.Readstring;
        if HexRecordInstanceFromName(mName,mField) then
        begin
          self.FObjects.Add(mField);
          mField.ReadObject(mReader);
        end else
        raise EHexRecordError.CreateFmt
        ('Unknown field class [%s] error',[mName]);
      end;
    end else
    raise EHexRecordError.Create('Invalid record header error');
  finally
    mReader.Free;
  end;
end;

procedure THexCustomRecord.WriteInt(const FieldName: string;const Value:integer);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldInteger);
  THexFieldInteger(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteStr(const FieldName: string;const Value: string);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldString);
  THexFieldString(mRef).Value:=Value;
end;

procedure THexCustomRecord.Writebyte(const FieldName: string;const Value:byte);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldbyte);
  THexFieldbyte(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteBool(const FieldName: string;const Value: boolean);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldboolean);
  THexFieldboolean(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteCurrency(const FieldName: string;
          const Value:Currency);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldCurrency);
  THexFieldCurrency(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteData(const FieldName: string;const Value: TStream);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldData);
  if value<>NIL then
  THexFieldData(mRef).LoadFromStream(value);
end;

procedure THexCustomRecord.WriteDateTime(const FieldName: string;
          const Value:TDateTime);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldDateTime);
  THexFieldDateTime(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteDouble(const FieldName: string;
          const Value:Double);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldDouble);
  THexFieldDouble(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteGUID(const FieldName: string; const Value: TGUID);
var
  mRef: THexRecordField;
begin
  mRef := ObjectOf(FieldName);
  if mRef = NIL then
    mRef:=Add(FieldName, THexFieldGUID);
  THexFieldGUID(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteInt64(const FieldName: string;
          const Value:Int64);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldInt64);
  THexFieldInt64(mRef).Value:=Value;
end;

procedure THexCustomRecord.WriteLong(const FieldName: string;
          const Value:Longword);
var
  mRef: THexRecordField;
begin
  mRef:=ObjectOf(FieldName);
  if mRef=NIL then
  mRef:=Add(FieldName,THexFieldLong);
  THexFieldLong(mRef).Value:=Value;
end;

function THexCustomRecord.Addinteger(const FieldName: string): THexFieldInteger;
begin
  result:=THexFieldInteger(Add(FieldName,THexFieldInteger));
end;

function THexCustomRecord.AddStr(const FieldName: string): THexFieldString;
begin
  result:=THexFieldString(Add(FieldName,THexFieldString));
end;

function THexCustomRecord.Addbyte(const FieldName: string): THexFieldbyte;
begin
  result:=THexFieldbyte(Add(FieldName,THexFieldbyte));
end;

function THexCustomRecord.AddBool(const FieldName: string): THexFieldboolean;
begin
  result:=THexFieldboolean(Add(FieldName,THexFieldboolean));
end;

function THexCustomRecord.AddCurrency(const FieldName: string): THexFieldCurrency;
begin
  result:=THexFieldCurrency(Add(FieldName,THexFieldCurrency));
end;

function THexCustomRecord.AddData(const FieldName: string): THexFieldData;
begin
  result:=THexFieldData(Add(FieldName,THexFieldData));
end;

function THexCustomRecord.AddDateTime(const FieldName: string): THexFieldDateTime;
begin
  result:=THexFieldDateTime(Add(FieldName,THexFieldDateTime));
end;

function THexCustomRecord.AddDouble(const FieldName: string): THexFieldDouble;
begin
  result:=THexFieldDouble(Add(FieldName,THexFieldDouble));
end;

{$IFDEF VCL_TARGET}
function THexCustomRecord.AddGUID(const FieldName: string): THexFieldGUID;
begin
  result := THexFieldGUID(Add(FieldName,THexFieldGUID));
end;
{$ENDIF}

function THexCustomRecord.AddInt64(const FieldName: string): THexFieldInt64;
begin
  result:=THexFieldInt64(Add(FieldName,THexFieldInt64));
end;

function THexCustomRecord.AddLong(const FieldName: string): THexFieldLong;
begin
  result:=THexFieldLong(Add(FieldName,THexFieldLong));
end;

function THexCustomRecord.Add(const FieldName: string;
         const Fieldclass:THexRecordFieldclass): THexRecordField;
begin
  result:=ObjectOf(FieldName);
  if result=NIL then
  begin
    if Fieldclass<>NIL then
    begin
      result:=Fieldclass.Create(nil);
      result.FieldName := FieldName;
      FObjects.Add(result);
    end else
    result:=NIL;
  end;
end;

function THexCustomRecord.GetCount: integer;
begin
  result:=FObjects.Count;
end;

function THexCustomRecord.GetItem(const Index:integer): THexRecordField;
begin
  result:=THexRecordField(FObjects[index]);
end;

procedure THexCustomRecord.SetItem(const Index: integer;
          const value:THexRecordField);
begin
  THexRecordField(FObjects[index]).Assign(Value);
end;

function THexCustomRecord.GetField(const FieldName: string): THexRecordField;
begin
  result:=ObjectOf(FieldName);
end;

procedure THexCustomRecord.SetField(const FieldName: string;
          const Value:THexRecordField);
var
  FItem: THexRecordField;
begin
  FItem:=ObjectOf(FieldName);
  if FItem<>NIL then
  FItem.assign(Value);
end;

function THexCustomRecord.IndexOf(FieldName: string):  integer;
var
  x:  integer;
begin
  result:=-1;
  FieldName := trim(FieldName);
  FieldName := lowercase(FieldName);
  if length(FieldName)>0 then
  begin
    for x:=0 to FObjects.Count-1 do
    begin
      if lowercase(GetItem(x).FieldName) = FieldName then
      begin
        result:=x;
        Break;
      end;
    end;
  end;
end;

function THexCustomRecord.ObjectOf(FieldName: string): THexRecordField;
var
  x:      integer;
  FItem:  THexRecordField;
begin
  result:=NIL;
  FieldName := trim(FieldName);
  FieldName := lowercase(FieldName);
  if length(FieldName)>0 then
  begin
    for x:=0 to FObjects.Count-1 do
    begin
      FItem:=GetItem(x);
      if lowercase(FItem.FieldName) = FieldName then
      begin
        result:=FItem;
        Break;
      end;
    end;
  end;
end;

//##########################################################################
// THexFieldLong
//##########################################################################

function THexFieldLong.asstring: string;
begin
  result:=IntToStr(Value);
end;

function THexFieldLong.GetDisplayName: string;
begin
  result:='Longword';
end;

function THexFieldLong.GetValue:Longword;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldLong.SetValue(const NewValue:Longword);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// TSRLFieldInt64
//##########################################################################

function THexFieldInt64.asstring: string;
begin
  result:=IntToStr(Value);
end;

function THexFieldInt64.GetDisplayName: string;
begin
  result:='Int64';
end;

function THexFieldInt64.GetValue:Int64;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldInt64.SetValue(const NewValue:Int64);
begin
  if Write(0,SizeOf(NewValue),NewValue) < SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldInteger
//##########################################################################

function THexFieldInteger.asstring: string;
begin
  result:=IntToStr(Value);
end;

function THexFieldInteger.GetDisplayName: string;
begin
  result:='integer';
end;

function THexFieldInteger.GetValue: integer;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldInteger.SetValue(const NewValue:integer);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldGUID
//##########################################################################
{$IFDEF VCL_TARGET}
function THexFieldGUID.asstring: string;
begin
  result:=string(HexGUIDToStr(Value));
end;

function THexFieldGUID.GetDisplayName: string;
begin
  result:='GUID';
end;

function THexFieldGUID.GetValue:TGUID;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldGUID.SetValue(const NewValue:TGUID);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;
{$ENDIF}

//##########################################################################
// THexFieldDateTime
//##########################################################################

function THexFieldDateTime.asstring: string;
begin
  result:=DateTimeToStr(Value);
end;

function THexFieldDateTime.GetDisplayName: string;
begin
  result:='DateTime';
end;

function THexFieldDateTime.GetValue:TDateTime;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldDateTime.SetValue(const NewValue:TDateTime);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldDouble
//##########################################################################

function THexFieldDouble.AsString: string;
begin
  result:=FloatToStr(Value);
end;

function THexFieldDouble.GetDisplayName: string;
begin
  result:='Double';
end;

function THexFieldDouble.GetValue:Double;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RecordField_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldDouble.SetValue(const NewValue:Double);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldData
//##########################################################################

function THexFieldData.asstring: string;
begin
  result:='[Binary]';
end;

function THexFieldData.GetDisplayName: string;
begin
  result:='Binary';
end;

//##########################################################################
// THexFieldCurrency
//##########################################################################

function THexFieldCurrency.asstring: string;
begin
  result:=CurrToStr(Value);
end;

function THexFieldCurrency.GetDisplayName: string;
begin
  result:='Currency';
end;

function THexFieldCurrency.GetValue:Currency;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldCurrency.SetValue(const NewValue:Currency);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldbyte
//##########################################################################

function THexFieldbyte.asstring: string;
begin
  result:=IntToStr(Value);
end;

function THexFieldbyte.GetDisplayName: string;
begin
  result:='byte';
end;

function THexFieldbyte.GetValue:byte;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldbyte.SetValue(const NewValue:byte);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldboolean
//##########################################################################

function THexFieldboolean.asstring: string;
begin
  result:=BoolToStr(Value,True);
end;

function THexFieldboolean.GetDisplayName: string;
begin
  result:='boolean';
end;

function THexFieldboolean.GetValue: boolean;
begin
  if not Empty then
  begin
    if Read(0,SizeOf(result),result)<SizeOf(result) then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  if not (csDesigning in ComponentState) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FieldIsEmpty,[FieldName]);
end;

procedure THexFieldboolean.SetValue(const NewValue: boolean);
begin
  if Write(0,SizeOf(NewValue),NewValue)<SizeOf(NewValue) then
  raise EHexRecordFieldError.CreateFmt
  (ERR_RECORDFIELD_FailedSet,[FieldName]) else
  SignalWrite;
end;

//##########################################################################
// THexFieldString
//##########################################################################

constructor THexFieldString.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLength:=0;
  FExplicit:=False;
end;

function THexFieldString.asstring: string;
begin
  result:=Value;
end;

function THexFieldString.GetDisplayName: string;
begin
  result:='string';
end;

procedure THexFieldString.SetFieldLength(Value:integer);
begin
  if  FExplicit
  and (Value<>FLength) then
  begin
    Value:=EnsureRange(Value,0,MAXINT-1);
    if Value>0 then
    begin
      FLength:=Value;
      if FLength<>Size then
      Size:=FLength;
    end else
    begin
      FLength:=0;
      Release;
    end;
  end;
end;

function THexFieldString.GetValue: string;
begin
  if not Empty then
  begin
    SetLength(result,Size div SizeOf(Char));
    if Read(0,Size,pointer(@result[1])^)<Size then
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_FailedGet,[FieldName]) else
    SignalRead;
  end else
  result:='';
end;

procedure THexFieldString.SetValue(NewValue: string);
var
  FLen: integer;
begin
  FLen:=system.Length(NewValue);
  if FLen>0 then
  begin
    (* cut string to length if explicit *)
    if FExplicit then
    begin
      if FLen>FLength then
      FLen:=FLength;
    end;
    Size:=FLen * SizeOf(char);

    if FLen>0 then
    begin
      if Write(0,Size,NewValue[1])<Size then
      raise EHexRecordFieldError.CreateFmt
      (ERR_RECORDFIELD_FailedSet,[FieldName]) else
      SignalWrite;
    end else
    Release;

  end else
  Release;
end;

//##########################################################################
// THexRecordField
//##########################################################################

function THexRecordField.GetDisplayName: string;
begin
  result:='Unknown';
end;

procedure THexRecordField.SignalWrite;
begin
  if assigned(FOnWrite) then
    FOnWrite(self);
end;

procedure THexRecordField.SignalRead;
begin
  if assigned(FOnRead) then
    FOnRead(self);
end;

procedure THexRecordField.SignalRelease;
begin
  if assigned(FOnRelease) then
    FOnRelease(self);
end;

procedure THexRecordField.SetRecordName(NewName: string);
begin
  NewName := trim(NewName);
  if NewName <> FName then
  begin
    if system.Length(NewName)>0 then
    begin
      FName := NewName;
      FNameHash := ElfHash(LowerCase(NewName))
    end else
    raise EHexRecordFieldError.CreateFmt
    (ERR_RECORDFIELD_INVALIDNAME,[NewName]);
  end;
end;

procedure THexRecordField.BeforeReadObject;
begin
  inherited;
  FName:='';
  FNameHash:=0;
end;

procedure THexRecordField.ReadObject(Reader:TReader);
begin
  inherited;
  FNameHash:=Reader.ReadInt64;
  FName:=Reader.Readstring;
end;

procedure THexRecordField.WriteObject(Writer:TWriter);
begin
  inherited;
  Writer.Writeinteger(FNameHash);
  Writer.Writestring(FName);
end;

procedure THexRecordField.DoReleaseData;
begin
  inherited;
  SignalRelease;
end;

//##########################################################################
// THexSize
//##########################################################################

class function THexSize.Kilobyte: NativeInt;
begin
  result := 1024;
end;

class function THexSize.Megabyte: NativeInt;
begin
  result := 1048576;
end;

class function THexSize.Gigabyte: NativeInt;
begin
  result := 1073741824;
end;

{$IFNDEF NO_UINT64}
class function THexSize.Terabyte: UInt64;
begin
  result := 1000 * Gigabyte;
end;
{$ENDIF}

class function THexSize.KilobytesIn(byteCount: int64;
    const Aligned: boolean = true):  NativeInt;
begin
  result := byteCount div Kilobyte;
  if Aligned then
  begin
    if result * Kilobyte < byteCount then
      inc(result);
  end;
end;

class function THexSize.MegabytesIn(byteCount: int64;
    const Aligned: boolean = true):  NativeInt;
begin
  result := byteCount div Megabyte;
  if Aligned then
  begin
    if result * Megabyte < byteCount then
      inc(result);
  end;
end;

class function THexSize.GigabytesIn(byteCount: int64;
  const Aligned: boolean = true):  NativeInt;
begin
  result := byteCount div Gigabyte;
  if Aligned then
  begin
    if result * Gigabyte < byteCount then
      inc(result);
  end;
end;

{$IFNDEF NO_UINT64}
class function THexSize.TerabytesIn(byteCount: UInt64;
  const Aligned: boolean = true):  NativeInt;
begin
  result := byteCount div Terabyte;
  if Aligned then
  begin
    {$WARNINGS OFF}
    if (result * Terabyte) < byteCount then
      inc(result);
    {$WARNINGS ON}
  end;
end;
{$ENDIF}

class function THexSize.KilobytesOf(Amount: NativeInt):  int64;
begin
  result := abs(Amount) * Kilobyte;
end;

class function THexSize.MegabytesOf(Amount: NativeInt):  int64;
begin
  result := abs(Amount) * Megabyte;
end;

class function THexSize.GigabytesOf(Amount: NativeInt):  int64;
begin
  result := abs(Amount) * Gigabyte;
end;

{$IFNDEF NO_UINT64}
class function THexSize.TerabytesOf(Amount: NativeInt;
    const Aligned: boolean = true):  UInt64;
begin
  {$WARNINGS OFF}
  result := abs(Amount) * Terabyte;
  {$WARNINGS ON}
end;
{$ENDIF}

class function THexSize.AsString(const SizeInbytes: int64):  string;
var
  A1, A2, A3: double;
begin
  A1 := SizeInbytes / 1024;
  A2 := A1 / 1024;
  A3 := A2 / 1024;
  if A1 < 1 then
  result := floattostrf(SizeInbytes, ffNumber, 15, 0) + ' bytes' else
  if A1 < 10 then result := floattostrf(A1, ffNumber, 15, 2) + ' KB' else
  if A1 < 100 then result := floattostrf(A1, ffNumber, 15, 1) + ' KB' else
  if A2 < 1 then result := floattostrf(A1, ffNumber, 15, 0) + ' KB' else
  if A2 < 10 then result := floattostrf(A2, ffNumber, 15, 2) + ' MB' else
  if A2 < 100 then result := floattostrf(A2, ffNumber, 15, 1) + ' MB' else
  if A3 < 1 then result := floattostrf(A2, ffNumber, 15, 0) + ' MB' else
  if A3 < 10 then result := floattostrf(A3, ffNumber, 15, 2) + ' GB' else
  if A3 < 100 then result := floattostrf(A3, ffNumber, 15, 1) + ' GB' else
  result := floattostrf(A3, ffNumber, 15, 0) + ' GB';
  result := result + ' (' + floattostrf(SizeInbytes, ffNumber, 15, 0) + ' bytes)';
end;

//##########################################################################
// THexPersistent
//##########################################################################

constructor THexPersistent.Create;
begin
  inherited;
  FObjId:=classIdentifier;
end;

function THexPersistent.ObjectHasData: boolean;
begin
  result:=False;
end;

procedure THexPersistent.DefineProperties(Filer: TFiler);
begin
  inherited;
  filer.DefineBinaryproperty('$RES',ReadObjBin,WriteObjBin,ObjectHasData);
end;

procedure THexPersistent.ReadObjBin(Stream: TStream);
var
  mReader:  THexReaderStream;
begin
  mReader:=THexReaderStream.Create(Stream);
  try
    ObjectFrom(mReader);
  finally
    mReader.Free;
  end;
end;

procedure THexPersistent.WriteObjBin(Stream: TStream);
var
  mWriter:  THexWriterStream;
begin
  mWriter:=THexWriterStream.Create(Stream);
  try
    ObjectTo(mWriter);
  finally
    mWriter.Free;
  end;
end;

function THexPersistent.ObjectIdentifier:Longword;
begin
  result:=FObjId;
end;

class function THexPersistent.classIdentifier:Longword;
begin
  result:=THexBuffer.ElfHash(ObjectPath);
end;

(* ISRLPersistent: ObjectToStream *)
procedure THexPersistent.ObjectToStream(const Stream: TStream);
var
  FWriter: THexWriterStream;
begin
  FWriter:=THexWriterStream.Create(Stream);
  try
    ObjectTo(FWriter);
  finally
    FWriter.free;
  end;
end;

(* ISRLPersistent: ObjectToBinary *)
procedure THexPersistent.ObjectToData(const Binary:THexBuffer);
var
  FWriter: THexWriterBuffer;
begin
  FWriter:=THexWriterBuffer.Create(Binary);
  try
    ObjectTo(FWriter);
  finally
    FWriter.free;
  end;
end;

(* ISRLPersistent: ObjectToBinary *)
function THexPersistent.ObjectToData:THexBuffer;
begin
  Result:=THexBufferMemory.Create(nil);
  try
    ObjectToData(Result);
  except
    on e: exception do
    begin
      FreeAndNil(Result);
      raise EHexPersistent.Create(e.Message);
    end;
  end;
end;

(* ISRLPersistent: ObjectToStream *)
function THexPersistent.ObjectToStream: TStream;
begin
  Result:=TMemoryStream.Create;
  try
    ObjectToStream(Result);
    Result.Position:=0;
  except
    on e: exception do
    begin
      FreeAndNil(Result);
      raise EHexPersistent.Create(e.message);
    end;
  end;
end;

procedure THexPersistent.ObjectFrom(const Reader:THexReader);
begin
  If Reader<>NIL then
  begin
    If beginUpdate then
    begin
      BeforeReadObject;
      ReadObject(Reader);
      AfterReadObject;
      EndUpdate;
    end;
  end else
  raise EHexPersistent.Create(ERR_HEX_PERSISTENCY_INVALIDREADER);
end;

procedure THexPersistent.ObjectTo(const Writer:THexWriter);
begin
  If Writer<>NIl then
  begin
    BeforeWriteObject;
    WriteObject(Writer);
    AfterWriteObject;
  end else
  raise EHexPersistent.Create(ERR_HEX_PERSISTENCY_INVALIDWRITER);
end;

(* ISRLPersistent: ObjectFromBinary *)
procedure THexPersistent.ObjectFromData
          (const Binary:THexBuffer;const Disposable: boolean);
var
  FReader: THexReaderBuffer;
begin
  FReader:=THexReaderBuffer.Create(Binary);
  try
    ObjectFrom(FReader);
  finally
    FReader.free;
    If Disposable then
    Binary.free;
  end;
end;

procedure THexPersistent.Assign(Source: TPersistent);
begin
  If Source<>NIL then
  begin
    if (source is THexPersistent) then
    begin
      (* Always supports object of same class *)
      if IHexObject(THexPersistent(Source)).GetObjectclass() = GetObjectclass then
      begin
        If Source<>Self then
        ObjectFromData(THexPersistent(Source).ObjectToData,True);
      end else
      (* no support, raise exception *)
      raise EHexPersistent.CreateFmt
      (ERR_HEX_PERSISTENCY_ASSIGNCONFLICT,
      [THexPersistent(Source).ObjectPath,ObjectPath]);
    end;
  end;
end;

procedure THexPersistent.BeforeWriteObject;
begin
  AddObjectState([osReadWrite]);
end;

procedure THexPersistent.BeforeReadObject;
begin
  AddObjectState([osReadWrite]);
end;

procedure THexPersistent.AfterReadObject;
begin
  RemoveObjectState([osReadWrite]);
end;

procedure THexPersistent.AfterWriteObject;
begin
  RemoveObjectState([osReadWrite]);
end;

procedure THexPersistent.WriteObject(const Writer: THexWriter);
begin
  (* write identifier to stream *)
  Writer.WriteLong(FObjId);
end;

procedure THexPersistent.ReadObject(const Reader: THexReader);
var
  FReadId:  Longword;
begin
  (* read identifier from stream *)
  FReadId:=Reader.ReadLong;

  If FReadId<>FObjId then
  raise EHexPersistent.CreateFmt
  (ERR_HEX_PERSISTENCY_INVALIDSIGNATURE,
  [IntToHex(FReadId,8),IntToHex(FObjId,8)]);
end;

(* ISRLPersistent: ObjectFromStream *)
procedure THexPersistent.ObjectFromStream
          (const Stream: TStream; const Disposable: boolean);
var
  FReader:  THexReaderStream;
begin
  FReader:=THexReaderStream.Create(Stream);
  try
    ObjectFrom(FReader);
  finally
    FReader.free;
    If Disposable then
    Stream.free;
  end;
end;

(* ISRLPersistent: ObjectfromFile *)
procedure THexPersistent.ObjectfromFile(const Filename: string);
begin
  ObjectFromStream(TFileStream.Create(filename,
  fmOpenRead or fmShareDenyWrite),True);
end;

(* ISRLPersistent: ObjectToFile *)
procedure THexPersistent.ObjectToFile(const Filename: string);
var
  FFile:  TFileStream;
begin
  FFile:=TFileStream.Create(filename,fmCreate);
  try
    ObjectToStream(FFile);
  finally
    FFile.free;
  end;
end;

procedure THexPersistent.BeforeUpdate;
begin
end;

procedure THexPersistent.AfterUpdate;
begin
end;

function THexPersistent.beginUpdate: boolean;
begin
  result:=QueryObjectState([osDestroying])=False;
  if result then
  begin
    inc(FUpdCount);
    If FUpdCount=1 then
    begin
      AddObjectState([osUpdating]);
      BeforeUpdate;
    end;
  end;
end;

procedure THexPersistent.EndUpdate;
begin
  If QueryObjectState([osUpdating]) then
  begin
    dec(FUpdCount);
    If FUpdCount<1 then
    begin
      RemoveObjectState([osUpdating]);
      AfterUpdate;
    end;
  end;
end;

//##########################################################################
// THexObject
//##########################################################################

constructor THexObject.Create;
begin
  inherited;
  FState:=[osCreating];
end;

procedure THexObject.Afterconstruction;
begin
  inherited;
  FState := FState - [osCreating];
end;

procedure THexObject.BeforeDestruction;
begin
  FState := FState + [osDestroying];
  inherited;
end;

function THexObject.GetObjectclass:THexObjectclass;
begin
  result := THexObjectclass(classType);
end;

class function THexObject.ObjectPath: string;
var
  LAncestor:  Tclass;
begin
  SetLength(result,0);
  LAncestor := ClassParent;
  while (LAncestor <> NIL) do
  begin
    If Length(result)>0 then
    result := (LAncestor.ClassName + '.' + result) else
    result := LAncestor.ClassName;
    LAncestor := LAncestor.classParent;
  end;
  If Length(result)>0 then
  result := result + '.' + ClassName else
  result := ClassName;
end;

function THexObject.GetParent:TObject;
begin
  result := FParent;
end;

procedure THexObject.SetParent(const Value:TObject);
begin
  FParent := Value;
end;

function THexObject.GetObjectState:THexObjectState;
begin
  result := FState;
end;

procedure THexObject.AddObjectState(const Value: THexObjectState);
begin
  FState:=FState + Value;
end;

procedure THexObject.RemoveObjectState(const Value: THexObjectState);
begin
  FState:=FState - Value;
end;

procedure THexObject.SetObjectState(const Value: THexObjectState);
begin
  FState:=Value;
end;

function THexObject.QueryObjectState(const Value: THexObjectState):  boolean;
begin
  If (osCreating in Value) then
  Result:=(osCreating in FState) else
  Result:=False;

  If (Result=False) and (osDestroying in Value) then
  begin
    If (osDestroying in FState) then
    Result:=True;
  end;

  If (Result=False) and (osUpdating in Value) then
  begin
    if (osUpdating in FState) then
    Result:=True;
  end;

  If (Result=False) and (osReadWrite in Value) then
  begin
    if (osReadWrite in FState) then
    Result:=True;
  end;

  If (Result=False) and (osSilent in Value) then
  Result:=(osSilent in FState);
end;

function THexObject.QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
begin
  If GetInterface(IID,Obj) then
  Result:=S_OK else
  Result:=E_NOINTERFACE;
end;

function THexObject._AddRef: integer; stdcall;
begin
  (* Inform COM that no reference counting is required *)
  Result:=-1;
end;

function THexObject._Release: integer; stdcall;
begin
  (* Inform COM that no reference counting is required *)
  Result:=-1;
end;

procedure InitializeFramework;
begin
  HexRegisterRecordField(THexFieldboolean);
  HexRegisterRecordField(THexFieldbyte);
  HexRegisterRecordField(THexFieldCurrency);
  HexRegisterRecordField(THexFieldData);
  HexRegisterRecordField(THexFieldDateTime);
  HexRegisterRecordField(THexFieldDouble);
  HexRegisterRecordField(THexFieldGUID);
  HexRegisterRecordField(THexFieldInt64);
  HexRegisterRecordField(THexFieldInteger);
  HexRegisterRecordField(THexFieldLong);
  HexRegisterRecordField(THexFieldString);
end;

procedure FinalizeFramwork;
begin
  (* We only store class-types in this array, no instances,
     so we can just clear it for brewity - nothing to release *)
  SetLength(_Fieldclasses,0);
end;


initialization
begin
  InitializeFramework();
end;

finalization
begin
  FinalizeFramwork();
end;

end.
