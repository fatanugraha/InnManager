program innManager;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, formLogin, lib.database, lib.common, lib.logger, formmain, formuser,
  formAddUser, formproduct, formtype, formaddtype;

{$R *.res}

begin
  InitLogger;

  //cek semua file ada atau ngga
  case (VerifyFiles) of
  1: RaiseCriticalError('DB01: database inti tidak ditemukan', 1);
  2: RaiseCriticalError('DB02: driver database sqlite3 tidak ditemukan', 1);
  end;

  //passed all checkpoint
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmUsers, frmUsers);
  Application.CreateForm(TfrmAddUser, frmAddUser);
  Application.CreateForm(TfrmProduct, frmProduct);
  Application.CreateForm(TfrmType, frmType);
  Application.CreateForm(TfrmAddType, frmAddType);
  Application.Run;
end.

