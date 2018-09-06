unit FMX.HexCodecs;

interface

{$I 'FMX.hexlicense.inc'}

uses
{$IFDEF VCL_TARGET}
  {$IFNDEF USE_NEW_UNITNAMES}
  SysUtils, Classes, FMX.hexbuffers;
  {$ELSE}
  System.SysUtils, System.Classes;
  {$ENDIF}
{$ENDIF}

{$IFDEF FMX_TARGET}
  System.SysUtils, System.Classes, FMX.hexbuffers;
{$ENDIF}

type

//###########################################################################
// Exception classes
//###########################################################################

  EHexCodec = class(exception);
  EHexCodecNoImplementation = class(EHexCodec);

//###########################################################################
// Interface declarations
//###########################################################################

  IHexCodec = interface
  ['{349C3DD6-3D6A-4732-9903-523A69E35595}']
    function  QueryCodecIdentifier: string;
    function  QueryCodecInfo: string;
  end;

  IHexStreamCodec = interface
  ['{72759634-A3D3-4F8C-815A-4466AA6D7FF7}']
    procedure StreamEncode(const FromStream: TStream; const ToStream: TStream);
    procedure StreamDecode(const FromStream: TStream; const ToStream: TStream);
  end;

  IHexTextCodec = interface
  ['{F5337481-0124-48D6-8F75-4EA1D5024D78}']
    function TextEncode(PlainText: string): string;
    function TextDecode(EncodedText: string): string;
  end;

  IHexMemoryCodec = interface
  ['{553C4D67-ABBC-4CA7-932D-B0F3D4F63CA1}']
    function MemoryEncode(const PlainData: TBRBuffer): TBRBuffer;
    function MemoryDecode(const EncodedData: TBRBuffer): TBRBuffer;
  end;

  IHexCodecGematriaMatrix = interface
    ['{384BFE33-65B7-4A80-B1C7-1357EEA0A91C}']
    procedure SetupMatrix(Size:Integer; const Data: Array of Integer);
    procedure BurnMatrix;
  end;

//###########################################################################
// Codec baseclass
//###########################################################################

  THexCodec = class(TComponent, IHexCodec)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; virtual;
    function QueryCodecInfo: string; virtual;
  end;

//###########################################################################
// Standard text based codecs
//###########################################################################

  THexCodecURL = class(THexCodec, IHexStreamCodec, IHexTextCodec)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  private
    FReserved: Array of char;
    procedure SetupReservedDictionary;
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexStreamCodec
    procedure StreamEncode(const FromStream: TStream; const ToStream: TStream);
    procedure StreamDecode(const FromStream: TStream; const ToStream: TStream);

    // IHexTextCodec
    function TextEncode(PlainText: string): string;
    function TextDecode(EncodedText: string): string;
  public
    constructor Create(AOwner: TComponent);override;
  end;

  THexCodecBase64 = class(THexCodec, IHexStreamCodec, IHexTextCodec)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  private
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexStreamCodec
    procedure StreamEncode(const FromStream: TStream; const ToStream: TStream);
    procedure StreamDecode(const FromStream: TStream; const ToStream: TStream);

    // IHexTextCodec
    function TextEncode(PlainText: string): string;
    function TextDecode(EncodedText: string): string;
  public
    constructor Create(AOwner: TComponent);override;
  end;

  THexCodecMime = class(THexCodec, IHexStreamCodec, IHexTextCodec)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  private
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexStreamCodec
    procedure StreamEncode(const FromStream: TStream; const ToStream: TStream);
    procedure StreamDecode(const FromStream: TStream; const ToStream: TStream);

    // IHexTextCodec
    function TextEncode(PlainText: string): string;
    function TextDecode(EncodedText: string): string;
  public
    constructor Create(AOwner: TComponent);override;
  end;

