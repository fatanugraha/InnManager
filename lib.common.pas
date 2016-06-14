unit lib.common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, md5, LCLType, dateutils;

const
  //required filenames
  FILE_COREDB = 'core.sqlite3';
  FILE_DRIVER = 'sqlite3.dll';
  FILE_CUSTOMERS = 'customers.sqlite3';
  FILE_ORDERS = 'orders.sqlite3';
  FILE_INV_ADV = 'advance_receipt.lrf';
  FILE_INV_FULL = 'full_receipt.lrf';

  //salt for hashing
  SALT_PREFIX = 'kucing_';
  SALT_SUFFIX = '_terbang';

  //application name
  APP_NAME = 'PSBB MAN 3 Malang';

  //user authority bitmask
  AUTH_SEE_PRODUCT = 1;
  AUTH_EDIT_PRODUCT = 2;
  AUTH_SEE_USER = 4;
  AUTH_EDIT_USER = 8;

  //date auxiliary data
  DAY_IN_MONTH = 7;
  MONTH_IN_YEAR = 12;

  MONTH_SIZE: array [0..MONTH_IN_YEAR - 1] of integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
  MONTH_IDN: array [0..MONTH_IN_YEAR - 1] of string = ('Januari', 'Februrari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember');

  DAY_ENG: array [0..DAY_IN_MONTH - 1] of string = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
  DAY_IDN: array [0..DAY_IN_MONTH - 1] of string = ('Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu');

  //orders bitmask in base4
  ORDERS_BOOKED = 1;
  ORDERS_CHECKIN = 2;
  ORDERS_CHECKOUT = 3;

  ORDERS_ZERO = 1;
  ORDERS_PARTIAL = 2;
  ORDERS_FULL = 3;

//check if core files is exists
function VerifyFiles: integer;
//get current working directory
function CurrentDir: string;
//check is current TEdit is empty and set focus to it if empty
function IsFieldEmpty(Sender: TObject): boolean;
//hash current password with MD5 + added some salt
function HashPassword(password: string): string;
//format current integer to more readable format
function GroupDigits(x: int64): string;
//reverse GroupDigits(x) function
function UngroupDigits(x: string): int64;

//check is this year is leap TODO: REMOVE, exists in dateutils
function IsLeapYear(year: integer): boolean;
//convert current day from string (Only supported ID and EN locale) to 0-based integer
function TokenizeDay(day: string): integer;
//check is A..B intersects with X..Y
function IsDateIntersect(A, B, X, Y: TDateTime): boolean;

implementation

uses
  lib.logger;

function isDateIntersect(A, B, X, Y: TDateTime): boolean;
begin
  if (CompareDate(A, X) = 0) or (CompareDate(A, Y) = 0) then
    exit(True);
  if (CompareDate(B, X) = 0) or (CompareDate(B, Y) = 0) then
    exit(True);

  if (CompareDate(A, X) < 0) and (CompareDate(X, B) < 0) then
    exit(True);
  if (CompareDate(A, Y) < 0) and (CompareDate(Y, B) < 0) then
    exit(True);

  if (CompareDate(X, A) < 0) and (CompareDate(B, Y) < 0) then
    exit(True);
  if (CompareDate(A, X) < 0) and (CompareDate(Y, B) < 0) then
    exit(True);

  Result := False;
end;

function TokenizeDay(day: string): integer;
var
  i: integer;
begin
  for i := 0 to 6 do
    if (DAY_ENG[i] = day) or (DAY_IDN[i] = day) then
      exit(i);

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

function GroupDigits(x: int64): string;
const
  LIMITER = ',';
var
  len: integer;
  tmp: int64;
  neg: boolean;
begin
  neg := x < 0;
  x := abs(x);

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

  if (Result = '') then
    Result := '0';

  if (neg) then
    Result := '-' + Result;
end;

function UngroupDigits(x: string): int64;
var
  i: integer;
  neg: boolean;
begin
  Result := 0;
  neg := False;

  for i := 1 to length(x) do
  begin
    if ('0' <= x[i]) and (x[i] <= '9') then
      Result := Result * 10 + (Ord(x[i]) - Ord('0'));
    if (x[i] = '-') then
      neg := True;
  end;

  if (neg) then
    Result := -1 * Result;
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
  if (not FileExists(CurrentDir + FILE_COREDB)) then
    exit(1);

  if (not FileExists(CurrentDir + FILE_DRIVER)) then
    exit(2);

  if (not FileExists(CurrentDir + FILE_CUSTOMERS)) then
    exit(3);

  if (not FileExists(CurrentDir + FILE_ORDERS)) then
    exit(4);

  if (not FileExists(CurrentDir + FILE_INV_ADV)) then
    exit(5);

  if (not FileExists(CurrentDir + FILE_INV_FULL)) then
    exit(7);

  exit(0);
end;

end.
