unit formproduct;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, sqldb, LCLType,
  StdCtrls;

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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lvProductClick(Sender: TObject);
    procedure lvProductCompare(Sender: TObject; Item1, Item2: TListItem; Data: integer; var Compare: integer);
    procedure lvProductSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
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
  lib.database, FormLogin, FormAddProduct, FormMain;

procedure TfrmProduct.LoadData;
var
  query: TSQLQuery;
  Item: TListItem;
begin
  btnEdit.Visible := False;
  btnRemove.Visible := False;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product`';
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

procedure TfrmProduct.FormCreate(Sender: TObject);
begin

end;

procedure TfrmProduct.FormShow(Sender: TObject);
begin
  btnEdit.Visible := false;
  btnRemove.Visible := false;

  LoadData;
end;

procedure TfrmProduct.lvProductClick(Sender: TObject);
begin
  if (lvProduct.ItemIndex = -1) then
  begin
    btnEdit.Visible := false;
    btnRemove.Visible := false;
  end;
end;

procedure TfrmProduct.Button1Click(Sender: TObject);
begin
  frmAddProduct.ID := '';
  frmAddProduct.Show;
  frmMain.Enabled := false;
end;

procedure TfrmProduct.btnEditClick(Sender: TObject);
begin
  frmAddProduct.ID := lvProduct.ItemFocused.Caption;
  frmAddProduct.Show;
  frmMain.Enabled := false;
end;

procedure TfrmProduct.btnRemoveClick(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  ret := Application.MessageBox(PChar(Format('Apakah anda yakin untuk menghapus produk %s?', [lvProduct.ItemFocused.SubItems[0]])), 'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if (ret = ID_YES) then
  begin
    //todo cek ada nggak reservasi atas produk yang mau dihapus

    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'DELETE FROM `product` WHERE `id` = :id';
    query.ParamByName('id').AsString := lvProduct.ItemFocused.Caption;
    query.ExecSQL;

    frmLogin.dbCoreTransaction.Commit;
    query.Free;


    Application.MessageBox(PChar(Format('Produk %s berhasil dihapus', [lvProduct.ItemFocused.SubItems[0]])),
      'Sukses', MB_ICONINFORMATION);
    LoadData;
  end;
end;

procedure TfrmProduct.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
end;

procedure TfrmProduct.lvProductCompare(Sender: TObject; Item1, Item2: TListItem; Data: integer; var Compare: integer);
begin

end;

procedure TfrmProduct.lvProductSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  btnRemove.Visible := true;
  btnEdit.Visible := true;
end;

end.