//###########################################################################
// Gematria based cipher codecs
//###########################################################################

  // Most gematria ciphers uses a fixed table of substitutes
  // where one letter is replaced by another [or a glyph with a value]
  THexCodecGematriaMatrix = class(TComponent, IHexCodecGematriaMatrix)
  private
    FCache: Array of integer;
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    procedure SetupMatrix(Size:Integer; const Data: Array of Integer);virtual;
    procedure BurnMatrix;virtual;
  end;

  THexCodecGematria = class(THexCodec, IHexTextCodec)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  private
    FMatrix:  THexCodecGematriaMatrix;
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    procedure SetMatrix(NewMatrix: THexCodecGematriaMatrix);virtual;
    function  GetMatrix: THexCodecGematriaMatrix;virtual;

    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; virtual; abstract;
    function TextDecode(EncodedText: string): string; virtual; abstract;
  end;

  THexCodecGematriaSepsephos = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;

  THexCodecGematriaHebrew = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;

  THexCodecGematriaBeatus = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;

  THexCodecGematriaLatin = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;

  THexCodecGematriaAmun = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;

  THexCodecCecarShift = class(THexCodecGematria)
  {$IFDEF SUPPORT_STRICT}strict{$ENDIF}
  protected
    function QueryCodecIdentifier: string; override;
    function QueryCodecInfo: string; override;

    // IHexTextCodec
    function TextEncode(PlainText: string): string; override;
    function TextDecode(EncodedText: string): string; override;
  end;


implementation

uses REST.Utils;

//#############################################################################
// THexCodecCecarShift
//#############################################################################

function THexCodecCecarShift.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:caecar';
end;

function THexCodecCecarShift.QueryCodecInfo: string;
begin
  result := 'This codec implements the roman caecar shift cipher ' + #13
    + ' [https://en.wikipedia.org/wiki/Caesar_cipher]';
end;

function THexCodecCecarShift.TextEncode(PlainText: string): string;
begin
end;

function THexCodecCecarShift.TextDecode(EncodedText: string): string;
begin
end;


//#############################################################################
// THexCodecGematriaAmun
//#############################################################################

function THexCodecGematriaAmun.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:amun';
end;

function THexCodecGematriaAmun.QueryCodecInfo: string;
begin
  result := 'This codec implements the egyptian amun gematria cipher';
end;

function THexCodecGematriaAmun.TextEncode(PlainText: string): string;
begin
end;

function THexCodecGematriaAmun.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecGematriaLatin
//#############################################################################

function THexCodecGematriaLatin.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:latin';
end;

function THexCodecGematriaLatin.QueryCodecInfo: string;
begin
  result := 'This codec implements the latin standard gematria cipher';
end;

function THexCodecGematriaLatin.TextEncode(PlainText: string): string;
begin
end;

function THexCodecGematriaLatin.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecGematriaBeatus
//#############################################################################

function THexCodecGematriaBeatus.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:beatus';
end;

function THexCodecGematriaBeatus.QueryCodecInfo: string;
begin
  result := 'This codec implements the beatus gematria cipher';
end;

function THexCodecGematriaBeatus.TextEncode(PlainText: string): string;
begin
end;

function THexCodecGematriaBeatus.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecGematriaHebrew
//#############################################################################

function THexCodecGematriaHebrew.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:hebrew';
end;

function THexCodecGematriaHebrew.QueryCodecInfo: string;
begin
  result := 'This codec implements the hebrew gematria cipher';
end;

function THexCodecGematriaHebrew.TextEncode(PlainText: string): string;
begin
end;

function THexCodecGematriaHebrew.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecGematriaSepsephos
//#############################################################################

function THexCodecGematriaSepsephos.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:sepsephos';
end;

function THexCodecGematriaSepsephos.QueryCodecInfo: string;
begin
  result := 'This codec implements the sepsephos greek gematria cipher';
end;

function THexCodecGematriaSepsephos.TextEncode(PlainText: string): string;
begin
end;

function THexCodecGematriaSepsephos.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecGematria
//#############################################################################

procedure THexCodecGematriaMatrix.SetupMatrix(Size:Integer;
  const Data: Array of Integer);
var
  x:  integer;
begin
  SetLength(FCache, Size);
  for x:=1 to Size do
  FCache[x-1] := Data[x-1];
end;

procedure THexCodecGematriaMatrix.BurnMatrix;
var
  x: integer;
  LLen: integer;
