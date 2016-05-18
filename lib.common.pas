unit lib.common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, md5, LCLType;

const
  FILE_COREDB = 'core.sqlite3';
  FILE_DRIVER = 'sqlite3.dll';

  SALT_PREFIX = 'kucing_';
  SALT_SUFFIX = '_terbang';

  APP_NAME    = 'PSBB MAN 3 Malang Reservation System';

  AUTH_SEE_PRODUCT  = 1;
  AUTH_EDIT_PRODUCT = 2;
  AUTH_SEE_USER     = 4;
  AUTH_EDIT_USER    = 8;

function VerifyFiles: integer;
function CurrentDir: string;
function IsFieldEmpty(Sender: TObject): boolean;
function HashPassword(password: string): string;

implementation

uses
  lib.logger;

function HashPassword(password: string): string;
begin
  result := md5print(md5string(format('%s%s%s', [SALT_PREFIX, password, SALT_SUFFIX])));
end;

function IsFieldEmpty(Sender: TObject): boolean;
begin
  result := Trim(TEdit(Sender).Text) = '';
  if (result) then
  begin
    Application.MessageBox('Isi field yang diperlukan.', 'Field Kosong', MB_ICONEXCLAMATION);
    TEdit(Sender).SetFocus;
  end;
end;

function CurrentDir: string;
begin
  result := IncludeTrailingBackslash(ExtractFilePath(Application.Exename));
end;

function VerifyFiles: integer;
begin
  //chcek coredb
  if (not FileExists(CurrentDir+FILE_COREDB)) then
     exit(1);

  if (not FileExists(CurrentDir+FILE_DRIVER)) then
     exit(2);

  //check reservation data here
  exit(0);
end;

end.

