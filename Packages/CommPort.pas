unit CommPort;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.SyncObjs;


type
  TAsyncRead = packed record
    Buffer   :AnsiString;
    Received :Cardinal;
  end;

  TReadEvent   = procedure(Sender: TObject; AsyncRead: TAsyncRead) of object;
  TErrorsEvent = procedure(Sender: TObject; ErrorMsg: String; ErrorCode :Int64) of object;

  TOperationKind = (okWrite, okRead);
  TAsync = record
    Overlapped: TOverlapped;
    Kind: TOperationKind;
    Data: Pointer;
    Size: Integer;
  end;
  PAsync = ^TAsync;


  TCustomCommPort = class;

  TCommThread = class(TThread)
  private
    FCommPort: TCustomCommPort;
    FStopEvent: THandle;
    procedure InitRead;
  protected
    procedure Execute; override;
    procedure Stop;
  public
    constructor Create(ACommPort: TCustomCommPort);
    destructor Destroy; override;
  end;

  TCommBuffer = class(TPersistent)
  private
    FCommPort: TCustomCommPort;
    FInputSize  :Integer;
    FOutputSize :Integer;
    procedure SetCustomCommPort(const ACommPort: TCustomCommPort);
    procedure SetInputSize(const Value: Integer);
    procedure SetOutputSize(const Value: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property CommPort: TCustomCommPort read FCommPort;
  published
    property InputSize  :Integer read FInputSize write SetInputSize default 1024;
    property OutputSize :Integer read FOutputSize write SetOutputSize default 1024;
  end;

  TPCommTimeouts = class(TPersistent)
  private
    FCommPort: TCustomCommPort;
    FReadInterval         :DWORD;
    FReadTotalMultiplier  :DWORD;
    FReadTotalConstant    :DWORD;
    FWriteTotalMultiplier :DWORD;
    FWriteTotalConstant   :DWORD;
    procedure SetCustomCommPort(const ACommPort: TCustomCommPort);

    procedure SetReadInterval(const Value: DWORD);
    procedure SetReadTotalMultiplier(const Value: DWORD);
    procedure SetReadTotalConstant(const Value: DWORD);
    procedure SetWriteTotalMultiplier(const Value: DWORD);
    procedure SetWriteTotalConstant(const Value: DWORD);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property CommPort: TCustomCommPort read FCommPort;
  published
    property ReadInterval: DWORD read FReadInterval write SetReadInterval default MAXDWORD;
    property ReadTotalMultiplier: DWORD read FReadTotalMultiplier write SetReadTotalMultiplier default 0;
    property ReadTotalConstant: DWORD read FReadTotalConstant write SetReadTotalConstant default 0;
    property WriteTotalMultiplier: DWORD read FWriteTotalMultiplier write SetWriteTotalMultiplier default 0;
    property WriteTotalConstant: DWORD read FWriteTotalConstant write SetWriteTotalConstant default 0;
  end;

  TCustomCommPort = class(TComponent)
  private
    FEventThread: TCommThread;
    FThreadCreated: Boolean;
    FHandle: THandle;
    FConnected: Boolean;
    FPortNo: Cardinal;
    FBaudRate: Cardinal;
    FByteSize: Byte;
    FParity: Byte;
    FStopBits: Byte;
    FFlags: Longint;
    FBuffer: TCommBuffer;
    FReadSleep: Cardinal;
    FTimeouts: TPCommTimeouts;
    AsyncRead :TAsyncRead;
    FErrorException :Boolean;
    FOnRead: TReadEvent;
    FOnErrors: TErrorsEvent;

    procedure DestroyCommPort; virtual;
    function SetCommPort():Boolean; dynamic;
    function ReadSync():Boolean;
    procedure InitAsync(var AsyncPtr: PAsync);
    procedure DoneAsync(var AsyncPtr: PAsync);
    function InputCount: LongInt;
    procedure PrepareAsync(AKind: TOperationKind; const Buffer; Count: Integer; AsyncPtr: PAsync);
    procedure CommErrors(const ErrorCode :Int64 = 0);
    procedure SetPort(const Value: Cardinal);
    procedure SetBaudRate(const Value: Cardinal);
    procedure SetByteSize(const Value: Byte);
    procedure SetParity(const Value: Byte);
    procedure SetStopBits(const Value: Byte);
    procedure SetFlags(const Value: Longint);
    procedure SetBuffer(const Value: TCommBuffer);
    procedure SetReadSleep(const Value: Cardinal);
    procedure SetTimeouts(const Value: TPCommTimeouts);
    procedure SetErrorException(const Value: Boolean);
  public
   property Handle: THandle read FHandle;
   property Connected: Boolean read FConnected write FConnected default False;
   property PortNo: Cardinal read FPortNo write SetPort;
   property BaudRate: Cardinal read FBaudRate write SetBaudRate;
   property ByteSize: Byte read FByteSize write SetByteSize;
   property Parity: Byte read FParity write SetParity;
   property StopBits: Byte read FStopBits write SetStopBits;
   property Flags: Longint read FFlags write SetFlags;
   property Buffer: TCommBuffer read FBuffer write SetBuffer;
   property ReadSleep: Cardinal read FReadSleep write SetReadSleep;
   property Timeouts: TPCommTimeouts read FTimeouts write SetTimeouts;
   property ErrorException: Boolean read FErrorException write SetErrorException;

   property OnRead: TReadEvent read FOnRead write FOnRead;
   property OnErrors: TErrorsEvent read FOnErrors write FOnErrors;

  published
    constructor Create(ACommPort: TComponent); override;
    destructor Destroy; override;
    function Open():Boolean;
    procedure Close;
    function WriteStrAsync(const InBuffer :String): Integer;
  end;

    TCommPort = class(TCustomCommPort)
    published
     property Connected;
     property PortNo;
     property BaudRate;
     property ByteSize;
     property Parity;
     property StopBits;
     property Flags;
     property Buffer;
     property ReadSleep;
     property Timeouts;
     property ErrorException;

     property OnRead;
     property OnErrors;
  end;


implementation


constructor TCommBuffer.Create;
begin
  inherited Create;
  FInputSize := 1024;
  FOutputSize:= 1024;
end;

procedure TCommBuffer.AssignTo(Dest: TPersistent);
begin
  if Dest is TCommBuffer then
  begin
    with TCommBuffer(Dest) do
    begin
      FOutputSize:= Self.OutputSize;
      FInputSize := Self.InputSize;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure TCommBuffer.SetCustomCommPort(const ACommPort: TCustomCommPort);
begin
  FCommPort:= ACommPort;
end;

procedure TCommBuffer.SetInputSize(const Value: Integer);
begin
  if Value <> FInputSize then
    FInputSize := Value;
end;

procedure TCommBuffer.SetOutputSize(const Value: Integer);
begin
  if Value <> FOutputSize then
    FOutputSize := Value;
end;

constructor TPCommTimeouts.Create;
begin
  inherited Create;
  FReadInterval         :=MAXDWORD;
  FReadTotalMultiplier  :=0;
  FReadTotalConstant    :=0;
  FWriteTotalMultiplier :=0;
  FWriteTotalConstant   :=0;
end;

procedure TPCommTimeouts.AssignTo(Dest: TPersistent);
begin
  if Dest is TPCommTimeouts then
  begin
    with TPCommTimeouts(Dest) do
    begin
      FReadInterval         := Self.ReadInterval;
      FReadTotalMultiplier  := Self.ReadTotalMultiplier;
      FReadTotalConstant    := Self.ReadTotalConstant;
      FWriteTotalMultiplier := Self.WriteTotalMultiplier;
      FWriteTotalConstant   := Self.WriteTotalConstant;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure TPCommTimeouts.SetCustomCommPort(const ACommPort: TCustomCommPort);
begin
  FCommPort := ACommPort;
end;

procedure TPCommTimeouts.SetReadInterval(const Value: DWORD);
begin
  if Value <> FReadInterval then
    FReadInterval := Value;
end;

procedure TPCommTimeouts.SetReadTotalMultiplier(const Value: DWORD);
begin
  if Value <> FReadTotalMultiplier then
    FReadTotalMultiplier := Value;
end;

procedure TPCommTimeouts.SetReadTotalConstant(const Value: DWORD);
begin
  if Value <> FReadTotalConstant then
    FReadTotalConstant := Value;
end;

procedure TPCommTimeouts.SetWriteTotalMultiplier(const Value: DWORD);
begin
  if Value <> FWriteTotalMultiplier then
    FWriteTotalMultiplier := Value;
end;

procedure TPCommTimeouts.SetWriteTotalConstant(const Value: DWORD);
begin
  if Value <> FWriteTotalConstant then
    FWriteTotalConstant := Value;
end;

constructor TCommThread.Create(ACommPort: TCustomCommPort);
begin
  isMultiThread:= True;
  inherited Create(False);
  FStopEvent:=CreateEvent(nil, True, False, nil);
  FCommPort:= ACommPort;
  Priority:=tpNormal;
  //EV_BREAK or EV_RX80FULL or EV_CTS or EV_DSR or EV_ERR or EV_RING or EV_RLSD or EV_RXCHAR or EV_RXFLAG or EV_TXEMPTY
  if not SetCommMask(FCommPort.Handle, EV_RXCHAR) then begin
    FCommPort.CommErrors(GetLastError);
    Exit;
  end;
end;

destructor TCommThread.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TCommThread.Stop;
begin
  SetEvent(FStopEvent);
end;

procedure TCommThread.Execute;
var
  EventHandles: array[0..1] of THandle;
  Overlapped: TOverlapped;
  dwSignaled, BytesTrans, Mask: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  EventHandles[0] := FStopEvent;
  EventHandles[1] := Overlapped.hEvent;

  repeat
   if not WaitCommEvent(FCommPort.Handle, Mask, @Overlapped) then
    if GetLastError <> ERROR_IO_PENDING then begin
     FCommPort.CommErrors(GetLastError);
     break;
    end;

   dwSignaled := WaitForMultipleObjects(2, @EventHandles, False, INFINITE);
    case dwSignaled of
      WAIT_OBJECT_0:Break;
      WAIT_OBJECT_0 + 1:
      if (GetOverlappedResult(FCommPort.Handle, Overlapped, BytesTrans, False)) and ((Mask and EV_RXCHAR) <> 0) then begin
       Sleep(FCommPort.FReadSleep);
        if FCommPort.ReadSync() then
          Synchronize(InitRead);
      end else Break;
    end;
  until dwSignaled <> (WAIT_OBJECT_0 + 1);

CloseHandle(Overlapped.hEvent);
SetCommMask(FCommPort.Handle, 0);
PurgeComm(FCommPort.Handle, PURGE_TXCLEAR or PURGE_RXCLEAR);
CloseHandle(FStopEvent);
inherited;
end;


procedure TCommThread.InitRead;
begin
  With FCommPort do
  begin
    If Assigned(FOnRead) then
        OnRead(Self, AsyncRead);
  end;
end;



constructor TCustomCommPort.Create(ACommPort: TComponent);
begin
  inherited Create(ACommPort);
  FHandle := INVALID_HANDLE_VALUE;
  FThreadCreated:=False;
  FConnected:=False;
  FPortNo:=1;
  FBaudRate:=CBR_19200;
  FByteSize:=8;
  FParity:=NOPARITY;
  FStopBits:=ONESTOPBIT;
  FFlags:=EV_RXCHAR;
  FBuffer:= TCommBuffer.Create;
  FBuffer.SetCustomCommPort(Self);
  FReadSleep:=0;
  FTimeouts:= TPCommTimeouts.Create;
  FTimeouts.SetCustomCommPort(Self);
  FErrorException:=True;
end;

destructor TCustomCommPort.Destroy;
begin
  FBuffer.Free;
  FTimeouts.Free;
  Close;
  inherited Destroy;
end;

procedure TCustomCommPort.DestroyCommPort;
begin
FConnected:=False;
if FThreadCreated then begin
 FThreadCreated:=False;
 FEventThread.Free;
 FEventThread:= nil;
end;
if FHandle <> INVALID_HANDLE_VALUE then
if CloseHandle(FHandle) then
FHandle:=INVALID_HANDLE_VALUE;
end;


function TCustomCommPort.SetCommPort():Boolean;
var
  FDCB :TDCB;
  FCTO :TCommTimeouts;
  ERR  :Dword;
begin
try
Result:=False;
ClearCommError(Handle, ERR, nil);

if not SetUpComm(FHandle, FBuffer.InputSize, FBuffer.OutputSize) then begin
CommErrors(GetLastError);
Exit;
end;

GetCommState(FHandle, FDCB);
 with FDCB do begin
    DCBlength:= SizeOf(TDCB);
    BaudRate := FBaudRate;
    ByteSize := FByteSize;
    Parity   := FParity;
    StopBits := FStopBits;
    Flags    := FFlags;
    XonLim   := FBuffer.InputSize div 4;;
    XoffLim  := XonLim;
    XonChar  := #17;
    XoffChar := #19;
    ErrorChar:= #0;
    EofChar  := #0;
    EvtChar  := #0;
 end;
  if not SetCommState(FHandle, FDCB) then begin
   CommErrors(GetLastError);
   DestroyCommPort;
   Exit;
  end;

GetCommTimeouts(FHandle, FCTO);
 with FCTO do begin
    ReadIntervalTimeout         := FTimeouts.FReadInterval;
    ReadTotalTimeoutMultiplier  := FTimeouts.FReadTotalMultiplier;
    ReadTotalTimeoutConstant    := FTimeouts.FReadTotalConstant;
    WriteTotalTimeoutMultiplier := FTimeouts.FWriteTotalMultiplier;
    WriteTotalTimeoutConstant   := FTimeouts.FWriteTotalConstant;
 end;
  if not SetCommTimeouts(FHandle, FCTO) then begin
   CommErrors(GetLastError);
   DestroyCommPort;
   Exit;
  end;

if not PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR or PURGE_RXABORT or PURGE_TXABORT) then begin
   CommErrors(GetLastError);
   DestroyCommPort;
   Exit;
