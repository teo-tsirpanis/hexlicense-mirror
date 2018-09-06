object frmNumber: TfrmNumber
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Generate serial numbers'
  ClientHeight = 173
  ClientWidth = 280
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
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 32
    Width = 244
    Height = 13
    Caption = 'Number of trackable, unique numbers to generate:'
  end
  object Edit1: TEdit
    Left = 16
    Top = 48
    Width = 85
    Height = 21
    NumbersOnly = True
    TabOrder = 0
    Text = '100'
  end
  object Button1: TButton
    Left = 184
    Top = 132
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = Button1Click
  end
  object TrackBar1: TTrackBar
    Left = 16
    Top = 76
    Width = 237
    Height = 45
    Max = 100000
    Min = 100
    PageSize = 100
    Position = 100
    ShowSelRange = False
    TabOrder = 2
    TickStyle = tsNone
    OnChange = TrackBar1Change
  end
end
