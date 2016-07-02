{
  formaddproduct.pas
  :: handles adding or removing product.
}

unit formAddProduct;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  sqldb, LCLType, StdCtrls;

type

  { TfrmAddProduct }

  TfrmAddProduct = class(TForm)
    Button1: TButton;
    Button2: TButton;
    cbType: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    edtName: TLabeledEdit;
    mmDesc: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    ID: string;
  end;

var
  frmAddProduct: TfrmAddProduct;

implementation

{$R *.lfm}

{ TfrmAddProduct }

uses
  lib.database, FormLogin, lib.logger, lib.common, FormProduct, FormMain;

procedure TfrmAddProduct.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddProduct.Button1Click(Sender: TObject);
var
  query: TSQLQuery;
  Exists: boolean;
begin
  //validate
  if isFieldEmpty(edtName) then
    exit;

  if cbType.ItemIndex = -1 then
  begin
    application.MessageBox('Jenis produk belum ditentukan.', 'Field Kosong',
                           MB_ICONEXCLAMATION);
    exit;
  end;

  //cek dulu namanya ada ngga
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product` WHERE LOWER(`name`) = :name AND '+
                    '`active` = 1 ';
  query.ParamByName('name').AsString := lowercase(edtName.Text);

  if ID <> '' then
  begin
    query.SQL.Text := query.SQL.Text + 'AND `id` != :id';
    query.ParamByName('id').AsString := ID;
  end;

  query.Open;
  Exists := not query.EOF;
  query.close;

  if Exists then
  begin
    Application.MessageBox('Produk telah ada di database.', 'Produk Sudah Ada',
                            MB_ICONEXCLAMATION);
    edtName.SetFocus;
    exit;
  end;

  //update database
  if id = '' then
  begin
    //tambahin
    query.SQL.Text := 'INSERT INTO `product` (`name`, `typename`, `description`) '+
                      'VALUES (:name, :typename, :desc)';

    query.ParamByName('name').AsString := edtName.Text;
    query.ParamByName('typename').AsString := cbType.Text;
    query.ParamByName('desc').AsString := mmDesc.Text;

    query.ExecSQL;
  end else begin
    query.SQL.Text := 'UPDATE `product` SET `name` = :name, '+
                      '`typename` = :typename, `description` = :desc '+
                      'WHERE `id` = :id';

    query.ParamByName('id').AsString := ID;
    query.ParamByName('name').AsString := edtName.Text;
    query.ParamByName('typename').AsString := cbType.Text;
    query.ParamByName('desc').AsString := mmDesc.Text;

    query.ExecSQL;
  end;
  frmLogin.dbCoreTransaction.Commit;
  query.free;

  frmProduct.LoadData;
  Close;
end;

procedure TfrmAddProduct.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
end;

procedure TfrmAddProduct.FormShow(Sender: TObject);
var
  query: TSQLQuery;
  i: integer;
begin
  frmMain.Enabled := false;

  Caption := Format('%s | %s', [APP_NAME, 'Tambahkan Produk']);

  edtName.Text := '';
  cbType.Clear;
  mmDesc.Text := '';

  //tampilin jenis produk yang masih aktif
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT `id`, `name` FROM `product_type` WHERE `active` = 1';
  query.Open;

  while not query.eof do
  begin
    cbType.Items.Add(query.FieldByName('name').AsString);
    query.next;
  end;

  query.close;

  if id <> '' then
  begin
    caption := 'Ubah Produk';
    query.SQL.Text := 'SELECT * FROM `product` WHERE `id` = :id';
    query.ParamByName('id').AsString := id;
    query.Open;
    edtName.Text := query.fieldbyname('name').AsString;
    mmDesc.text := query.fieldbyname('description').AsString;

    for i := 0 to cbType.Items.Count-1 do
    begin
      if cbType.Items[i] = query.fieldbyname('typename').AsString then
      begin
        cbType.ItemIndex := i;
        break;
      end;
    end;
  end else
    caption := 'Tambahkan Produk';

  query.free;
end;

end.