end;

if not EscapeCommFunction( fhandle, CLRRTS Or CLRDTR Or SETRTS Or SETDTR ) then begin
   CommErrors(GetLastError);
   DestroyCommPort;
   Exit;
end;

Result:=True;
except
CommErrors(GetLastError);
DestroyCommPort;
end;
end;


function TCustomCommPort.Open():Boolean;
begin
try
Result:=False;
FHandle:= CreateFile(PChar('\\?\' + Format('COM%u', [FPortNo])),  GENERIC_READ + GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

if FHandle = INVALID_HANDLE_VALUE then begin
 CommErrors(GetLastError);
 DestroyCommPort;

 end else begin
  if SetCommPort = False then Exit;

  If not Assigned(FEventThread) then begin
    FThreadCreated:=True;
    FEventThread:=TCommThread.Create(Self);
  end;

   FConnected:=True;
   Result:=True;
 end;
except
CommErrors(GetLastError);
DestroyCommPort;
end;
end;


procedure TCustomCommPort.Close;
begin
DestroyCommPort;
end;

function TCustomCommPort.WriteStrAsync(const InBuffer :String): Integer;
var
 Success: Boolean;
 BytesTrans: DWORD;
 AsyncPtr: PAsync;
 Buffer :AnsiString;
 Count, I : Integer;
begin
Result:=0;
if FHandle = INVALID_HANDLE_VALUE then Exit;
if Length(InBuffer) = 0 then Exit;
Count:=Length(InBuffer);
SetLength(Buffer, Count);

{$IFDEF Unicode}
for I := 1 to Count do
Buffer[i]:=AnsiChar(Byte(InBuffer[i]));
{$ENDIF}

InitAsync(AsyncPtr);
if AsyncPtr = nil then Exit;

PrepareAsync(okWrite, Buffer[1], Count, AsyncPtr);

Try
 Success:= WriteFile(FHandle, Buffer[1], Count, BytesTrans, @(AsyncPtr^.Overlapped)) or (GetLastError = ERROR_IO_PENDING);
  if not Success then
   if GetLastError = ERROR_ACCESS_DENIED then begin
    CommErrors(GetLastError);
    Close;
    DoneAsync(AsyncPtr);
    Exit;
   end else
       CommErrors(GetLastError);

finally
DoneAsync(AsyncPtr);
end;

Result:= BytesTrans;
end;

function TCustomCommPort.ReadSync():Boolean;
var
 Success: Boolean;
 BytesInQueue : LongInt;
 AsyncPtr: PAsync;
begin
Try
Result:=False;
if FHandle = INVALID_HANDLE_VALUE then Exit;
BytesInQueue:=InputCount;
if BytesInQueue = 0 then Exit;

InitAsync(AsyncPtr);
if AsyncPtr = nil then Exit;

AsyncPtr^.Kind:= okRead;
SetLength(AsyncRead.Buffer, BytesInQueue + 1);

Try
  Success:=ReadFile(FHandle, AsyncRead.Buffer[1], BytesInQueue, AsyncRead.Received, @AsyncPtr^.Overlapped) or (GetLastError = ERROR_IO_PENDING);

  if not Success then
   if GetLastError = ERROR_ACCESS_DENIED then begin
    CommErrors(GetLastError);
    DoneAsync(AsyncPtr);
    Exit;
   end;

   if (AsyncPtr^.Kind = okRead) and (AsyncRead.Received > 0) and (Length(AsyncRead.Buffer) > 0) then
    Result:=True;

finally
DoneAsync(AsyncPtr);
end;
except
CommErrors(GetLastError);
end;
end;

procedure TCustomCommPort.InitAsync(var AsyncPtr: PAsync);
begin
  New(AsyncPtr);
  with AsyncPtr^ do
  begin
    FillChar(Overlapped, SizeOf(TOverlapped), 0);
    Overlapped.hEvent := CreateEvent(nil, True, True, nil);
    Data := nil;
    Size := 0;
  end;
end;

procedure TCustomCommPort.DoneAsync(var AsyncPtr: PAsync);
begin
  with AsyncPtr^ do
  begin
    CloseHandle(Overlapped.hEvent);
    if Data <> nil then
      FreeMem(Data);
  end;
  Dispose(AsyncPtr);
  AsyncPtr := nil;
end;

function TCustomCommPort.InputCount: LongInt;
var
  Errors: DWORD;
  ComStat: TComStat;
begin
  if not ClearCommError(FHandle, Errors, @ComStat) then begin
  PurgeComm(FHandle, PURGE_RXCLEAR);
  CommErrors(GetLastError);
  Result:= 0;
 end else
  Result:=ComStat.cbInQue;
end;

procedure TCustomCommPort.PrepareAsync(AKind: TOperationKind; const Buffer; Count: Integer; AsyncPtr: PAsync);
begin
  with AsyncPtr^ do
  begin
    Kind := AKind;
    if Data <> nil then
      FreeMem(Data);
    GetMem(Data, Count);
    Move(Buffer, Data^, Count);
    Size := Count;
  end;
end;

procedure TCustomCommPort.CommErrors(const ErrorCode :Int64 = 0);
var
  ErrorMessage: string;
begin
if Assigned(OnErrors) then begin
if ErrorCode > 0 then
    try
      Win32Check(ErrorCode = 0);
    except
      on E:Exception do
        ErrorMessage:=e.message;
    end;

if FErrorException then
raise Exception.Create(ErrorMessage)
Else
OnErrors(Self, ErrorMessage, ErrorCode);
end;
end;

procedure TCustomCommPort.SetPort(const Value: Cardinal);
begin
  if Value <> FPortNo then
    FPortNo := Value;
end;

procedure TCustomCommPort.SetBaudRate(const Value: Cardinal);
begin
  if Value <> FBaudRate then
    FBaudRate := Value;
end;

procedure TCustomCommPort.SetByteSize(const Value: Byte);
begin
  if Value <> FByteSize then
    FByteSize := Value;
end;

procedure TCustomCommPort.SetParity(const Value: Byte);
begin
  if Value <> FParity then
    FParity := Value;
end;

procedure TCustomCommPort.SetStopBits(const Value: Byte);
begin
  if Value <> FStopBits then
    FStopBits := Value;
end;

procedure TCustomCommPort.SetFlags(const Value: LongInt);
begin
  if Value <> FFlags then
    FFlags := Value;
end;

procedure TCustomCommPort.SetBuffer(const Value: TCommBuffer);
begin
  FBuffer.Assign(Value);
end;

procedure TCustomCommPort.SetReadSleep(const Value: Cardinal);
begin
  if Value <> FReadSleep then
    FReadSleep := Value;
end;

procedure TCustomCommPort.SetTimeouts(const Value: TPCommTimeouts);
begin
  FTimeouts.Assign(Value);
end;

procedure TCustomCommPort.SetErrorException(const Value: Boolean);
begin
  if Value <> FErrorException then
    FErrorException := Value;
end;

end.
