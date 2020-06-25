object JSRTTIExtensionFrm: TJSRTTIExtensionFrm
  Left = 0
  Top = 0
  Caption = 'JSRTTIExtension'
  ClientHeight = 641
  ClientWidth = 1081
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object imgQrCode: TImage
    Left = 0
    Top = 457
    Width = 165
    Height = 165
    Align = alLeft
    Stretch = True
    ExplicitLeft = 438
    ExplicitTop = 428
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 622
    Width = 1081
    Height = 19
    Panels = <
      item
        Width = 1000
      end>
  end
  object CEFWindowParent1: TCEFWindowParent
    Left = 0
    Top = 0
    Width = 1081
    Height = 457
    Align = alTop
    TabOrder = 1
  end
  object btnReload: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Reload'
    TabOrder = 2
    OnClick = btnReloadClick
  end
  object mmoDebug: TMemo
    Left = 171
    Top = 457
    Width = 910
    Height = 165
    Align = alRight
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object Chromium1: TChromium
    OnProcessMessageReceived = Chromium1ProcessMessageReceived
    OnLoadStart = Chromium1LoadStart
    OnLoadEnd = Chromium1LoadEnd
    OnBeforeContextMenu = Chromium1BeforeContextMenu
    OnContextMenuCommand = Chromium1ContextMenuCommand
    OnBeforePopup = Chromium1BeforePopup
    OnAfterCreated = Chromium1AfterCreated
    OnBeforeClose = Chromium1BeforeClose
    OnClose = Chromium1Close
    Left = 32
    Top = 224
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 32
    Top = 288
  end
end
