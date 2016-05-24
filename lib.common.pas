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

  DAY_IN_MONTH = 7;
  MONTH_IN_YEAR = 12;

  MONTH_SIZE: array [0..MONTH_IN_YEAR-1] of integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  MONTH_IDN:  array [0..MONTH_IN_YEAR-1] of string  = ('Januari', 'Feburari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
                                                       'Agustus', 'September', 'Oktober', 'November', 'Desember');

  DAY_ENG: array [0..DAY_IN_MONTH-1] of string = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
                                                  'Saturday');
  DAY_IDN: array [0..DAY_IN_MONTH-1] of string = ('Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu');

  CURRENCY = 'Rp';

//check if core files is exists
function VerifyFiles: integer;
//get current working directory
function CurrentDir: string;
//check is current TEdit is empty and set focus to it if empty
function IsFieldEmpty(Sender: TObject): boolean;
//hash current password with MD5 + added some salt
function HashPassword(password: string): string;
//format current integer to more readable format
function FormatCurrency(currency: string; x: int64): string;

//check is this year is leap
function IsLeapYear(year: integer): boolean;
//convert current day from string (Only supported ID and EN locale) to 0-based integer
function TokenizeDay(day: string): integer;

implementation

uses
  lib.logger;

function TokenizeDay(day: string): integer;
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

  //check sqlite driver
  if (not FileExists(CurrentDir + FILE_DRIVER)) then
    exit(2);

  //check reservation data here
  exit(0);
end;

end.
