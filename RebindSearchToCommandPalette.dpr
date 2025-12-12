program RebindSearchToCommandPalette;

uses
  Vcl.Forms,
  Cod.Instances,
  MainUI in 'MainUI.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;

  InstanceAuto(TAutoInstanceMode.TerminateIfOtherExist);

  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := false;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
