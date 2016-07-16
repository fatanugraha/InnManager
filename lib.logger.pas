{
  lib.logger.pas
  :: contains methods for run-time debugging and logging.
}

unit lib.logger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, dateutils;

const
  FILE_LOG = 'main.log';

procedure dump(x: int64);
procedure dump(x: string);
procedure dump(x: TDateTime);
procedure dump(x: boolean);

//throw exception terus halt
procedure RaiseCriticalError(message: string; code: integer);

procedure InitLogger;
procedure WriteLog(message: string);
procedure CloseLogger;

implementation

uses
  lib.common;

var
  LogFile: TextFile;

procedure dump(x: boolean);
begin
  if x then
    ShowMessage('True')
  else
    ShowMessage('False');
end;

procedure dump(x: TDateTime);
begin
  ShowMessage(FormatDateTime('hh:mm:ss dddd dd/mm/yyyy', x));
end;

procedure dump(x: int64);
begin
  showmessage(IntToStr(x));
end;

procedure dump(x: string);
begin
  showmessage(x);
end;

procedure InitLogger;
begin
  AssignFile(LogFile, CurrentDir+FILE_LOG);
  Rewrite(LogFile);
end;

procedure CloseLogger;
begin
  CloseFile(LogFile);
end;

procedure RaiseCriticalError(message: string; code: integer);
begin
  WriteLog(message);

  //TODO: tentuin ini harus throw exception ato hanya pesan error
  raise Exception.Create(message);
  CloseLogger;
  halt(code);
end;

procedure WriteLog(message: string);
begin
  WriteLn(LogFile, Message);
end;

end.

