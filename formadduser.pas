unit formAddUser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LCLType, sqldb;

type

  { TfrmAddUser }

  TfrmAddUser = class(TForm)
    btnSave: TButton;
    Button1: TButton;
    CheckGroup1: TCheckGroup;
    edtUsername: TLabeledEdit;
    edtName: TLabeledEdit;
    edtPassword: TLabeledEdit;
    procedure btnSaveClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    ID: string;
  end;

var
  frmAddUser: TfrmAddUser;

implementation

{$R *.lfm}

{ TfrmAddUser }

uses
  lib.database, FormLogin, lib.Common, FormUser, lib.logger;

procedure TfrmAddUser.FormCreate(Sender: TObject);
begin

end;

procedure TfrmAddUser.FormShow(Sender: TObject);
var
  query: TSQLQuery;
  i, auth: integer;
begin
  edtPassword.Text := '';

  if (id = '') then
  begin
    edtUsername.Text := '';
    edtName.Text := '';
    checkgroup1.Checked[0] := True;
    checkgroup1.Checked[1] := False;
    checkgroup1.Checked[2] := False;
    checkgroup1.Checked[3] := False;
  end
  else
  begin
    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'SELECT * FROM `users` WHERE `id` = :id';
    query.ParamByName('id').AsString := ID;
    query.Open;

    edtUserName.Text := query.FieldByName('username').AsString;
    edtName.Text := query.FieldByName('fullname').AsString;

    auth := query.FieldByName('authority').AsInteger;

    for i := 0 to checkgroup1.Items.Count - 1 do
    begin
      checkgroup1.Checked[i] := (auth and (1 shl i)) > 0;
    end;

    query.Close;
    query.Free;
  end;
  checkgroup1.Enabled := id <> '1';
end;

procedure TfrmAddUser.btnSaveClick(Sender: TObject);
var
  query: TSQLQuery;
  auth, i: integer;
begin
  //pastikan gaada yang kosong
  if (IsFieldEmpty(edtUsername)) then
    exit;

  if (IsFieldEmpty(edtName)) then
    exit;

  if (ID = '') and (IsFieldEmpty(edtPassword)) then
    exit;

  //buat bitmask authoritynya
  auth := 0;
  for i := 0 to checkgroup1.Items.Count - 1 do
    if (checkgroup1.Checked[i]) then
      auth := auth or (1 shl i);

  if ((auth and AUTH_EDIT_PRODUCT) > 0) then
    auth := auth or AUTH_SEE_PRODUCT;

  if ((auth and AUTH_EDIT_USER) > 0) then
    auth := auth or AUTH_SEE_USER
  else if (auth and AUTH_SEE_USER) > 0 then
    auth := auth xor AUTH_SEE_USER; //flip nih bit gaguna seriusan

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);

  if (ID = '') then //buat baru
  begin
    //cek udah ada usernamenya ngga

    query.SQL.Text := 'SELECT * FROM `users` WHERE `username` = :username';
    query.ParamByName('username').AsString := lowercase(edtUsername.Text);
    query.Open;

    if (not query.EOF) then //user udah ada
    begin
      query.Close;

      Application.MessageBox('Username telah terdaftar. Gunakan username lain.', 'Username Sudah Ada',
        MB_ICONEXCLAMATION);
      edtUsername.SetFocus;
    end
    else
    begin
      //user gaada
      query.Close;

      //tambahin ke database
      query.sql.Text := 'INSERT INTO `users` (`username`, `password`, `authority`, `lastlogin`, `fullname`) ' +
        'VALUES (:username, :password, :authority, :lastlogin, :fullname)';
      query.ParamByName('username').AsString := lowercase(edtUsername.Text);
      query.ParamByName('password').AsString := HashPassword(edtPassword.Text);
      query.paramByName('authority').AsInteger := auth;
      query.ParamByName('lastlogin').AsString := '-';
      query.paramByName('fullname').AsString := edtName.Text;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      Application.MessageBox('User berhasil ditambahkan.', 'Sukses', MB_ICONINFORMATION);
      Close;
    end;
  end
  else
  begin //edit doang
    //cek dulu usernamenya bentrok ga?
    query.SQL.Text := 'SELECT * FROM `users` WHERE `username` = :username AND `id` != :id';
    query.ParamByName('id').AsString := id;
    query.ParamByName('username').AsString := lowercase(edtUsername.Text);
    query.Open;

    if (not query.EOF) then //user udah ada
    begin
      query.Close;

      Application.MessageBox('Username telah terdaftar. Gunakan username lain.', 'Username Sudah Ada',
        MB_ICONEXCLAMATION);
      edtUsername.SetFocus;

    end
    else
    begin
      //update woi ke database
      if (edtPassword.Text <> '') then
      begin
        query.sql.Text := 'UPDATE `users` SET `username` = :username, `password` = :password, `authority` = :authority, '
          + '`fullname` = :fullname WHERE `id` = :id';

        query.ParamByName('password').AsString := HashPassword(edtPassword.Text);
      end
      else
        query.sql.Text := 'UPDATE `users` SET `username` = :username, `authority` = :authority, ' +
          '`fullname` = :fullname WHERE `id` = :id';

      query.ParamByName('id').AsString := ID;
      query.ParamByName('username').AsString := lowercase(edtUsername.Text);
      query.paramByName('authority').AsInteger := auth;
      query.paramByName('fullname').AsString := edtName.Text;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      Application.MessageBox('Data user berhasil diubah.', 'Sukses', MB_ICONINFORMATION);

      //cek kalau user yang sekarang affected
      if (IntToStr(CurrentSession.ID) = ID) then
      begin
        CurrentSession.Username := lowercase(edtUsername.Text);
        CurrentSession.Authority := auth;
        if (edtPassword.Text <> '') then
          currentSession.Password := HashPassword(edtPassword.Text);
        CurrentSession.FullName := edtName.Text;
      end;
      Close;
    end;
  end;

  query.Free;
end;

procedure TfrmAddUser.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddUser.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmUsers.lvUsersClick(nil);
  frmUsers.Enabled := True;
  frmUsers.LoadData;
end;

end.
