unit MainUI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.SystemRT, Winapi.CommCtrl,
  Cod.Windows, System.Generics.Collections, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Menus, ShellAPI, Winapi.ActiveX, System.Win.ComObj,
  Winapi.Winrt, Winapi.ApplicationModel, Cod.WindowsRT,
  Cod.WindowsRT.ActivationManager, Cod.UWP, Winapi.Management;

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
  MissingCounter: integer=0;

  ExistanceValidated: boolean=false;

implementation

{$R *.dfm}

var
  WinSActive: Boolean = False;

function LowLevelKeyboardProc(nCode: Integer; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  kbData: PKBDLLHOOKSTRUCT;
  IsKeyDown, IsKeyUp: Boolean;
begin
  if nCode = HC_ACTION then
  begin
    kbData := PKBDLLHOOKSTRUCT(lParam);
    IsKeyDown := (wParam = WM_KEYDOWN) or (wParam = WM_SYSKEYDOWN);
    IsKeyUp   := (wParam = WM_KEYUP)   or (wParam = WM_SYSKEYUP);

    // Pressed S (last to press, do not allow ctrl, alt or shift)
    if IsKeyDown and (kbData^.vkCode = Ord('S'))
      and (GetAsyncKeyState(VK_CONTROL) >= 0)
      and (GetAsyncKeyState(VK_MENU) >= 0)
      and (GetAsyncKeyState(VK_SHIFT) >= 0)
      and (GetAsyncKeyState(VK_LWIN) < 0) or (GetAsyncKeyState(VK_RWIN) < 0) then
    begin
      WinSActive := True;

      if Assigned(MainForm) then
        SendMessage(MainForm.Handle, WM_CUSTOM_RUN, 0, 0);

      Result := 1;  // block 'S'
      Exit;
    end;

    // Win+S active
    if WinSActive then
    begin
      // Block Win-DOWN
      if IsKeyDown and ((kbData^.vkCode = VK_LWIN) or (kbData^.vkCode = VK_RWIN)) then
      begin
        Result := 1;
        Exit;
      end;

      // Allow Win-UP but instantly neutralize Start Menu
      if IsKeyUp and ((kbData^.vkCode = VK_LWIN) or (kbData^.vkCode = VK_RWIN)) then
      begin
        // Cancel Start Menu by pressing and releasing SHIFT artificially
        keybd_event(VK_SHIFT, 0, 0, 0);
        keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);

        Result := 0; // DO NOT block Win-UP
        Exit;
      end;

      // End Win+S mode when S is released
      if (kbData^.vkCode = Ord('S')) and IsKeyUp then
        WinSActive := False;
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

procedure AttachThreadFocusWindow(Window: HWND);
var
  ForeThread, ThisThread: DWORD;
begin
  ForeThread := GetWindowThreadProcessId(GetForegroundWindow(), nil);
  ThisThread := GetCurrentThreadId();

  if AttachThreadInput(ThisThread, ForeThread, True) then begin
    SetForegroundWindow(Window);
    SetActiveWindow(Window);
    BringWindowToTop(Window);
    AttachThreadInput(ThisThread, ForeThread, False);
  end;
end;

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

procedure DoRunCommandPalette;
const
  APP_FAMILYNAME = 'Microsoft.CommandPalette_8wekyb3d8bbwe';
  APP_ACTIVATIONNAME = '!App';
var
  Mgr: IApplicationActivationManager;
  PID: dword;
  aHWND: HWND;
begin
  // Exists?
  if not ExistanceValidated then begin
    const PackageManager = TDeployment_PackageManager.Create;
    var Iterable: IIterable_1__IPackage;
    const FamName = HSTRING.Create(APP_FAMILYNAME);
    const UserSID = HSTRING.Create(GetUserCLSID);
    try
      Iterable := PackageManager.FindPackagesForUser(UserSID, FamName);
    except
      FamName.Free;
      UserSID.Free;
    end;
    if not Iterable.First.HasCurrent then begin
      if Assigned(MainForm) then
        try
          MainForm.Tray.BalloonTitle := 'Command Palette was not found!';
          MainForm.Tray.BalloonHint := 'We''ve attempted to run the app but it does not seem to be installed on your device.';
          MainForm.Tray.ShowBalloonHint;
        except
        end;
    end;

    // Do not call again
    ExistanceValidated := true;
  end;

  // Click
  Mgr := TApplicationActivationManager.Create;
  Mgr.ActivateApplication(APP_FAMILYNAME+APP_ACTIVATIONNAME, nil, ActivateOptions.None, PID);

  // Focus Window
  aHWND := GetCommandPaletteAppHWND;
  AttachThreadFocusWindow(aHWND);
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
