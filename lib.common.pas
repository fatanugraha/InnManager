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

  APP_NAME = 'PSBB MAN 3 Malang Reservation System';

  AUTH_SEE_PRODUCT = 1;
  AUTH_EDIT_PRODUCT = 2;
  AUTH_SEE_USER = 4;
  AUTH_EDIT_USER = 8;

  MONTH_SIZE: array [0..11] of integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  DAY_ENG   : array [0..6] of string   = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
  DAY_IDN   : array [0..6] of string   = ('Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu');

  //sesuai KBBI lol
  MONTH_IDN : array [0..11] of string  = ('Januari', 'Feburari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus',
                                          'September', 'Oktober', 'November', 'Desember');
  currency = 'Rp';

function VerifyFiles: integer;
function CurrentDir: string;
function IsFieldEmpty(Sender: TObject): boolean;
function HashPassword(password: string): string;
function FormatCurrency(currency: string; x: int64): string;

function IsLeapYear(year: integer): boolean;
function TokenizeDay(day: string): integer;
function IndonesianDay(day: string): string;

implementation

uses
  lib.logger;

function IndonesianDay(day: string): string;
var
  i: integer;
begin
  Result := day;
  for i := 0 to 6 do
    if (DAY_ENG[i] = day) then
      Result := DAY_IDN[i];
end;

function TokenizeDay(day: string):integer;
var
  i: integer;
begin
  for i := 0 to 6 do
  begin
    if (DAY_ENG[i] = day) or (DAY_IDN[i] = day) then
      exit(i);
  end;

  RaiseCriticalError('ERR01: Format waktu tidak diketahui. Harap kontak pengembang aplikasi', 1);
end;

function IsLeapYear(year: integer): boolean;
begin
  if (year mod 4 <> 0) then
    Result := False
  else if (year mod 100 <> 0) then
    Result := True
  else if (year mod 400 <> 0) then
    Result := False
  else
    Result := True;
end;

function FormatCurrency(currency: string; x: int64): string;
const
  LIMITER = ',';
var
  len: integer;
  tmp: int64;
begin
  tmp := x;
  len := 0;

  Result := '';
  while (tmp > 0) do
  begin
    Result := char((tmp mod 10) + Ord('0')) + Result;
    Inc(len);
    tmp := tmp div 10;

    if (len mod 3 = 0) and (tmp > 0) then
      Result := LIMITER + Result;
  end;

  Result := currency + ' ' + Result; //increase readability
end;

function HashPassword(password: string): string;
begin
  Result := md5print(md5string(format('%s%s%s', [SALT_PREFIX, password, SALT_SUFFIX])));
end;

function IsFieldEmpty(Sender: TObject): boolean;
begin
  Result := Trim(TEdit(Sender).Text) = '';
  if (Result) then
  begin
    Application.MessageBox('Isi field yang diperlukan.', 'Field Kosong', MB_ICONEXCLAMATION);
    TEdit(Sender).SetFocus;
  end;
end;

function CurrentDir: string;
begin
  Result := IncludeTrailingBackslash(ExtractFilePath(Application.Exename));
end;

function VerifyFiles: integer;
begin
  //chcek coredb
  if (not FileExists(CurrentDir + FILE_COREDB)) then
    exit(1);

  if (not FileExists(CurrentDir + FILE_DRIVER)) then
    exit(2);

  //check reservation data here
  exit(0);
end;

end.
