unit hex.serialmatrix;

interface

uses 
  system.types,
  hex.types;

type

  { Access interface for TFMXHexCustomLicenseStorage}
  IHexSerialMatrix = Interface
    ['{D562EC1E-6254-45E6-87C7-18CF16CF84B3}']
    function GetSerialMatrix(var Value: THexKeyMatrix): boolean;
  end;

  THexGetSerialMatrixEvent = procedure (sender: TObject; var Matrix: THexKeyMatrix);

  THexSerialMatrix = class(TObject, IHexSerialMatrix)
  private
    FOnGetMatrix: THexGetSerialMatrixEvent;
  protected
    function GetSerialMatrix(var Value: THexKeyMatrix): boolean;
  published
    property OnGetMatrix: THexGetSerialMatrixEvent read FOnGetMatrix write FOnGetMatrix;
  end;


implementation

//############################################################################
// THexSerialMatrix
//############################################################################

function THexSerialMatrix.GetSerialMatrix(var Value: THexKeyMatrix): boolean;
var
  LTemp: THexKeyMatrix;
begin
  result := assigned(FOnGetMatrix);
  if result then
  begin
    FOnGetMatrix(self,LTemp);
    Value := LTemp;
  end;
end;



end.
