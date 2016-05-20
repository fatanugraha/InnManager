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

  CURRENCY = 'Rp';

function VerifyFiles: integer;
function CurrentDir: string;
function IsFieldEmpty(Sender: TObject): boolean;
function HashPassword(password: string): string;
function FormatCurrency(currency: string; x: int64): string;

implementation

uses
  lib.logger;

function FormatCurrency(currency: string; x: int64): string;
const
  LIMITER = ',';
var
  len: integer;
  tmp: int64;
begin
  tmp := x;
  len := 0;

  result := '';
  while (tmp > 0) do
  begin
    result := char((tmp mod 10)+Ord('0')) + result;
    inc(len);
    tmp := tmp div 10;

    if (len mod 3 = 0) and (tmp > 0) then
      result := LIMITER+result;
  end;

  result := currency+' '+result; //increase readability
end;

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

