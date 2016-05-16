unit lib.common;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms;

function VerifyFiles: integer;
function CurrentDir: string;

const
  FILE_COREDB = 'core.sqlite3';
  FILE_DRIVER = 'sqlite3.dll';

  SALT_PREFIX = 'kucing_';
  SALT_SUFFIX = '_terbang';

  APP_NAME    = 'PSBB MAN 3 Malang Reservation System';

implementation

uses
  lib.logger;

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

