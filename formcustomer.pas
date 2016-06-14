unit formCustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, CheckBoxThemed, ListViewFilterEdit, Forms,
  Controls, Graphics, Dialogs, ComCtrls, sqldb, LCLType, StdCtrls;

type

  { TfrmCustomer }
  TfrmCustomer = class(TForm)
    btnAdd: TButton;
    btnRemove: TButton;
    btnEdit: TButton;
    CheckBox1: TCheckBox;
    ListView1: TListView;
    procedure btnAddClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
  public
    filt: integer;
    procedure LoadData;
  end;

var
  frmCustomer: TfrmCustomer;

implementation

{$R *.lfm}

uses
  lib.database, lib.common, FormMain, FormAddCustomer;

{ TfrmCustomer }

procedure TfrmCustomer.LoadData;
var
  query: TSQLQuery;
  item: TListItem;
  sum: integer;
begin
  listview1.Clear;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  if filt = 1 then
    query.SQL.Text := 'SELECT * FROM `data` WHERE `active` = 1'
  else
    query.SQL.Text := 'SELECT * FROM `data`';
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

  LoadData;
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

procedure TfrmCustomer.CheckBox1Change(Sender: TObject);
begin
  if checkbox1.Checked then
    filt := 0
  else
    filt := 1;
  LoadData;
end;

procedure TfrmCustomer.FormCreate(Sender: TObject);
begin
  filt := 1;
end;

procedure TfrmCustomer.FormShow(Sender: TObject);
begin
  btnRemove.Visible := false;
  btnEdit.Visible := false;
  LoadData;
end;

procedure TfrmCustomer.ListView1Click(Sender: TObject);
begin
  btnEdit.Visible := listview1.ItemIndex <> -1;
  btnRemove.Visible := listview1.ItemIndex <> -1;
end;

end.

