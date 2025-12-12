unit MainUI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.SystemRT, Winapi.CommCtrl,
  Cod.Windows, System.Generics.Collections, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Menus, ShellAPI;

const
  WM_CUSTOM_RUN = WM_USER + 100;

type
  TMainForm = class(TForm)
    Tray: TTrayIcon;
    PopupMenu1: TPopupMenu;
    Exit1: TMenuItem;
    Support1: TMenuItem;
    N1: TMenuItem;
    Visitwebsite1: TMenuItem;
    Delayed1Run: TTimer;
    procedure Support1Click(Sender: TObject);
    procedure Visitwebsite1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure Delayed1RunTimer(Sender: TObject);
  private
    { Private declarations }
    procedure DoMessageRun(var Msg: TMessage); message WM_CUSTOM_RUN;
  public
    { Public declarations }
  end;

procedure DoRunCommandPalette;

var
  MainForm: TMainForm;

  // Hook(er)
  KeyboardHook: HHOOK;

implementation

{$R *.dfm}

function GetCommandPaletteAppHWND: HWND;
var
  AFound: integer;
begin
  AFound := 0;

  // Find
  EnumerateActiveWindows(procedure(Window: HWND; var Continue: boolean) begin
    if Window.GetTitle = 'Command Palette' then begin
      AFound := Window;
      Continue := false;
    end;
  end);
  Result := AFound;
end;

procedure SimulateTrayClick(AppHWND: HWND);
const
  WM_TRAY_CALLBACK = WM_USER + 1;  // Vcl.ExtCtrls
  WM_LBUTTONDOWN = $0201;
  WM_LBUTTONUP   = $0202;
begin
  if not IsWindow(AppHWND) then Exit;

  // LBUTTONDOWN
  PostMessage(AppHWND, WM_TRAY_CALLBACK, 0, WM_LBUTTONDOWN);

  // LBUTTONUP
  PostMessage(AppHWND, WM_TRAY_CALLBACK, 0, WM_LBUTTONUP);
end;

function LowLevelKeyboardProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  kbData: PKBDLLHOOKSTRUCT;
  IsKeyDown: Boolean;
begin
  if nCode = HC_ACTION then
  begin
    kbData := PKBDLLHOOKSTRUCT(lParam);
    IsKeyDown := (wParam = WM_KEYDOWN) or (wParam = WM_SYSKEYDOWN);

    // Check if 'S' key is pressed while ONLY Win is down
    if IsKeyDown and (kbData^.vkCode = Ord('S')) then begin
      // Win pressed?
      if (GetAsyncKeyState(VK_LWIN) < 0) or (GetAsyncKeyState(VK_RWIN) < 0) then
      begin
        // NO other modifiers?
        if (GetAsyncKeyState(VK_CONTROL) >= 0) and
           (GetAsyncKeyState(VK_MENU) >= 0) and        // Alt
           (GetAsyncKeyState(VK_SHIFT) >= 0) then
        begin
          // Run command palette
          if Assigned(MainForm) then
            try
              SendMessage(MainForm.Handle, WM_CUSTOM_RUN, 0, 0);
            except
            end;

          // Block Win+S
          Result := 1;
          Exit;
        end;
      end;

    end;
  end;

  Result := CallNextHookEx(KeyboardHook, nCode, wParam, lParam);
end;

procedure InstallKeyboardHook;
begin
  KeyboardHook := SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc, HInstance, 0);
end;

procedure UninstallKeyboardHook;
begin
  if KeyboardHook <> 0 then
    UnhookWindowsHookEx(KeyboardHook);
end;

procedure FocusWindow(Window: HWND);
var
  ForeThread, ThisThread: DWORD;
begin
  ForeThread := GetWindowThreadProcessId(GetForegroundWindow(), nil);
  ThisThread := GetCurrentThreadId();

  AttachThreadInput(ThisThread, ForeThread, True);
  SetForegroundWindow(Window);
  SetActiveWindow(Window);
  BringWindowToTop(Window);
  AttachThreadInput(ThisThread, ForeThread, False);
end;

procedure DoRunCommandPalette;
var
  Window: HWND;
begin
  Window := GetCommandPaletteAppHWND;
  if Window <> 0 then begin
    // Click
    SimulateTrayClick(Window);

    // Bring to top
    FocusWindow( Window );
  end else begin
    // Attempt to start command palette
    ShellExecute(0, 'open', 'x-cmdpal://', nil, nil, SW_SHOW);

    if Assigned(MainForm) then
      try
        MainForm.Tray.BalloonTitle := 'Starting Command Palette...';
        MainForm.Tray.BalloonHint := 'We could not find Command Palette running. We''re attempting to start it now.';
        MainForm.Tray.ShowBalloonHint;
      except
      end;
  end;
end;

procedure TMainForm.Delayed1RunTimer(Sender: TObject);
begin
  TTimer(Sender).Enabled := false;

  // Run
  DoRunCommandPalette;
end;

procedure TMainForm.DoMessageRun(var Msg: TMessage);
begin
  Delayed1Run.Enabled := true;
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.Support1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://go.codrutsoft.com/support/', nil, nil, SW_SHOW);
end;

procedure TMainForm.TrayClick(Sender: TObject);
begin
  DoRunCommandPalette;
end;

procedure TMainForm.Visitwebsite1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://www.codrutsoft.com/', nil, nil, SW_SHOW);
end;

initialization
  // Install hook
  InstallKeyboardHook;
finalization
  // Free hook(er)
  UninstallKeyboardHook;
end.
