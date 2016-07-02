{
  formproduct.pas
  :: handles displaying and removing product.
}

unit formproduct;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  sqldb, LCLType, StdCtrls;

type

  { TfrmProduct }

  TfrmProduct = class(TForm)
    Button1: TButton;
    btnRemove: TButton;
    btnEdit: TButton;
    lvProduct: TListView;
    procedure btnEditClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure lvProductClick(Sender: TObject);
  private
    { private declarations }
  public
    procedure LoadData;
  end;

var
  frmProduct: TfrmProduct;

implementation

{$R *.lfm}

{ TfrmProduct }

uses
  lib.database, FormLogin, FormAddProduct, FormMain, lib.Common;

procedure TfrmProduct.LoadData;
var
  query: TSQLQuery;
  Item: TListItem;
begin
  btnEdit.Visible := False;
  btnRemove.Visible := False;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product` WHERE `active` = 1';
  query.Open;

  lvProduct.Clear;
  while (not query.EOF) do
  begin
    Item := TListItem.Create(lvProduct.Items);
    Item.Caption := query.FieldByName('id').AsString;
    Item.SubItems.Add(query.FieldByName('name').AsString);
    Item.SubItems.Add(query.FieldByName('typename').AsString);
    Item.SubItems.Add(query.FieldByName('description').AsString);
    lvProduct.Items.AddItem(item);
    query.Next;
  end;
  lvProductClick(nil);

  query.Close;
  query.Free;
end;

procedure TfrmProduct.FormShow(Sender: TObject);
begin
  LoadData;
  Button1.enabled := (CurrentSession.Authority and AUTH_EDIT_PRODUCT) > 0;
end;

procedure TfrmProduct.lvProductClick(Sender: TObject);
var
  can: boolean;
begin
  can := (CurrentSession.Authority and AUTH_EDIT_PRODUCT) > 0;
  btnEdit.Visible := (lvProduct.ItemIndex <> -1) and can;
  btnRemove.Visible := (lvProduct.ItemIndex <> -1) and can;
end;

procedure TfrmProduct.Button1Click(Sender: TObject);
begin
  frmAddProduct.ID := '';
  frmAddProduct.Show;
end;

procedure TfrmProduct.btnEditClick(Sender: TObject);
begin
  frmAddProduct.ID := lvProduct.ItemFocused.Caption;
  frmAddProduct.Show;
end;

procedure TfrmProduct.btnRemoveClick(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  ret := Application.MessageBox(
    PChar(Format('Apakah anda yakin untuk menghapus produk %s?',
    [lvProduct.ItemFocused.SubItems[0]])),
    'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if ret = ID_YES then
  begin
    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'UPDATE `product` SET `active` = 0 WHERE `id` = :id';
    query.ParamByName('id').AsString := lvProduct.ItemFocused.Caption;
    query.ExecSQL;

    frmLogin.dbCoreTransaction.Commit;
    query.Free;

    LoadData;
  end;
end;

procedure TfrmProduct.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := True;
end;

end.
