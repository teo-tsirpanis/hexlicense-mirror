object frmExport: TfrmExport
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Export keyset'
  ClientHeight = 172
  ClientWidth = 316
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnKeyPress = FormKeyPress
  DesignSize = (
    316
    172)
  PixelsPerInch = 96
  TextHeight = 13
  object RadioGroup1: TRadioGroup
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 304
    Height = 124
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Select keyset file format'
    ItemIndex = 0
    Items.Strings = (
      'Text file'
      'XML dataset'
      'Binary dataset'
      'JSON dictionary')
    TabOrder = 0
  end
  object Button1: TButton
    Left = 238
    Top = 138
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 158
    Top = 138
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Export'
    Default = True
    TabOrder = 2
    OnClick = Button2Click
  end
end
