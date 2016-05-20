unit lib.logger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

const
  FILE_LOG = 'main.log';

procedure dump(x: int64);
procedure dump(x: string);

//for logging purposes
procedure InitLogger;
procedure WriteLog(message: string);
procedure RaiseCriticalError(message: string; code: integer);
procedure CloseLogger;

implementation

uses
  lib.common;

var
  LogFile: TextFile;

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

