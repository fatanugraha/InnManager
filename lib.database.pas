{
  lib.database.pas
  :: contains methods for database stuffs.
}

unit lib.database;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb;

//TODO: bikin crud

function CreateQuery(pConnection: TSQLConnection;
                     pTransaction: TSQLTransaction): TSQLQuery;

implementation

function CreateQuery(pConnection: TSQLConnection;
                     pTransaction: TSQLTransaction): TSQLQuery;
begin
  result := TSQLQuery.Create(nil);
  result.Database := pConnection;
  result.Transaction := pTransaction
end;
end.

