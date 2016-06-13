unit formCustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, sqldb,
  StdCtrls;

type

  { TfrmCustomer }

  TfrmCustomer = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ListView1: TListView;
    procedure Button1Click(Sender: TObject);
		procedure Button3Click(Sender: TObject);
		procedure FormShow(Sender: TObject);
  public
    procedure LoadData(lv: TListView; param: integer);
  public

  end;

var
  frmCustomer: TfrmCustomer;

implementation

{$R *.lfm}

uses
  lib.database, lib.common, FormMain, FormAddCustomer;

{ TfrmCustomer }

procedure TfrmCustomer.LoadData(lv: TListView; param: integer);
var
  query: TSQLQuery;
  item: TListItem;
  sum: integer;
begin
  lv.Clear;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'SELECT * FROM `data` WHERE `active` = :param';
  query.ParamByName('param').AsInteger := param;
  query.open;

  while (not query.EOF) do
  begin
    item := TListItem.Create(lv.Items);
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
    item.SubItems.Add(GroupDigits(query.FieldByName('bill_front').AsInteger));

    if query.FieldByName('bill_front').AsInteger = 0 then
      item.SubItems.Add('Belum Bayar')
    else if query.FieldByName('bill_front').AsInteger < sum then
      item.SubItems.Add('Parsial (DP)')
    else
      item.SubItems.Add('Lunas');

    lv.Items.AddItem(item);
    query.Next;
  end;

  query.close;
  query.Free;
end;

procedure TfrmCustomer.Button1Click(Sender: TObject);
begin
  frmMain.enabled := false;
  frmAddCustomer.EditID := 0;
  frmAddCustomer.Show;
end;

procedure TfrmCustomer.Button3Click(Sender: TObject);
begin
  frmMain.enabled := false;
  frmAddCustomer.EditID := StrToInt(ListView1.Selected.Caption);
  frmAddCustomer.Show;
end;

procedure TfrmCustomer.FormShow(Sender: TObject);
begin
  LoadData(listview1, 1);
end;

end.

