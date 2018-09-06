unit hex.partition;

interface

uses
  system.types,
  hex.types,
  hex.modulators;

type

  THexGateArray = Array of byte;

  THexIronwoodPartition = class(TObject)
  private
    FFormula:   THexNumberModulator;
    FGates:     THexGateArray;
    FRange:     THexRange;
    FGateTotal: integer;
  protected
    function    GetGate(const Index: integer): byte;
    procedure   SetGate(const Index: integer; const Value: byte);
  public
    property    Modulator: THexNumberModulator read FFormula write FFormula;
    property    Gates[const Index: integer]: byte read GetGate write SetGate;
    property    GateCount: integer read (FGates.Count);
    property    Range: THexRange read FRange;

    function    ToString: string;
    function    ToArray: TByteArray;

    function    Valid(const Data: byte): boolean;
    procedure   Build(const RootKeyValue: byte);
    constructor Create(const PartitionGateCount: integer);virtual;
    destructor Destroy;override;
  end;

  THexIronwoodPartitions = array of THexIronwoodPartition;

implementation


//############################################################################
// THexIronwoodPartition
//############################################################################

constructor THexIronwoodPartition.Create(const PartitionGateCount: integer);
begin
  inherited create;
  FRange := THexRange.Create(0,255);

  // 64 is the optimal number of gates per partition, but we allow for
  // a minimal of 16 gates to be used - and a maximum of 128.
  // This means that half of the combinations [0..255] are invalid to
  // begin with, so this makes it much harder to figure out the non-linear
  // gate-numbers a partition contains
  FGateTotal := TInteger.EnsureRange(PartitionGateCount, 16, 128); //64;
end;

destructor THexIronwoodPartition.Destroy;
begin
  FRange.free;
  inherited;
end;

function THexIronwoodPartition.ToArray: TByteArray;
var
  LItem: byte;
begin
  for LItem in FGates do
  result.add(LItem);
end;

function THexIronwoodPartition.Valid(const Data: byte): boolean;
begin
  if FGates.Count>0 then
  result := FGates.IndexOf(Data) >= 0 else
  result := false;
end;

function THexIronwoodPartition.GetGate(const Index: integer): byte;
begin
  result := FGates[index]
end;

procedure THexIronwoodPartition.SetGate(const Index: integer; const Value: byte);
begin
  FGates[index] := value;
end;

function THexIronwoodPartition.ToString: string;
begin
  for var x:=low(FGates) to high(FGates) do
  begin
    if x<high(FGates) then
    result += FGates[x].ToHexString(2).UpperCase() + '-' else
    result += FGates[x].ToHexString(2).UpperCase();
  end;
end;

procedure THexIronwoodPartition.Build(const RootKeyValue: integer);
var
  x:  integer;
  LValue: integer;
begin
  FGates.clear;
  if FFormula <> nil then
  begin
    x:=1;
    while (FGates.Count < FGateTotal) do
    begin
      LValue :=  (RootKeyValue + FFormula.Data[x] -x) mod FRange.Top;
      if FGates.IndexOf(LValue)<0 then
      begin
        FGates.Push(LValue);
      end;
      inc(x);
      if x>255 then
      x:=1;
    end;
  end;
end;


end.
