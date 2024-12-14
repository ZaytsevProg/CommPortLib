object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'DemoCommPort'
  ClientHeight = 302
  ClientWidth = 852
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 416
    Top = 24
    Width = 41
    Height = 13
    Caption = 'PortNo:'
  end
  object Label2: TLabel
    Left = 399
    Top = 51
    Width = 58
    Height = 13
    Caption = 'BaudRate:'
  end
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 393
    Height = 302
    Align = alLeft
    Lines.Strings = (
      '')
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object B_Open: TButton
    Left = 463
    Top = 88
    Width = 113
    Height = 33
    Cursor = crHandPoint
    Caption = 'Open'
    TabOrder = 1
    OnClick = B_OpenClick
  end
  object E_PortNo: TEdit
    Left = 463
    Top = 21
    Width = 113
    Height = 21
    TabOrder = 2
    Text = '1'
    OnKeyPress = E_PortNoKeyPress
  end
  object CB_BaudRate: TComboBox
    Left = 463
    Top = 48
    Width = 113
    Height = 22
    Cursor = crHandPoint
    Style = csOwnerDrawFixed
    TabOrder = 3
  end
  object B_Close: TButton
    Left = 591
    Top = 88
    Width = 113
    Height = 33
    Cursor = crHandPoint
    Caption = 'Close'
    TabOrder = 4
    OnClick = B_CloseClick
  end
  object B_Send: TButton
    Left = 463
    Top = 151
    Width = 113
    Height = 33
    Cursor = crHandPoint
    Caption = 'Send'
    TabOrder = 5
    OnClick = B_SendClick
  end
  object E_WriteStr: TEdit
    Left = 591
    Top = 157
    Width = 121
    Height = 21
    TabOrder = 6
  end
  object B_Clear: TButton
    Left = 719
    Top = 88
    Width = 113
    Height = 33
    Cursor = crHandPoint
    Caption = 'Clear'
    TabOrder = 7
    OnClick = B_ClearClick
  end
  object CommPort: TCommPort
    PortNo = 1
    BaudRate = 19200
    ByteSize = 8
    Parity = 0
    StopBits = 0
    Flags = 1
    ReadSleep = 0
    OnRead = CommPortRead
    OnErrors = CommPortErrors
    Left = 616
    Top = 24
  end
end
