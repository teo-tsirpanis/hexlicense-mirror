unit hex.types;

interface

uses
  system.types;

type

  THexKeyMatrix = Array[0..11] of byte;

  THexRange = class
  private
    FLow:     integer;
    FHigh:    integer;
  protected
    function  GetValid: boolean;
    function  GetTop: integer;
    function  GetBottom: integer;
    procedure SetLow(const NewLow: integer);
    procedure SetHigh(const NewHigh: integer);
  public
    property  Left: integer read FLow write SetLow;
    property  Right: integer read FHigh write SetHigh;
    property  Top: integer read GetTop;
    property  Bottom: integer read GetBottom;
    property  Valid: boolean read GetValid;
    procedure Define(const FromValue, ToValue: integer);
    procedure Reset;

    function  Next(const Value: integer): integer;

    class function Range(const Left, Right: integer): THexRange;

    function  Within(const Value: integer): boolean;
    function  Inside(const Value: integer): boolean;
    constructor Create(const FromValue, ToValue: integer);
  end;

implementation

//############################################################################
// THexRange
//############################################################################

constructor THexRange.Create(const FromValue, ToValue: integer);
begin
  inherited Create;
  Define(FromValue, ToValue);
end;

class function THexRange.Range(const Left, Right: integer): THexRange;
begin
  result := THexRange.Create(Left,Right);
end;

procedure THexRange.Reset;
begin
  FLow := -1;
  FHigh := -1;
end;

procedure THexRange.Define(const FromValue, ToValue: integer);
begin
  if (FromValue < ToValue) then
  begin
    FLow := FromValue;
    FHigh := ToValue;
  end else
  if (FromValue>ToValue) then
  begin
    FLow := ToValue;
    FHigh := FromValue;
  end else
  begin
    FLow := FromValue;
    FHigh := ToValue;
  end;
end;

function THexRange.Inside(const Value: integer): boolean;
begin
  if GetValid then
  begin
    result := (Value>FLow) and (Value<FHigh);
  end else
  result := value = FLow;
end;

function THexRange.Next(const Value: integer): integer;
begin
  result := (value +1) mod Top;
end;

function THexRange.Within(const Value: integer): boolean;
begin
  if GetValid then
  begin
    result := (Value>=FLow) and (Value<=FHigh);
  end else
  result := value = FLow;
end;

procedure THexRange.SetLow(const NewLow: integer);
begin
  Define(NewLow, FHigh);
end;

procedure THexRange.SetHigh(const NewHigh: integer);
begin
  Define(FLow,NewHigh);
end;

function THexRange.GetValid: boolean;
begin
  result := (FLow < FHigh) or ( (FLow = FHigh) and (FLow>=0) );
end;

function THexRange.GetTop: integer;
begin
  result := FHigh + 1;
end;

function THexRange.GetBottom: integer;
begin
  result := FLow -1;
end;


end.
