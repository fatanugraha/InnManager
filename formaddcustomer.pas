unit formaddcustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, sqldb,
  ExtCtrls, ComCtrls, CheckLst;

type

  { TfrmAddCustomer }
  TOrderRec = record
    name: string;
    jenis: string;
    id, harga, sum, days: integer;
    checkin, checkout: string;
  end;

  TfrmAddCustomer = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    btnAddRoom: TButton;
    btnRemoveRoom: TButton;
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    edtName: TLabeledEdit;
    edtPriceFront: TLabeledEdit;
    edtInstance: TLabeledEdit;
    edtContact1: TLabeledEdit;
    edtContact2: TLabeledEdit;
    edtPriceRoom: TLabeledEdit;
    edtPriceFood: TLabeledEdit;
    edtPriceMisc: TLabeledEdit;
    edtPriceRem: TLabeledEdit;
    edtPriceAdd: TLabeledEdit;
    lvRooms: TListView;
    mmNote: TMemo;
    procedure btnAddRoomClick(Sender: TObject);
		procedure btnRemoveRoomClick(Sender: TObject);
		procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure edtPriceAddChange(Sender: TObject);
    procedure edtPriceRoomKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
		procedure lvRoomsClick(Sender: TObject);
  private
    { private declarations }
  public
    tmpOrder: array of TOrderRec;
    procedure UpdateOrders;
  end;

var
  frmAddCustomer: TfrmAddCustomer;

implementation

{$R *.lfm}

{ TfrmAddCustomer }

uses
  formMain, formAddRoom, lib.common, lib.logger, lib.database;

procedure TfrmAddCustomer.UpdateOrders;
var
  item: TListItem;
  i, sum: integer;
begin
  lvRooms.Clear;

  sum := 0;
  for i := 0 to Length(tmpOrder)-1 do begin
    item := TListItem.Create(lvRooms.Items);
    item.Caption := IntToStr(i+1);
    item.SubItems.Add(tmpOrder[i].name);
    item.SubItems.Add(tmpOrder[i].jenis);
    item.SubItems.Add(tmpOrder[i].checkin);
    item.SubItems.Add(tmpOrder[i].checkout);
    item.SubItems.Add(GroupDigits(tmpOrder[i].harga));
    item.SubItems.Add(IntToStr(tmpOrder[i].days));
    item.SubItems.Add(GroupDigits(tmpOrder[i].sum));
    lvRooms.Items.AddItem(item);

    inc(sum, tmpOrder[i].sum);
  end;

  edtPriceRoom.Text := GroupDigits(sum);
  lvRoomsClick(nil);
end;

procedure TfrmAddCustomer.lvRoomsClick(Sender: TObject);
begin
  btnRemoveRoom.Visible := lvRooms.ItemIndex <> -1;
end;

procedure TfrmAddCustomer.FormShow(Sender: TObject);
begin
  //reset form
  SetLength(tmpOrder, 0);
  edtName.Text := '';
  edtInstance.Text := '';
  edtContact1.Text := '';
  edtContact2.Text := '';
  mmNote.Text := '';
  edtPriceRoom.Text := '0';
  edtPriceFood.Text := '0';
  edtPriceMisc.Text := '0';
  edtPriceAdd.Text := '0';
  edtPriceRem.Text := '0';
  edtPriceFront.Text := '0';
  Label6.Caption := '0';
  Label11.Caption := '0';
  Label13.Caption := '0';
  lvRooms.Clear;
  lvRoomsClick(nil);
end;

procedure TfrmAddCustomer.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
end;

procedure TfrmAddCustomer.btnAddRoomClick(Sender: TObject);
begin
  Enabled := false;
  frmAddRoom.Show;
end;

procedure TfrmAddCustomer.btnRemoveRoomClick(Sender: TObject);
var
  i: integer;
begin
  for i := lvRooms.ItemIndex to Length(tmpOrder)-2 do
    tmpOrder[i] := tmpOrder[i+1];
  SetLength(tmpOrder, length(tmpOrder)-1);
  UpdateOrders;
end;

procedure TfrmAddCustomer.Button1Click(Sender: TObject);
const
  SEPARATOR = '|';
var
  Query1, Query2: TSQLQuery;
  OwnerID, start, i: integer;
  OrderData: string;
