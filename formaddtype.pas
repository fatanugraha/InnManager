unit formaddtype;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, sqldb, lclType,
  MaskEdit, StdCtrls, ComCtrls;

type

  { TfrmAddType }

  TfrmAddType = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtName: TLabeledEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtPrice: TLabeledEdit;
    mmFeature: TMemo;
    mmDesc: TMemo;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edtPriceChange(Sender: TObject);
    procedure edtPriceKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    ID: string;
  end;

var
  frmAddType: TfrmAddType;

implementation

{$R *.lfm}

{ TfrmAddType }

uses
  lib.database, FormLogin, lib.common, FormType, lib.logger;

procedure TfrmAddType.FormShow(Sender: TObject);
var
  query: TSQLQuery;
begin
  edtName.Text := '';
  edtPrice.Text := '';
  mmFeature.Text := '';
  mmDesc.Text := '';

  Caption := 'Tambahkan Jenis Produk';

  if (id <> '') then begin
    Caption := 'Ubah Jenis Produk';
    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
    query.SQL.Text := 'SELECT * FROM `product_type` WHERE `id` = :id';
    query.ParamByName('id').AsString := id;
    query.Open;
    edtName.Text := query.FieldByName('name').AsString;
    edtprice.Text := query.FieldByName('price').AsString;
    mmFeature.Text := query.FieldByName('feature').AsString;
    mmDesc.Text := query.FieldByName('description').AsString;
    query.Close;
    query.Free;
  end;
end;

procedure TfrmAddType.btnOKClick(Sender: TObject);
var
  query : TSQLQuery;
begin
  //validate
  if (isFieldEmpty(edtName)) then
    exit;
  if (isFieldEmpty(edtPrice)) then
    exit;

  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  if (ID = '') then //tambahin
  begin
    //cek udah ada belom yang namanya sama
    query.SQL.Text := 'SELECT * FROM `product_type` WHERE LOWER(`name`) = :name';
    query.ParamByName('name').AsString := lowercase(edtName.Text);
    query.Open;

    if (not query.EOF) then
    begin
      query.close;
      Application.MessageBox('Jenis produk telah ada di database.', 'Jenis Produk Sudah Ada', MB_ICONEXCLAMATION);
      edtName.SetFocus;
    end else begin
      query.close;
      query.SQL.Text := 'INSERT INTO `product_type` (`name`, `price`, `feature`, `description`) VALUES (:name, :price, '+
                        ':feature, :description)';
      query.ParamByName('name').AsString := edtName.Text;
      query.ParamByName('price').AsString := edtPrice.Text;
      query.ParamByName('feature').AsString := mmFeature.Text;
      query.ParamByName('description').AsString := mmDesc.Text;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      Application.MessageBox('Jenis produk berhasil di tambahkan.', 'Sukses', MB_ICONINFORMATION);
      FrmType.LoadData;
      Close;
    end;
  end else begin //ganti cuy
    query.SQL.Text := 'SELECT * FROM `product_type` WHERE LOWER(`name`) = :name AND `id` != :id';
    query.ParamByName('name').AsString := lowercase(edtName.Text);
    query.ParamByName('id').AsString := ID;
    query.Open;

    if (not query.EOF) then
    begin
      query.close;
      Application.MessageBox('Jenis produk telah ada di database.', 'Jenis Produk Sudah Ada', MB_ICONEXCLAMATION);
      edtName.SetFocus;
    end else begin
      query.close;
      query.SQL.Text := 'UPDATE `product_type` SET `name` = :name, `price` = :price, `feature` = :feature, `description` = :description '+
                        'WHERE `id` = :id';
      query.ParamByName('name').AsString := edtName.Text;
      query.ParamByName('price').AsString := edtPrice.Text;
      query.ParamByName('feature').AsString := mmFeature.Text;
      query.ParamByName('description').AsString := mmDesc.Text;
      query.ParamByName('id').AsString := ID;
      query.ExecSQL;
      frmLogin.dbCoreTransaction.Commit;

      Application.MessageBox('Jenis produk berhasil di ubah.', 'Sukses', MB_ICONINFORMATION);
      FrmType.LoadData;
      Close;
    end;
  end;
  query.Free;
end;

procedure TfrmAddType.btnCancelClick(Sender: TObject);
begin
  close;
end;

procedure TfrmAddType.edtPriceChange(Sender: TObject);
begin

end;

procedure TfrmAddType.edtPriceKeyPress(Sender: TObject; var Key: char);
begin
  if not(('0' <= key) and (key <= '9') or (key = #8) or (key = #9)) then
  begin
    key := #0;
    exit;
  end;

  if (length(edtPrice.Text) = 8) and (('0' <= key) and (key <= '9')) then begin
     key := #0;
     exit;
  end;
end;

procedure TfrmAddType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmType.Enabled := true;
end;

end.

