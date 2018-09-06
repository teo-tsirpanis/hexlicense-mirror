unit hex.serialnumber;

interface

uses
  system.types,
  hex.types,
  hex.partition,
  hex.obfuscation,
  hex.serialmatrix,
  hex.modulators;

type


  THexCustomSerialNumber = class(TObject)
  public
    function Validate(SerialNumber: string): boolean;virtual;abstract;
  end;

  THexIronWoodSerialNumber = class(THexCustomSerialNumber)
  private
    FGateCount: integer;
    FRootData: THexKeyMatrix;
    FModulator: THexNumberModulator;
    FObfuscator: THexObfuscation;
    FPartitions: THexIronwoodPartitions;
  protected
    function CanUseRootData: boolean;
    procedure SetGateCount(const Value: integer);virtual;
    procedure RebuildPartitionTable;
  public
    property Modulator: THexNumberModulator read FModulator write FModulator;
    property Obfuscaton: THexObfuscation read FObfuscator write FObfuscator;
    property Partitions: THexIronwoodPartitions read FPartitions;
    procedure Build(const Rootkey: THexKeyMatrix);
    function GetSignature: string;

    function Validate(SerialNumber: string): boolean;override;

    constructor Create;virtual;
    destructor  Destroy;override;
  end;

implementation

//############################################################################
// THexIronWoodSerialNumber
//############################################################################

constructor THexIronWoodSerialNumber.Create;
begin
  inherited create;

  for var LItem in FRootData do
  begin
    LItem := 0;
  end;

  // Out of 256 gates, we allow 64 to be actually used
  FGateCount := 64;

  // We have 12 partitions, each with 64 valid gates [out of 256]
  //RebuildPartitionTable;
end;

destructor THexIronWoodSerialNumber.Destroy;
begin
  try
    for var x:=low(FPartitions) to high(FPartitions) do
    begin
      FPartitions[x].free;
      FPartitions[x] := nil;
    end;
  finally
    FPartitions.clear;
  end;
  inherited;
end;

function THexIronWoodSerialNumber.CanUseRootData: boolean;
var
  LFilled: integer;
  LTop: integer;
begin
  LFilled := 0;
  LTop := length(FRootData);
  for var x:=low(FRootData) to high(FRootData) do
  begin
    if FRootData[x] <> 0 then
    inc(LFilled);
  end;

  //writeln("Filled:" + LFilled.ToString() );
  //writeln("Top:" + LTop.ToString() );

  // No more than 2 slots can have zero.
  result := ( LFilled >= (LTop-2) );
end;

procedure THexIronWoodSerialNumber.SetGateCount(const Value: integer);
begin
  FGateCount := TInteger.EnsureRange(Value, 16, 128);
end;

procedure THexIronWoodSerialNumber.RebuildPartitionTable;
var
  LPartition: THexIronwoodPartition;
begin
  FPartitions.Clear;
  if CanUseRootData then
  begin
    for var x:=1 to 12 do
    begin
      LPartition := THexIronwoodPartition.Create(FGateCount);
      LPartition.Modulator := Modulator;
      FPartitions.Add(LPartition);

      // Only issue a rebuild if a modulator has been assigned
      if (Modulator <> nil) then
      begin
        // Rebuild gate array
        LPartition.Build( FRootData[x-1] );
      end else
      raise Exception.Create('No modulator assigned, failed to rebuild partition table error');
    end;
  end else
  raise Exception.Create('Unsuitable root-key, failed to rebuild partition table error');
end;

procedure THexIronWoodSerialNumber.Build(const Rootkey: THexKeyMatrix);
begin
  FRootData := Rootkey;
  RebuildPartitionTable;
end;

function THexIronWoodSerialNumber.GetSignature: string;
begin
  if FPartitions.Count>0 then
  begin
    for var x:=low(FPartitions) to high(FPartitions) do
    begin
      if x<high(FPartitions) then
      result += FPartitions[x].ToString + #13 else
      result += FPartitions[x].ToString;
    end;
  end;
end;

function THexIronWoodSerialNumber.Validate(SerialNumber: string): boolean;
var
  x: integer;
  LBlock: string;
  LVector: integer;
  LRaw: byte;
  LLock: integer;
begin
  result := false;
  serialnumber := StrReplace(Serialnumber,'-','');
  if length(serialnumber) = FPartitions.length * 2 then
  begin
    x:=1;
    LVector := 0;
    LLock := 0;
    repeat
      LBlock := '$' + copy(Serialnumber,1,2);
      delete(serialnumber,1,2);
      inc(x,2);

      LRaw := TInteger.EnsureRange( StrToInt(LBlock),0 ,255);

      if FPartitions[LVector].Valid(LRaw) then
      inc(LLock);
    until x > length(serialnumber);

    result := LLock = FPartitions.Length;
  end;
end;


end.