begin
  if (IsFieldEmpty(edtName)) then
    exit;

  if (IsFieldEmpty(edtContact1)) then
    exit;

  //tutup dulu
  frmMain.dbOrdersQuery.Close;

  //ambil ownerid
  Query1 := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  Query1.SQL.Text := 'SELECT * FROM `sqlite_sequence`';
  Query1.Open;
  //CAREFUL! Assuming this db contains 1 table
  if (Query1.EOF) then
    OwnerID := 1
  else
    OwnerID := Query1.FieldByName('seq').AsInteger+1;
  Query1.Close;

  // tulis semua orders kamar
  Query2 := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  Query2.SQL.Text := 'SELECT * FROM `sqlite_sequence`';
  Query2.Open;
  //CAREFUL! Assuming this db contains 1 table
  if (Query2.EOF) then
    start := 1
  else
    start := Query2.FieldByName('seq').AsInteger+1;
  Query2.Close;

  Query2.SQL.Text := 'INSERT INTO `orders`(`owner_id`, `room_id`, `checkin`, `checkout`, `price`, `status`) VALUES '+
                     '(:ownerid, :roomid, :checkin, :checkout, :price, 1)';

  for i := 0 to length(tmpOrder)-1 do
  begin
    if i > 0 then
      OrderData := OrderData + SEPARATOR;
    OrderData := OrderData + IntToStr(start+i);

    Query2.ParamByName('ownerid').AsInteger := OwnerID;
    Query2.ParamByName('roomid').AsInteger := tmpOrder[i].id;
    Query2.ParamByName('checkin').AsString := tmpOrder[i].checkin;
    Query2.ParamByName('checkout').AsString := tmpOrder[i].checkout;
    Query2.ParamByName('price').AsInteger := tmpOrder[i].harga;
    Query2.ExecSQL;
	end;
  frmMain.dbOrdersTransaction.Commit;

  Query1.SQL.Text := 'INSERT INTO `data`(`name`, `instance`, `contact1`, `contact2`, `note`, `bill_room`, `bill_food`, `bill_misc`, `bill_add`, `bill_rem`, `bill_front`, `active`, `date_created`, `order_data`) '+
                     'VALUES (:name, :instance, :contact1, :contact2, :note, :bill_room, :bill_food, :bill_misc, :bill_add, :bill_rem, :bill_front, 1, :date_created, :order_data)';
  Query1.ParamByName('name').AsString := edtName.Text;
  Query1.ParamByName('instance').AsString := edtInstance.Text;
  Query1.ParamByName('contact1').AsString := edtContact1.Text;
  Query1.ParamByName('contact2').AsString := edtContact2.Text;
  Query1.ParamByName('note').AsString := mmNote.Text;
  Query1.ParamByName('bill_room').AsInteger := UngroupDigits(edtPriceRoom.Text);
  Query1.ParamByName('bill_food').AsInteger := UngroupDigits(edtPriceFood.Text);
  Query1.ParamByName('bill_misc').AsInteger := UngroupDigits(edtPricemisc.Text);
  Query1.ParamByName('bill_add').AsInteger := UngroupDigits(edtPriceadd.Text);
  Query1.ParamByName('bill_rem').AsInteger := UngroupDigits(edtPricerem.Text);
  Query1.ParamByName('bill_front').AsInteger := UngroupDigits(edtPricefront.Text);
  Query1.ParamByName('date_created').AsString := FormatDateTime('dd/mm/yyyy', now);
  Query1.ParamByName('order_data').AsString := OrderData;
  Query1.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;;

  Query2.Free;
  Query1.Free;
  Close;

  //refresh orders
  frmMain.dbOrdersQuery.Open;
end;

procedure TfrmAddCustomer.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddCustomer.edtPriceAddChange(Sender: TObject);
begin
  TEdit(Sender).Text := GroupDigits(UnGroupDigits(TEdit(Sender).Text));
  TEdit(sender).SelStart := Length(TEdit(Sender).Text);

  Label6.Caption := GroupDigits(UnGroupDigits(edtPriceRoom.Text)+UnGroupDigits(edtPriceFood.Text)+UnGroupDigits(edtPriceMisc.Text));
  Label11.Caption := GroupDigits(UnGroupDigits(Label6.Caption)+UnGroupDigits(edtPriceAdd.Text)-UnGroupDigits(edtPriceRem.Text));
  Label13.Caption := GroupDigits(UnGroupDigits(Label11.Caption)-UnGroupDigits(edtPriceFront.Text));
end;

procedure TfrmAddCustomer.edtPriceRoomKeyPress(Sender: TObject; var Key: char);
begin
  if not(('0' <= key) and (key <= '9') or (key = #8)) then
    key := #0
end;

end.

