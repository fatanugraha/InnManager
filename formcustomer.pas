unit formCustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, sqldb, LCLType,
  StdCtrls;

type

  { TfrmCustomer }
  TfrmCustomer = class(TForm)
    btnAdd: TButton;
    btnRemove: TButton;
    btnEdit: TButton;
    ListView1: TListView;
    procedure btnAddClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
  public
    procedure LoadData(param: integer);
  end;

var
  frmCustomer: TfrmCustomer;

implementation

{$R *.lfm}

uses
  lib.database, lib.common, FormMain, FormAddCustomer;

{ TfrmCustomer }

procedure TfrmCustomer.LoadData(param: integer);
var
  query: TSQLQuery;
  item: TListItem;
  sum: integer;
begin
  listview1.Clear;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'SELECT * FROM `data` WHERE `active` = :param';
  query.ParamByName('param').AsInteger := param;
  query.open;

  while (not query.EOF) do
  begin
    item := TListItem.Create(listview1.Items);
    item.Caption := query.FieldByName('id').AsString;
    item.SubItems.Add(query.FieldByName('name').AsString);
    item.SubItems.Add(query.FieldByName('instance').AsString);
    item.SubItems.Add(query.FieldByName('contact1').AsString);
    item.SubItems.Add(query.FieldByName('contact2').AsString);
    item.SubItems.Add(query.FieldByName('note').AsString);
    sum := query.FieldByName('bill_room').AsInteger;
    Inc(sum, query.FieldByName('bill_food').AsInteger);
    Inc(sum, query.FieldByName('bill_misc').AsInteger);
    Inc(sum, query.FieldByName('bill_add').AsInteger);
    Dec(sum, query.FieldByName('bill_rem').AsInteger);
    item.SubItems.Add(GroupDigits(sum));
    item.SubItems.Add(GroupDigits(sum-query.FieldByName('bill_front').AsInteger));

    if (query.FieldByName('bill_front').AsInteger = sum) or (query.FieldByName('done').AsInteger = 1) then
      item.SubItems.Add('Lunas')
    else if query.FieldByName('bill_front').AsInteger = 0 then
      item.SubItems.Add('Belum Bayar')
    else
      item.SubItems.Add('Parsial (DP)');

    listview1.Items.AddItem(item);
    query.Next;
  end;

  query.close;
  query.Free;
end;

procedure TfrmCustomer.btnAddClick(Sender: TObject);
begin
  frmMain.enabled := false;
  frmAddCustomer.EditID := 0;
  frmAddCustomer.Show;
end;

procedure TfrmCustomer.btnRemoveClick(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  if listview1.ItemIndex = -1 then
    exit;

  ret := Application.MessageBox('Apakah anda yakin untuk menghapus data pelanggan ini?'+LineEnding+
                                'Semua pesanan pelanggan ini juga akan dihapus.', 'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);
  if ret <> ID_YES then
    exit;

  frmMain.dbOrdersQuery.Close;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'DELETE FROM `data` WHERE `id` = :id';
  query.ParamByName('id').AsString := ListView1.ItemFocused.Caption;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'DELETE FROM `orders` WHERE `owner_id` = :id';
  query.ParamByName('id').AsString := ListView1.ItemFocused.Caption;
  query.ExecSQL;
  frmMain.dbOrdersTransaction.Commit;
  query.Free;

  LoadData(1);
  ListView1Click(nil);

  frmMain.dbOrdersQuery.Open;
end;

procedure TfrmCustomer.btnEditClick(Sender: TObject);
begin
  if listview1.itemindex = -1 then
    exit;

  frmMain.enabled := false;
  frmAddCustomer.EditID := StrToInt(ListView1.Selected.Caption);
  frmAddCustomer.Show;
end;

procedure TfrmCustomer.FormShow(Sender: TObject);
begin
  btnRemove.Visible := false;
  btnEdit.Visible := false;
  LoadData(1);
end;

procedure TfrmCustomer.ListView1Click(Sender: TObject);
begin
  btnEdit.Visible := listview1.ItemIndex <> -1;
  btnRemove.Visible := listview1.ItemIndex <> -1;
end;

end.

