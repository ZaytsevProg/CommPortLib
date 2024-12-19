unit U_DemoCommPort;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CommPort, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    CommPort: TCommPort;
    Memo: TMemo;
    B_Open: TButton;
    Label1: TLabel;
    E_PortNo: TEdit;
    Label2: TLabel;
    CB_BaudRate: TComboBox;
    B_Close: TButton;
    B_Send: TButton;
    E_WriteStr: TEdit;
    B_Clear: TButton;
    procedure E_PortNoKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure CommPortErrors(Sender: TObject; ErrorMsg: string;
      ErrorCode: Int64);
    procedure B_ClearClick(Sender: TObject);
    procedure CommPortRead(Sender: TObject; AsyncRead: TAsyncRead);
    procedure B_OpenClick(Sender: TObject);
    procedure B_CloseClick(Sender: TObject);
    procedure B_SendClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.B_ClearClick(Sender: TObject);
begin
Memo.Clear;
end;

procedure TForm1.B_CloseClick(Sender: TObject);
begin
CommPort.Close;
end;

procedure TForm1.B_OpenClick(Sender: TObject);
begin
if Length(E_PortNo.Text) = 0 then Exit;

CommPort.PortNo   :=StrToInt(E_PortNo.Text);
CommPort.BaudRate :=StrToInt(CB_BaudRate.Text);
CommPort.ReadSleep:=500;
CommPort.Open;
end;

procedure TForm1.B_SendClick(Sender: TObject);
begin
if Length(E_WriteStr.Text) = 0 then Exit;
Memo.Lines.Add('WriteStrAsync: '  +CommPort.WriteStrAsync(E_WriteStr.Text).ToString);
end;

procedure TForm1.CommPortErrors(Sender: TObject; ErrorMsg: string;
  ErrorCode: Int64);
begin
//CommPort:=False;

  {Memo.Lines.Add('');
  Memo.Lines.Add('ErrorCode: ' +ErrorCode.ToString);
  Memo.Lines.Add('ErrorMsg: '  +ErrorMsg);
  Memo.Lines.Add(''); }
  Messagedlg(ErrorMsg, mterror, [mbok],0);
end;

procedure TForm1.CommPortRead(Sender: TObject; AsyncRead: TAsyncRead);
begin
  Memo.Lines.Add('');
  Memo.Lines.Add('Received: ' +AsyncRead.Received.ToString);
  Memo.Lines.Add('Buffer: '   +string(AsyncRead.Buffer));
  Memo.Lines.Add('');
end;

procedure TForm1.E_PortNoKeyPress(Sender: TObject; var Key: Char);
begin
if not (Key in ['0'..'9', #8]) then Key:=#0;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
I, BaudRate: Integer;
begin
E_PortNo.Text:='1';

CB_BaudRate.Items.BeginUpdate;
CB_BaudRate.Items.Clear;
BaudRate:=2400;
for i := 1 to 10 do begin
CB_BaudRate.Items.Add(IntToStr(BaudRate));
if BaudRate = 38400 then BaudRate:= 57600
Else
BaudRate:=BaudRate*2;
end;
CB_BaudRate.Items.EndUpdate;
CB_BaudRate.ItemIndex:=0;
end;

end.
