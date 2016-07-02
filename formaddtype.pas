{
  formaddtype.pas
  :: handles adding and editing product type.
}

unit formaddtype;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  sqldb, lclType, StdCtrls;

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
  lib.logger, lib.database, lib.common, FormLogin, FormType, FormMain;

var
  prev: string;

procedure TfrmAddType.FormShow(Sender: TObject);
var
  query: TSQLQuery;
begin
  frmMain.Enabled := true;

  edtName.Text := '';
  edtPrice.Text := '';
  mmFeature.Text := '';
  mmDesc.Text := '';

  if (id <> '') then begin //edit product type
    Caption := Format('%s | %s', [APP_NAME, 'Ubah Jenis Produk']);

    query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);

    query.SQL.Text := 'SELECT * FROM `product_type` WHERE `id` = :id';
    query.ParamByName('id').AsString := id;
    query.Open;

    edtName.Text   := query.FieldByName('name').AsString;
    prev           := query.FieldByName('name').AsString;
    edtprice.Text  := query.FieldByName('price').AsString;
    mmFeature.Text := query.FieldByName('feature').AsString;
    mmDesc.Text    := query.FieldByName('description').AsString;

    query.Close;
    query.Free;
  end else
    Caption := Format('%s | %s', [APP_NAME, 'Tambahkan Jenis Produk']);
end;

procedure TfrmAddType.btnOKClick(Sender: TObject);
var
  query: TSQLQuery;
  Exists: boolean;
begin
  //validate
  if (isFieldEmpty(edtName)) then
    exit;
  if (isFieldEmpty(edtPrice)) then
    exit;

  //cek dulu udah ada yang namanya sama dengan sekarang ato ngga
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT * FROM `product_type` WHERE LOWER(`name`) = :name '+
                    'AND `active` = 1 ';
  query.ParamByName('name').AsString := lowercase(edtName.Text);

  if ID <> '' then
  begin
    query.SQL.Text := query.SQL.Text + 'AND `id` != :id';
    query.ParamByName('id').AsString := ID;
  end;

  query.Open;
  Exists := not query.EOF;
  query.Close;

  //udah ada di database
  if Exists then
  begin
    query.close;
    Application.MessageBox('Jenis produk telah ada di database.',
                           'Jenis Produk Sudah Ada', MB_ICONEXCLAMATION);
    edtName.SetFocus;
    exit;
  end;

  //update ke database
  if ID = '' then
  begin
    //tambahin
    query.SQL.Text := 'INSERT INTO `product_type` (`name`, `price`, `feature`, '+
                      '`description`) VALUES (:name, :price, :feature, '+
                      ':description)';

    query.ParamByName('name').AsString        := edtName.Text;
    query.ParamByName('price').AsInteger      := UnGroupDigits(edtPrice.Text);
    query.ParamByName('feature').AsString     := mmFeature.Text;
    query.ParamByName('description').AsString := mmDesc.Text;

    query.ExecSQL;
  end
  else
  begin
    //update
    query.SQL.Text := 'UPDATE `product_type` SET `name` = :name, `price` = :price,'+
                      '`feature` = :feature, `description` = :description '+
                      'WHERE `id` = :id';

    query.ParamByName('name').AsString        := edtName.Text;
    query.ParamByName('price').AsInteger      := UnGroupDigits(edtPrice.Text);
    query.ParamByName('feature').AsString     := mmFeature.Text;
    query.ParamByName('description').AsString := mmDesc.Text;
    query.ParamByName('id').AsString          := ID;

    query.ExecSQL;

    //TODO: should we change this refer to id, not by name?

    if (prev <> edtName.Text) then begin
      query.SQL.Text := 'UPDATE `product` SET `typename` = :new '+
                        'WHERE `typename` = :old';

      query.ParamByName('old').AsString := prev;
      query.ParamByName('new').AsString := edtName.Text;

      query.ExecSQL;
    end;
  end;
  frmLogin.dbCoreTransaction.Commit;
  query.Free;

  FrmType.LoadData;
  Close;
end;

procedure TfrmAddType.edtPriceChange(Sender: TObject);
begin
  TEdit(Sender).Text     := GroupDigits(UnGroupDigits(TEdit(Sender).Text));
  TEdit(sender).SelStart := Length(TEdit(Sender).Text);
end;

procedure TfrmAddType.btnCancelClick(Sender: TObject);
begin
  close;
end;

procedure TfrmAddType.edtPriceKeyPress(Sender: TObject; var Key: char);
begin
  //reject non numeric keys
  if not(('0' <= key) and (key <= '9') or (key = #8) or (key = #9)) then
    key := #0;
end;

procedure TfrmAddType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
end;

end.