begin
  LLen := length(FCache);
  if LLen>0 then
  begin
    try
      for x:=1 to LLen do
      begin
        FCache[x-1] := 0;
      end;
    finally
      SetLength(FCache,0);
    end;
  end;
end;

//#############################################################################
// THexCodecGematria
//#############################################################################

function THexCodecGematria.QueryCodecIdentifier: string;
begin
  result := 'codec:gematria:*';
end;

function THexCodecGematria.QueryCodecInfo: string;
begin
  result := 'This codec is a baseclass for various gematria implementations.'
    + ' Do not create instances of this class';
end;

procedure THexCodecGematria.SetMatrix(NewMatrix: THexCodecGematriaMatrix);
begin
  if NewMatrix <> FMatrix then
  begin
    if FMatrix<>nil then
    begin
      FMatrix.RemoveFreeNotification(self);
      FMatrix := nil;
    end;

    if NewMatrix<> nil then
    begin
      FMatrix := NewMatrix;
      FMatrix.FreeNotification(self);
    end;

  end;

  FMatrix := NewMatrix;
end;

function THexCodecGematria.GetMatrix: THexCodecGematriaMatrix;
begin
  result := FMatrix;
end;

//#############################################################################
// THexCodecMime
//#############################################################################

constructor THexCodecMime.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function THexCodecMime.QueryCodecIdentifier: string;
begin
  result := 'codec:text:mime';
end;

function THexCodecMime.QueryCodecInfo: string;
begin
  result := 'Codec implements Mime encoding/decoding [rfc 2045]';
end;

procedure THexCodecMime.StreamEncode(const FromStream: TStream; const ToStream: TStream);
begin
end;

procedure THexCodecMime.StreamDecode(const FromStream: TStream; const ToStream: TStream);
begin
end;

function THexCodecMime.TextEncode(PlainText: string): string;
begin
end;

function THexCodecMime.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodecBase64
//#############################################################################

constructor THexCodecBase64.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

function THexCodecBase64.QueryCodecIdentifier: string;
begin
  result := 'codec:text:base64';
end;

function THexCodecBase64.QueryCodecInfo: string;
begin
  result := 'Codec implements Base64 encoding/decoding [rfc 4648]';
end;

procedure THexCodecBase64.StreamEncode(const FromStream: TStream; const ToStream: TStream);
begin
end;

procedure THexCodecBase64.StreamDecode(const FromStream: TStream; const ToStream: TStream);
begin
end;

function THexCodecBase64.TextEncode(PlainText: string): string;
begin
end;

function THexCodecBase64.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexURLCodec
//#############################################################################

constructor THexCodecURL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetupReservedDictionary;
end;

procedure THexCodecURL.SetupReservedDictionary;
const
  URL_RESERVE_DICTIONARY =
    [ 'A' .. 'Z',
      'a' .. 'z',
      '0' .. '9',
      '-',
      '_',
      '.',
      '~'
    ];
var
  c: Char;
  i: integer;
begin
  SetLength(FReserved, 1024);
  i := 0;
  for c in URL_RESERVE_DICTIONARY do
  begin
    inc(i);
    FReserved[i] := c;
  end;
  SetLength(FReserved, i);
end;

function THexCodecURL.QueryCodecIdentifier: string;
begin
  result := 'codec:text:url';
end;

function THexCodecURL.QueryCodecInfo: string;
begin
  result := 'Codec implements URL encoding/decoding [rfc 3986]';
end;

procedure THexCodecURL.StreamEncode(const FromStream: TStream; const ToStream: TStream);
begin
end;

procedure THexCodecURL.StreamDecode(const FromStream: TStream; const ToStream: TStream);
begin
end;

function THexCodecURL.TextEncode(PlainText: string): string;
begin
end;

function THexCodecURL.TextDecode(EncodedText: string): string;
begin
end;

//#############################################################################
// THexCodec
//#############################################################################

function THexCodec.QueryCodecIdentifier: string;
begin
  result := 'codec:*';
end;

function THexCodec.QueryCodecInfo: string;
begin
  result := 'Codec baseclass. Do not create instances of this class';
end;

end.
