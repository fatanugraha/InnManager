unit lib.database;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb;

function CreateQuery(pConnection: TSQLConnection; pTransaction: TSQLTransaction): TSQLQuery;

implementation

function CreateQuery(pConnection: TSQLConnection; pTransaction: TSQLTransaction): TSQLQuery;
begin
  result := TSQLQuery.Create(nil);
  result.Database := pConnection;
  result.Transaction := pTransaction
end;
end.

