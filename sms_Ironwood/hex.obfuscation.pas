unit hex.obfuscation;

interface

uses
  SmartCL.system,
  system.types,
  hex.types;

type

THexObfuscationMatrix = Array[0..25] of integer;

THexObfuscation = class;

THexObfuscationTypes = class
public
  class function Sepsephos: THexObfuscation;
  class function Hebrew: THexObfuscation;
  class function Latin: THexObfuscation;
  class function Beatus: THexObfuscation;
  class function Amun: THexObfuscation;
end;

THexObfuscation = class(TObject)
private
  FMatrix: THexObfuscationMatrix;
protected
  function GetMatrix: THexObfuscationMatrix; virtual; abstract;
  function FindInMatrix(const Value: integer): Integer;
public
  class function Types(): THexObfuscationTypes;
  function Encode(const Data: byte): byte; overload; virtual;
  function Encode(Text: string): string; overload; virtual;

  function Decode(const Data: byte): byte; overload; virtual;
  function Decode(Text: string): string; overload; virtual;

  procedure Clear;
  function Ready: boolean;
  procedure Load;
  constructor Create; virtual;
end;

THexObfuscationSepsephos = class(THexObfuscation)
protected
  function GetMatrix: THexObfuscationMatrix; override;
end;

THexObfuscationHebrew = class(THexObfuscation)
protected
  function GetMatrix: THexObfuscationMatrix; override;
end;

THexObfuscationBeatus = class(THexObfuscation)
protected
  function GetMatrix: THexObfuscationMatrix; override;
end;

THexObfuscationLatin = class(THexObfuscation)
protected
  function GetMatrix: THexObfuscationMatrix; override;
end;

THexObfuscationAmun = class(THexObfuscation)
protected
  function GetMatrix: THexObfuscationMatrix; override;
end;

implementation

//############################################################################
// THexObfuscationTypes
//############################################################################

class function THexObfuscationTypes.Sepsephos: THexObfuscation;
begin
  result := THexObfuscationSepsephos.Create;
end;

class function THexObfuscationTypes.Hebrew: THexObfuscation;
begin
  result := THexObfuscationHebrew.Create;
end;

class function THexObfuscationTypes.Latin: THexObfuscation;
begin
  result := THexObfuscationLatin.Create;
end;

class function THexObfuscationTypes.Beatus: THexObfuscation;
begin
  result := THexObfuscationBeatus.Create;
end;

class function THexObfuscationTypes.Amun: THexObfuscation;
begin
  result := THexObfuscationAmun.Create;
end;

//############################################################################
// THexObfuscation
//############################################################################

constructor THexObfuscation.Create;
begin
  inherited Create;
  FMatrix := GetMatrix();
end;

class function THexObfuscation.Types(): THexObfuscationTypes;
begin
  result := THexObfuscationTypes.Create;
end;

function THexObfuscation.Ready: boolean;
var
  LSum: integer;
begin
  for var Item in FMatrix do
  begin
    inc(LSum, Item);
  end;
  result := (LSum > 0);
end;

procedure THexObfuscation.Load;
begin
  FMatrix := GetMatrix();
end;

procedure THexObfuscation.Clear;
begin
  FMatrix := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
end;

function THexObfuscation.FindInMatrix(const Value: integer): Integer;
var
  x: integer;
begin
  result := -1;
  for x:=low(FMatrix) to high(FMatrix) do
  begin
    if FMatrix[x] = Value then
    begin
      result := x;
      break;
    end;
  end;
end;

function THexObfuscation.Encode(const Data: byte): byte;
const
  CNT_CHARSET = '0123456789abcdef';
var
  LText: string;
  LTemp: string;
  xpos: integer;
begin
  LText := IntToHex(Data,2);
  for var LChar in LText do
  begin
    xpos := pos(LChar, CNT_CHARSET);
    LTemp := LTemp + IntToHex(FMatrix[xpos],1);
  end;
  result := HexToInt('$' + LTemp);
end;

function THexObfuscation.Encode(Text: string): string;
const
  CNT_CHARSET = 'abcdefghijklmnopqrstuvwxyz';
var
  xpos: integer;
  x: integer;
  LValue: integer;
  LChar: char;
begin
  Text := Text.trim().toLower();
  if Text.length > 0 then
  begin
    for x:=low(Text) to high(Text) do
    begin
      LChar :=Text[x].ToLower();
      xpos := pos(LChar, CNT_CHARSET);
      if xpos>0 then
      begin
        dec(xpos);
        LValue := FMatrix[xpos];
        result += IntToHex(LValue,4);
      end else
      begin
        result += "C932" + IntToHex(TString.CharCodeFor(LChar),2);
      end;
    end;
  end;
end;

function THexObfuscation.Decode(Text: string): string;
begin
end;

function THexObfuscation.Decode(const Data: byte): byte;
const
  CNT_CHARSET = '0123456789abcdef';
var
  LText: string;
  LTemp: string;
  xpos: integer;
begin
  LText := IntToHex(Data,2);
  for var LChar in LText do
  begin
    var LValue := HexToInt('$' + LChar);
    xpos := FindInMatrix(LValue);

    // If the value is not in the gematria matrix, the value
    // is either not encoded, or encoded using a different gematria matrix
    // Exit stage right ..
    if (xpos<0) then
    begin
      result := Data;
      exit;
    end;

    LTemp := LTemp + CNT_CHARSET[xpos];
  end;
  result := HexToInt('$' + LTemp);
end;

//############################################################################
// THexObfuscationSepsephos
//############################################################################

function THexObfuscationSepsephos.GetMatrix: THexObfuscationMatrix;
begin
  result := [1,2,3,4,5,6,7,8,10,100,10,20,30,40,50,3,70,80,200,300,400,6,80,60,10,800];
end;

//############################################################################
// THexObfuscationHebrew
//############################################################################

function THexObfuscationHebrew.GetMatrix: THexObfuscationMatrix;
begin
  result := [0,2,100,4,0,80,3,5,10,10,20,30,40,50,0,80,100,200,300,9,6,6,6,60,10,7];
end;

//############################################################################
// THexObfuscationBeatus
//############################################################################

function THexObfuscationBeatus.GetMatrix: THexObfuscationMatrix;
begin
  result := [1,2,90,4,5,6,7,8,10,10,20,30,40,50,70,80,100,200,300,400,6,6,6,60,10,7];
end;

//############################################################################
// THexObfuscationLatin
//############################################################################

function THexObfuscationLatin.GetMatrix: THexObfuscationMatrix;
begin
  result := [1,2,700,4,5,500,3,8,10,10,20,30,40,50,70,80,600,100,200,300,400,6,800,60,10,7];
end;

//############################################################################
// THexObfuscationAmun
//############################################################################

function THexObfuscationAmun.GetMatrix: THexObfuscationMatrix;
begin
  result := [1,19,46,21,09,19,73,31,18,60,12,17,37,4,7,8,17,13,244,364,496,512,122,196,291,600];
end;

end.
