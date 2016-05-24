unit formLogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, FileUtil, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, LCLType, md5;

type

  { TfrmLogin }
  TfrmLogin = class(TForm)
    btnLogin: TButton;
    edtUserName: TEdit;
    edtPassword: TEdit;
    Label1: TLabel;
    dbCoreConnection: TSQLite3Connection;
    dbCoreTransaction: TSQLTransaction;
    procedure btnLoginClick(Sender: TObject);
    procedure edtPasswordExit(Sender: TObject);
    procedure edtUserNameEnter(Sender: TObject);
    procedure edtUserNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TSession = record
    FullName: string;
    Username: string;
    Authority, ID: integer;
    Password: string;
  end;

var
  frmLogin: TfrmLogin;
  CurrentSession: TSession; //Active Session Data

implementation

{$R *.lfm}

{ TfrmLogin }

uses
  lib.common, lib.logger, lib.database, formmain;

procedure TfrmLogin.edtUserNameEnter(Sender: TObject);
begin
  if (TEdit(Sender).Font.Color = clGray) then
  begin
    TEdit(Sender).Text := '';
    TEdit(Sender).Font.Color := clBlack;

    if (Sender = edtPassword) then
      TEdit(Sender).PasswordChar := '*';
  end;
end;

procedure TfrmLogin.edtUserNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 13) then
    btnLogin.Click;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  //keep alive aja yah
  dbCoreConnection.DatabaseName:= CurrentDir+FILE_COREDB;
  dbCoreConnection.Connected := true;

  //cosmetics
  Caption := Format('%s | Log Masuk', [APP_NAME]);
end;

procedure TfrmLogin.edtPasswordExit(Sender: TObject);
begin
  if (TEdit(Sender).Caption = '') then
  begin
    if (Sender = edtPassword) then
      TEdit(Sender).Text := 'password'
    else
      TEdit(Sender).Text := 'username';

    TEdit(Sender).Font.Color := clGray;

    if (Sender = edtPassword) then
      TEdit(Sender).PasswordChar := #0;
  end;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
var
  query: TSQLQuery;
  hash: string;
begin
  //pastikan udah keisi semua
  if (edtUsername.Font.Color = clGray) or (Trim(edtUsername.Text) = '') then
  begin
    Application.MessageBox('Username belum di isi.', 'Log Masuk', MB_ICONEXCLAMATION);
    edtUsername.setfocus;
    exit;
  end;

  if (edtPassword.Font.Color = clGray) or (Trim(edtPassword.Text) = '') then
  begin
    Application.MessageBox('Username belum di isi.', 'Log Masuk', MB_ICONEXCLAMATION);
    edtPassword.setfocus;
    exit;
  end;

  //query username dan password
  query := CreateQuery(dbCoreConnection, dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `users` WHERE `username` = :username LIMIT 1';
  query.params.ParamByName('username').AsString := lowercase(edtUsername.Text);
  query.Open;

  if (query.EOF) then
  begin
    //username gaada
    Application.MessageBox('Username tidak tersedia.', 'Log Masuk', MB_ICONEXCLAMATION);
    edtUserName.SetFocus;
  end
  else
  begin
    hash := HashPassword(edtPassword.Text);
    if (query.FieldByName('password').AsString = hash) then
    begin
      CurrentSession.FullName := query.FieldByName('fullname').AsString;
      CurrentSession.UserName := query.FieldByName('username').AsString;
      CurrentSession.Authority := query.FieldByName('authority').AsInteger;
      CurrentSession.Password := query.FieldByName('password').AsString;
      CurrentSession.ID := query.FieldByName('ID').AsInteger;
      dbCoreConnection.ExecuteDirect(Format('UPDATE `users` SET `lastlogin` = ''%s'' WHERE `id` = %d',
                                            [DateTimeToStr(Now), query.FieldByName('id').AsInteger]));
      dbCoreTransaction.Commit;
      frmMain.Show;
      hide;
    end
    else
    begin
      //password salah
      Application.MessageBox('Password salah.', 'Log Masuk', MB_ICONEXCLAMATION);
      edtPassword.SetFocus;
    end;
  end;

  query.close;
  query.Free;
end;

end.

