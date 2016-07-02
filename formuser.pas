unit formuser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, FileUtil, LCLType,
  Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls, ExtCtrls,
  ComCtrls;

type

  { TfrmUsers }

  TfrmUsers = class(TForm)
    btnChangePwd: TButton;
    btnEdit: TButton;
    btnRemove: TButton;
    btnAdd: TButton;
    Button1: TButton;
    gbEditPassword: TGroupBox;
    edtVerify: TLabeledEdit;
    edtNew: TLabeledEdit;
    edtOld: TLabeledEdit;
    lvUsers: TListView;
    procedure btnAddClick(Sender: TObject);
    procedure btnChangePwdClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure lvUsersClick(Sender: TObject);
    procedure lvUsersSelectItem(Sender: TObject; Item: TListItem; Selected: boolean);
  private

  public
    procedure LoadData;
  end;

var
  frmUsers: TfrmUsers;

implementation

{$R *.lfm}

{ TfrmUsers }

uses
  lib.common, lib.database, FormLogin, lib.logger, FormAddUser, FormMain;

var
  canSee: boolean;
  canEdit: boolean;

const
  OFFSET = 8;
  DEFAULTW = 600;
  DEFAULTH = 400;

procedure TfrmUsers.LoadData;
var
  query: TSQLQuery;
  item: TListItem;
begin
  //load data
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM users';
  query.Open;

  lvUsers.Clear();
  lvUsers.ItemIndex := -1;

  while (not query.EOF) do
  begin
    item := TListItem.Create(lvUsers.Items);
    item.Caption := query.FieldByName('id').AsString;
    item.SubItems.Add(query.FieldByName('username').AsString);
    item.SubItems.Add(query.FieldByName('fullname').AsString);
    item.SubItems.Add(query.FieldByName('lastlogin').AsString);
    lvUsers.Items.AddItem(item);

    query.Next;
  end;

  lvUsersClick(nil);
  query.Close;
  query.Free;
end;

procedure TfrmUsers.FormShow(Sender: TObject);
begin
  if (CurrentSession.Authority and AUTH_EDIT_USER) > 0 then
    Caption := Format('%s | %s', [APP_NAME, 'Atur Pengguna'])
  else
    Caption := Format('%s | %s', [APP_NAME, 'Ganti Password']);

  frmMain.Enabled := false;

  canSee := (CurrentSession.Authority and AUTH_SEE_USER) > 0;
  canEdit := (CurrentSession.Authority and AUTH_EDIT_USER) > 0;

  //cosmetics
  lvUsers.Visible := False;
  btnEdit.Visible := False;
  btnRemove.Visible := False;
  btnAdd.Visible := False;
  gbEditPassword.Visible := False;

  edtOld.Text := '';
  edtVerify.Text := '';
  edtNew.Text := '';

  if (not CanSee) and (not CanEdit) then
  begin
    gbEditPassword.Visible := True;
    gbEditPassword.Left := OFFSET;
    gbEditPassword.Top := OFFSET;
    Width := gbEditPassword.Width + 2 * OFFSET;
    Height := gbEditPassword.Height + 2 * OFFSET;
    BorderStyle := bsSingle;
  end
  else
  begin
    lvUsers.Visible := True;
    if (CanEdit) then
    begin
      btnAdd.Visible := True;
      Height := DEFAULTH + 3 * OFFSET + btnAdd.Height;
      Width := DEFAULTW + 3 * OFFSET;
    end
    else
    begin
      Height := DEFAULTH + 2 * OFFSET;
      Width := DEFAULTW + 2 * OFFSET;
    end;

    lvUsers.Height := DEFAULTH;
    LoadData;
  end;
end;

procedure TfrmUsers.lvUsersClick(Sender: TObject);
begin
  if (lvUsers.ItemIndex = -1) then
  begin
    btnRemove.Visible := False;
    btnEdit.Visible := False;
  end;
end;

procedure TfrmUsers.lvUsersSelectItem(Sender: TObject; Item: TListItem; Selected: boolean);
begin
  btnRemove.Visible := (Item.Caption <> '1');
  btnEdit.Visible := True;
end;

procedure TfrmUsers.btnEditClick(Sender: TObject);
begin
  if (lvUsers.ItemIndex = -1) then
  begin
    lvUsersClick(nil);
    exit;
  end;

  Enabled := False;

  frmAddUser.Caption := 'Ubah Data Pengguna';
  frmAddUser.ID := lvUsers.ItemFocused.Caption;
  frmAddUser.Show;
end;

procedure TfrmUsers.btnRemoveClick(Sender: TObject);
var
  query: TSQLQuery;
  act: integer;
begin
  if (lvUsers.ItemIndex = -1) then
  begin
    lvUsersClick(nil);
    exit;
  end;

  act := Application.MessageBox(PChar(Format('Apakah anda yakin untuk menghapus user %s?',
    [lvUsers.ItemFocused.SubItems[0]])), 'Hapus Pengguna', MB_ICONQUESTION or MB_YESNOCANCEL);

  if (ACT = ID_YES) then
  begin
    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'DELETE FROM `users` WHERE `id` = :id';
    query.ParamByName('id').AsString := lvUsers.ItemFocused.Caption;
    query.ExecSQl;
    frmLogin.dbCoreTransaction.Commit;

    LoadData;
    lvUsersClick(nil);
  end;

end;

procedure TfrmUsers.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmUsers.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

  frmMain.Enabled := true;
end;

procedure TfrmUsers.btnAddClick(Sender: TObject);
begin
  Enabled := False;

  frmAddUser.Caption := 'Tambahkan Pengguna';
  frmAddUser.ID := '';
  frmAddUser.Show;
end;

procedure TfrmUsers.btnChangePwdClick(Sender: TObject);
var
  query: TSQLQuery;
begin
  //cek kosong ngga
  if (IsFieldEmpty(edtOld)) then
    exit;

  if (IsFieldEmpty(edtNew)) then
    exit;

  if (IsFieldEmpty(edtVerify)) then
    exit;

  if (edtVerify.Text <> edtNew.Text) then
  begin
    application.MessageBox('Password yang anda masukkan tidak sama', 'Password Salah', MB_ICONEXCLAMATION);
    edtNew.SetFocus;
    exit;
  end;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  //cek passwordnya match ga?
  query.SQL.Text := 'SELECT * FROM `users` WHERE `id` = :id';
  query.ParamByName('id').AsInteger := CurrentSession.ID;
  query.Open;

  if (query.FieldByName('password').AsString <> HashPassword(edtOld.Text)) then
  begin
    Application.MessageBox('Passowrd lama salah. Mohon cek ulang password lama anda.',
      'Passowrd Salah', MB_ICONEXCLAMATION);
    edtOld.SetFocus;
    query.Close;
    query.Free;
    exit;
  end;

  query.SQL.Text := 'UPDATE `users` SET `password` = :password WHERE `username` = :username';
  query.ParamByName('username').AsString := CurrentSession.Username;
  query.ParamByName('password').AsString := HashPassword(edtVerify.Text);
  query.ExecSql;
  frmLogin.dbCoreTransaction.Commit;
  ;
  query.Free;

  Application.MessageBox('Password berhasil diperbarui.', 'Sukses', MB_ICONINFORMATION);
  Close;
end;

end.
