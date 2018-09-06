unit hex.ironwood;

interface

uses 
  system.types,
  hex.types,
  hex.modulators,
  hex.serialmatrix,
  hex.serialnumber,
  hex.partition;

type

  THexSerialGenerateMethod = (
    gmDispersed = $1200,
    gmCanonical = $12AF
    );

  THexMintSerialNumberReadyEvent = procedure(sender: TObject;
    SerialNumber: string; var Accept: boolean);
  THexMintBeforeEvent = procedure (sender: TObject);
  THexMintAfterEvent = procedure (sender: TObject);

  THexIronwoodGenerator = class(THexIronWoodSerialNumber)
  private
    FOnAcceptSerial: THexMintSerialNumberReadyEvent;
    FOnBeforeMint: THexMintBeforeEvent;
    FOnAfterMint: THexMintAfterEvent;
    FMethod:  THexSerialGenerateMethod;
  protected
    function  Deliver(SerialNumber: string): boolean;virtual;
    procedure DoDispersed(Count: integer);
    procedure DoCanonical(Count: integer);
  public
    procedure Mint(Count: integer);overload;virtual;
    procedure Mint(Count: integer;const MMethod: THexSerialGenerateMethod);overload;
    procedure Mint(Count: integer;const MMethod: THexSerialGenerateMethod;
      Handler: THexMintSerialNumberReadyEvent);overload;
  published
    property  MintMethod: THexSerialGenerateMethod read FMethod write FMethod;
    property  OnBeforeMining: THexMintBeforeEvent read FOnBeforeMint write FOnBeforeMint;
    property  OnAfterMinting: THexMintAfterEvent read FOnAfterMint write FOnAfterMint;
    property  OnAcceptSerialNumber: THexMintSerialNumberReadyEvent read FOnAcceptSerial write FOnAcceptSerial;
  end;

implementation

//############################################################################
// THexIronwoodGenerator
//############################################################################

function THexIronwoodGenerator.Deliver(SerialNumber: string): boolean;
begin
  result := false;
  if assigned(OnAcceptSerialNumber) then
  begin
    OnAcceptSerialNumber(self,Serialnumber, result);
  end;
end;

procedure THexIronwoodGenerator.Mint(Count: integer;
  const MMethod: THexSerialGenerateMethod);
begin
  var LOld := FMethod;
  try
    Mint(Count);
  finally
    FMethod := LOld;
  end;
end;

procedure THexIronwoodGenerator.Mint(Count: integer;
  const MMethod: THexSerialGenerateMethod;
  Handler: THexMintSerialNumberReadyEvent);
begin
  var LOld := @OnAcceptSerialNumber;
  OnAcceptSerialNumber := Handler;
  try
    Mint(Count,MMethod);
  finally
    OnAcceptSerialNumber := LOld;
  end;
end;

procedure THexIronwoodGenerator.DoDispersed(Count: integer);
var
  x:  integer;
  id: integer;
  LText:  string;
  LAtrophy: integer;
  LPartition: THexIronwoodPartition;
begin
  while Count>0 do
  begin
    LText := '';

    for x:=0 to Partitions.Count-1 do
    begin
      LPartition := Partitions[x];
      id := randomInt(LPartition.GateCount);
      LText += LPartition.Gates[id].ToHexString(2).ToUpper();
      if (x mod 4 = 3) and (x<Partitions.Count-1) then
        LText += '-';
    end;

    if Deliver(LText) then
    begin
      dec(count);
    end else
    begin
      inc(LAtrophy);
    end;

  end;
end;

procedure THexIronwoodGenerator.DoCanonical(Count: integer);
begin
end;

procedure THexIronwoodGenerator.Mint(Count: integer);
begin
  if assigned(OnBeforeMining) then
  OnBeforeMining(self);
  try
    case MintMethod of
    gmDispersed: DoDispersed(Count);
    gmCanonical: DoCanonical(Count);
    end;
  finally
    if assigned(OnAfterMinting) then
    OnAfterMinting(self);
  end;
end;


end.
