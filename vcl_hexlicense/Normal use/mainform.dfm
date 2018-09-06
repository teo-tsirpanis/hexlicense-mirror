object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'License components - Normal use'
  ClientHeight = 412
  ClientWidth = 490
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 53
    Width = 70
    Height = 13
    Caption = 'Use this serial:'
  end
  object Button1: TButton
    Left = 8
    Top = 22
    Width = 97
    Height = 25
    Action = acStart
    TabOrder = 0
  end
  object Button2: TButton
    Left = 120
    Top = 22
    Width = 113
    Height = 25
    Action = acAuth
    TabOrder = 1
  end
  object Edit1: TEdit
    Left = 8
    Top = 72
    Width = 265
    Height = 21
    TabOrder = 2
    Text = 'A25196-2402FF-19002C-A2B0EA'
  end
  object Memo1: TMemo
    Left = 8
    Top = 112
    Width = 474
    Height = 292
    Lines.Strings = (
      
        'This example demonstrates a typical "trial" session for an appli' +
        'cation.'
      ''
      
        '1. Begin by clicking on "Start session". This begins the license' +
        ' cycle.'#11
      ''
      
        'If you want the cycle to begin when the application starts, set ' +
        'the Auto'
      'property of THexLicense to TRUE during design time.'
      ''
      '2. Copy the serial number in the texbox to the clipboard'
      ''
      
        '3. Click "Buy software". Use the serial number to validate the l' +
        'icense data'
      ''
      'TIP:'
      
        'If you want your license, once bought, to last for 12 months - s' +
        'imply'
      
        'check the "bought" property of THexLicense (public), add 12 mont' +
        'hs'
      
        'using the functions in dateutils, then validate that the current' +
        ' date is within'
      'that range.')
    TabOrder = 3
  end
  object HexLicense1: THexLicense
    Automatic = False
    Storage = HexOwnerLicenseStorage1
    SerialNumber = HexSerialNumber1
    License = ltRunTrial
    Duration = 30
    Provider = 'My company name'
    FixedStart = 41599.565932766210000000
    FixedEnd = 41613.565932766210000000
    Software = 'My application name'
    OnLicenseObtained = HexLicense1LicenseObtained
    OnAfterLicenseLoaded = HexLicense1AfterLicenseLoaded
    OnLicenseBegins = HexLicense1LicenseBegins
    OnLicenseExpires = HexLicense1LicenseExpires
    Left = 320
    Top = 8
  end
  object HexSerialMatrix1: THexSerialMatrix
    OnGetKeyMatrix = HexSerialMatrix1GetKeyMatrix
    Left = 416
    Top = 8
  end
  object HexSerialNumber1: THexSerialNumber
    SerialMatrix = HexSerialMatrix1
    Left = 320
    Top = 56
  end
  object HexOwnerLicenseStorage1: THexOwnerLicenseStorage
    SerialMatrix = HexSerialMatrix1
    OnDataExists = HexOwnerLicenseStorage1DataExists
    OnReadData = HexOwnerLicenseStorage1ReadData
    OnWriteData = HexOwnerLicenseStorage1WriteData
    Left = 416
    Top = 56
  end
  object ActionList1: TActionList
    Left = 256
    Top = 8
    object acStart: TAction
      Caption = 'Start session'
      OnExecute = acStartExecute
      OnUpdate = acStartUpdate
    end
    object acAuth: TAction
      Caption = 'Buy software'
      OnExecute = acAuthExecute
      OnUpdate = acAuthUpdate
    end
  end
end
