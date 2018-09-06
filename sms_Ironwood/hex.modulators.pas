unit hex.modulators;

interface

uses
  system.types;

type
  THexModulationTable = array [0..255] of integer;

  THexNumberModulator = class(TObject)
  private
    FCache:     THexModulationTable;
  protected
    function    BuildNumberSeries: THexModulationTable; virtual; abstract;
    function    GetItem(Index: integer): byte; virtual;
    procedure   SetItem(Index: integer; const Value: byte); virtual;
    function    GetCount: integer;virtual;
  public
    property    Data[index: integer]: byte read GetItem write SetItem; default;
    property    Count: integer read GetCount;
    function    ToString: string; virtual;
    function    ToNearest(const Value: integer): integer; virtual;
    constructor Create;virtual;
  end;

  THexLucasModulator = class(THexNumberModulator)
  protected
    function BuildNumberSeries: THexModulationTable;override;
    function DoFindNearest(const Value: integer): integer;virtual;
  public
    function ToNearest(const Value: integer): integer; override;
  end;

  THexFibonacciModulator = class(THexNumberModulator)
  protected
    function  BuildNumberSeries: THexModulationTable;override;
  public
    function ToNearest(const Value: integer): integer; override;
  end;

  THexLeonardoModulator = class(THexNumberModulator)
  protected
    function  BuildNumberSeries: THexModulationTable;override;
  public
    function ToNearest(const Value: integer): integer; override;
  end;

implementation

//############################################################################
// THexLeonardoModulator
//############################################################################

function THexLeonardoModulator.BuildNumberSeries: THexModulationTable;
var
  x: integer;
  a,b : integer;
begin
  result[low(result)] := 1;
  result[low(result)+1] := 1;
  for x:=low(result)+2 to high(result) do
  begin
    a:= result[x-2];
    b:= result[x-1];
    result[x] := a + b + 1;
  end;
end;

function THexLeonardoModulator.ToNearest(const Value: integer): integer;
begin
  if (value = 1) then
    result := 1 else
  if (value = 2) then
    result := 1 else
  result := ToNearest(value-1) + ToNearest(value-2) + 1;
end;

//############################################################################
// THexFibonacciModulator
//############################################################################

function THexFibonacciModulator.BuildNumberSeries: THexModulationTable;
var
  x: integer;
  a,b : integer;
begin
  result[low(result)] := 0;
  result[low(result)+1] := 1;
  for x:=low(result)+2 to high(result) do
  begin
    a:= result[x-2];
    b:= result[x-1];
    result[x] := a + b;
  end;
end;

function THexFibonacciModulator.ToNearest(const Value: integer): integer;
var
  LForward: integer;
  LBackward: integer;
  LForwardDistance: integer;
  LBackwardsDistance: integer;
begin
  (* Note: the round() function always rounds upwards to the closest
           whole number. Which in a formula can result in the routine
           returning the next number even though the previous number
           is closer.
           To remedy this we do a distance compare between "number" and
           "number-1", so make sure we pick the closest match in distance *)
  LForward := round( TFloat.Power( ( (1+SQRT(5)) / 2), value) / SQRT(5) );
  LBackward := round( TFloat.Power( ( (1+SQRT(5)) / 2), value-1) / SQRT(5) );

  if LForward <> LBackward then
  begin
    LForwardDistance := LForward - value;
    LBackwardsDistance := Value - LBackward;

    if (LForwardDistance < LBackwardsDistance) then
    result := LForward else
    result := LBackward;
  end else
  result := LForward;
end;

//############################################################################
// THexLucasModulator
//############################################################################

function THexLucasModulator.DoFindNearest(const Value: integer): integer;
var
  LBestDiff: integer;
  LDistance: integer;
  LMatch: integer;
  a,b,c : integer;
begin

  LBestDiff := MAX_INT;
  LMatch := -1;

  a := 2;
  b := 1;
  repeat
    c := a + b;
    LDistance := c - value;
    if (LDistance >= 0) then
    begin
      if (LDistance < LBestDiff) then
      begin
        LBestDiff := LDistance;
        LMatch := c;
      end;
    end;

    a := b;
    b := c;
  until (c > value) or (LBestDiff = 0);

  if (LMatch > 0) then
  result := LMatch else
  result := value;
end;

function THexLucasModulator.ToNearest(const Value: integer): integer;
var
  LForward: integer;
  LBackward: integer;
  LForwardDistance: integer;
  LBackwardsDistance: integer;
begin
  (* Note: Lucas is a bit harder to work with than fibonacci. So instead
     of using a formula we have to actually search a bit.
     It is however important to search both ways, since the distance
     backwards can be closer to the number than forward *)
  LForward := DoFindNearest(Value);
  LBackward := DoFindNearest(value-1);

  if LForward <> LBackward then
  begin
    LForwardDistance := LForward - value;
    LBackwardsDistance := Value - LBackward;

    if (LForwardDistance < LBackwardsDistance) then
    result := LForward else
    result := LBackward;
  end else
  result := LForward;
end;

function THexLucasModulator.BuildNumberSeries: THexModulationTable;
var
  x: integer;
  a,b : integer;
begin
  result[low(result)] := 2;
  result[low(result)+1] := 1;
  for x:=low(result)+2 to high(result) do
  begin
    a:= result[x-2];
    b:= result[x-1];
    result[x] := a + b;
  end;
end;

//############################################################################
// THexNumberModulator
//############################################################################

constructor THexNumberModulator.Create;
begin
  inherited create;
  FCache := BuildNumberSeries;
end;

function THexNumberModulator.ToNearest(const Value: integer): integer;
begin
  if Value > 1 then
  result := ToNearest( Value - 1 ) + ToNearest( Value - 2 ) else
  if Value = 0 then
  result := 2 else
  result := 1;
end;

function THexNumberModulator.ToString: string;
var
  x: integer;
begin
  for x:=low(FCache) to high(FCache) do
  begin
    if ( x < high(FCache) ) then
    result := result + FCache[x].toString() + ', ' else
    result := result + FCache[x].toString();
  end;
end;

function THexNumberModulator.GetItem(Index: integer): byte;
begin
  result := FCache[index];
end;

procedure THexNumberModulator.SetItem(Index: integer; const Value: byte);
begin
  FCache[index] := value;
end;

function THexNumberModulator.GetCount: integer;
begin
  result := length(FCache);
end;


end.
