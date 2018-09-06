unit hexmgrreg;

  interface

  {$I vcl.hexlicense.inc}

  uses System.Sysutils, System.Classes, hexmgrlicense, hexbuffers;

  procedure Register;

  implementation


  Procedure Register;
  Begin
    RegisterComponents('HexLicense',
    [THexLicense,
    THexRegistryLicenseStorage,
    THexOwnerLicenseStorage,
    THexFileLicenseStorage,
    THexSerialMatrix,
    THexSerialNumber,
    THexSerialGenerator,

    THexBufferMemory,
    THexBufferFile,

    THexKeyRC4,
    THexEncoderRC4,

    THexRecord,
    THexFieldBoolean,
    THexFieldByte,
    THexFieldCurrency,
    THexFieldData,
    THexFieldDateTime,
    THexFieldDouble,
    THexFieldGUID,
    THexFieldInt64,
    THexFieldInteger,
    THexFieldLong,
    THexFieldString,

    THexPartsAccess,
    THexBitAccess
    ]);
  end;

  end.
