unit RegisterCommPort;
{$R CommPortLib.dcr}

interface

procedure Register;

implementation

uses
  Classes, CommPort;

procedure Register;
begin
  RegisterComponents('CommPortLib', [TCommPort]);
end;

end.

