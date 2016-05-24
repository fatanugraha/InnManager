unit formAddProduct;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, sqldb, LCLType,
  StdCtrls;

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

var
  tmp: TStringList;

procedure TfrmAddProduct.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddProduct.Button1Click(Sender: TObject);
var
  query: TSQLQuery;
begin
  //validate
  if (isFieldEmpty(edtName)) then
    exit;

  if (cbType.ItemIndex = -1) then
  begin
    application.MessageBox('Jenis produk belum ditentukan.', 'Field Kosong', MB_ICONEXCLAMATION);
    exit;
  end;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  if (id = '') then
  begin
    //cek dulu namanya ada ngga
    query.SQL.Text := 'SELECT * FROM `product` WHERE LOWER(`name`) = :name';
    query.ParamByName('name').AsString := lowercase(edtName.Text);
    query.Open;

    if (not query.eof) then //disini
    begin
      query.close;
      Application.MessageBox('Jenis produk telah ada di database.', 'Jenis Produk Sudah Ada', MB_ICONEXCLAMATION);
      edtName.SetFocus;
    end else begin
      query.close;

      query.SQL.Text := 'INSERT INTO `product` (`name`, `typename`, `description`) VALUES (:name, :typename, :desc)';
      query.ParamByName('name').AsString := edtName.Text;
      query.ParamByName('typename').AsString := cbType.Text;
      query.ParamByName('desc').AsString := mmDesc.Text;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      frmProduct.LoadData;
      Close;
    end;
  end else begin
    query.SQL.Text := 'SELECT * FROM `product` WHERE LOWER(`name`) = :name AND `id` != :id';
    query.ParamByName('name').AsString := lowercase(edtName.Text);
    query.ParamByName('id').AsString := ID;
    query.Open;

    if (not query.eof) then //disini
    begin
      query.close;
      Application.MessageBox('Jenis produk telah ada di database.', 'Jenis Produk Sudah Ada', MB_ICONEXCLAMATION);
      edtName.SetFocus;
    end else begin
      query.close;

      query.SQL.Text := 'UPDATE `product` SET `name` = :name, `typename` = :typename, `description` = :desc WHERE `id` = :id';
      query.ParamByName('id').AsString := ID;
      query.ParamByName('name').AsString := edtName.Text;
      query.ParamByName('typename').AsString := cbType.Text;
      query.ParamByName('desc').AsString := mmDesc.Text;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      frmProduct.LoadData;
      Close;
    end;
  end;
  query.free;
end;

procedure TfrmAddProduct.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
  tmp.free;
end;

procedure TfrmAddProduct.FormShow(Sender: TObject);
var
  query: TSQLQuery;
  i: integer;
begin
  tmp := TStringList.Create;

  edtName.Text := '';
  cbType.Clear;
  mmDesc.Text := '';

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT `id`, `name` FROM `product_type`';
  query.Open;

  while (not query.eof) do
  begin
    tmp.Add(query.FieldByName('id').AsString);
    cbType.Items.Add(query.FieldByName('name').AsString);
    query.next;
  end;

  query.close;

  caption := 'Tambahkan Produk';
  if (id <> '') then
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
  end;
  query.free;
end;

end.

