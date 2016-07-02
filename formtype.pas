{
  formtype.pas
  :: handles remove and displaying product type.
}

unit formtype;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  sqldb, LCLType, StdCtrls;

type

  { TfrmType }

  TfrmType = class(TForm)
    btnAdd: TButton;
    btnEdit: TButton;
    btnRemove: TButton;
    lvType: TListView;
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure lvTypeClick(Sender: TObject);
  private
    { private declarations }
  public
    procedure LoadData;
  end;

var
  frmType: TfrmType;

implementation

{$R *.lfm}

{ TfrmType }

uses
  lib.database, FormLogin, lib.common, FormAddType, lib.logger, FormMain;

procedure TfrmType.LoadData;
var
  query: TSQLQuery;
  item: TListItem;
begin
  //tampilin aja dari db
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product_type` WHERE `active` = 1';
  query.Open;

  lvType.Clear;
  while (not query.EOF) do
  begin
    item := TListItem.Create(lvType.Items);
    item.Caption := query.FieldByName('id').AsString;
    item.SubItems.Add(query.FieldByName('Name').AsString);
    item.SubItems.Add(GroupDigits(query.FieldByName('price').AsInteger));
    item.SubItems.Add(query.FieldByName('feature').AsString);
    item.SubItems.Add(query.FieldByName('description').AsString);

    if (Trim(item.SubItems[2]) = '') then
      item.SubItems[2] := '-';
    if (Trim(item.SubItems[3]) = '') then
      item.SubItems[3] := '-';

    lvType.Items.AddItem(Item);

    query.Next;
  end;

  lvTypeClick(nil);
  query.Close;
  query.Free;
end;

procedure TfrmType.btnAddClick(Sender: TObject);
begin
  FrmAddType.ID := '';
  frmAddType.Show;
end;

procedure TfrmType.btnEditClick(Sender: TObject);
begin
  FrmAddType.ID := lvType.ItemFocused.Caption;
  frmAddType.Show;
end;

procedure TfrmType.btnRemoveClick(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  ret := Application.MessageBox(
    PChar(Format('Apakah anda yakin untuk menghapus jenis %s?' + LineEnding +
    'Semua produk yang berjenis %s juga akan dihapus.',
    [lvType.ItemFocused.SubItems[0], lvType.ItemFocused.SubItems[0]])),
    'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if (ret = ID_YES) then
  begin
    //tandai aja sebagai inactive
    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'UPDATE `product_type` SET `active` = 0 WHERE `id` = :id';
    query.ParamByName('id').AsString := lvType.ItemFocused.Caption;
    query.ExecSQL;

    query.SQL.Text := 'UPDATE `product` SET `active` = 0 WHERE `typename` = :id';
    query.ParamByName('id').AsString := lvType.ItemFocused.SubItems[0];
    query.ExecSQL;

    frmLogin.dbCoreTransaction.Commit;
    query.Free;
    LoadData;
  end;
end;

procedure TfrmType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := True;
end;

procedure TfrmType.FormShow(Sender: TObject);
begin
  LoadData;
  btnAdd.Enabled := (CurrentSession.Authority and AUTH_EDIT_PRODUCT) > 0;
end;

procedure TfrmType.lvTypeClick(Sender: TObject);
var
  can: boolean;
begin
  can := (CurrentSession.Authority and AUTH_EDIT_PRODUCT) > 0;
  btnRemove.Visible := (lvType.ItemIndex <> -1) and can;
  btnEdit.Visible := (lvType.ItemIndex <> -1) and can;
end;

end.
