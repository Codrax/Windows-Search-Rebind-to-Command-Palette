object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Rebind to Command Palette'
  ClientHeight = 120
  ClientWidth = 228
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Tray: TTrayIcon
    Hint = 'Rebind to Command Palette'
    PopupMenu = PopupMenu1
    Visible = True
    OnClick = TrayClick
    Left = 40
    Top = 24
  end
  object PopupMenu1: TPopupMenu
    Left = 112
    Top = 16
    object Support1: TMenuItem
      Caption = 'Support'
      OnClick = Support1Click
    end
    object Visitwebsite1: TMenuItem
      Caption = 'Visit website'
      OnClick = Visitwebsite1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Exit1: TMenuItem
      Caption = 'Exit'
      OnClick = Exit1Click
    end
  end
  object Delayed1Run: TTimer
    Enabled = False
    Interval = 1
    OnTimer = Delayed1RunTimer
    Left = 176
    Top = 24
  end
end
