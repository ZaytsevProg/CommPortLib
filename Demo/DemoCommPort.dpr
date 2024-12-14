program DemoCommPort;

uses
  Vcl.Forms,
  U_DemoCommPort in 'U_DemoCommPort.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
