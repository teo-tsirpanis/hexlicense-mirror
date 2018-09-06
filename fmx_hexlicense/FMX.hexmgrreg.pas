  unit FMX.hexmgrreg;

  interface

  {$I FMX.hexlicense.inc}

  uses System.Sysutils, System.Classes, FMX.hexmgrlicense;

  Procedure Register;

  implementation

  uses FMX.hextools, FMX.Hexbuffers;


  Procedure Register;
  Begin
    RegisterComponents('HexLicense FMX',
    [TFMXHexLicense,
    {$IFDEF MSWINDOWS}
    TFMXHexRegistryLicenseStorage,
    {$ENDIF}
    TFMXHexOwnerLicenseStorage,
    TFMXHexFileLicenseStorage,
    TFMXHexSerialMatrix,
    TFMXHexSerialNumber,
    TFMXHexSerialGenerator,

    TFMXHexBufferMemory,
    TFMXHexBufferFile,

    TFMXHexKeyRC4,
    TFMXHexEncoderRC4,
    TFMXHexRecord,
    TFMXHexFieldBoolean,
    TFMXHexFieldByte,
    TFMXHexFieldCurrency,
    TFMXHexFieldData,
    TFMXHexFieldDateTime,
    TFMXHexFieldDouble,
    TFMXHexFieldGUID,
    TFMXHexFieldInt64,
    TFMXHexFieldInteger,
    TFMXHexFieldLong,
    TFMXHexFieldString,
    TFMXHexPartsAccess,
    TFMXHexBitAccess

    ]);
  end;

  end.
