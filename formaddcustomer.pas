unit formaddcustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, sqldb, LCLType, dateUtils,
  ExtCtrls, ComCtrls, CheckLst;

type

  { TfrmAddCustomer }
  TOrderRec = record
    name: string;
    jenis: string;
    id, harga, sum, days: integer;
    saved: bool;
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
		cbStatus: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
		Label1: TLabel;
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
		edtIdentity: TLabeledEdit;
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
    tmp_id: array of integer;
    tmp_nama, tmp_jenis: array of string;

    EditID: integer;

    procedure UpdateOrders;
  end;

var
  frmAddCustomer: TfrmAddCustomer;

implementation

{$R *.lfm}

{ TfrmAddCustomer }

uses
  formMain, formAddRoom, lib.common, lib.logger, lib.database, formLogin, formCustomer;

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
const
  SEPARATOR = '|';
var
  query, lookup: TSQLQuery;
  i, buf, sz, l, r, idx, mid: integer;
  tmp: string;
begin
  SetLength(tmpOrder, 0);
  SetLength(frmAddCustomer.tmp_id, 0);
  SetLength(frmAddCustomer.tmp_nama, 0);
  SetLength(frmAddCustomer.tmp_jenis, 0);

  //load data kamar dulu
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT `id`,`name`,`typename` FROM `product`';
  query.open;

  while not query.eof do
  begin
    sz := Length(tmp_id);
    SetLength(tmp_id, sz+1);
    tmp_id[sz] := query.FieldByName('id').AsInteger;

    SetLength(tmp_nama, sz+1);
    tmp_nama[sz] := query.FieldByName('name').AsString;

    SetLength(tmp_jenis, sz+1);
    tmp_jenis[sz] := query.FieldByName('typename').AsString;

    inc(sz);
    query.Next;
  end;

  query.close;
  query.Free;

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

  if (editID = 0) then
  begin
    //reset form
    edtName.Text := '';
    edtInstance.Text := '';
    edtContact1.Text := '';
    edtContact2.Text := '';
    mmNote.Text := '';
    edtIdentity.Text := '';
  end else begin
    //load data
    query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
    query.SQL.Text := 'SELECT * FROM `data` WHERE `id` = :id';
    query.ParamByName('id').AsInteger := EditID;
    query.Open;

    edtName.Text := query.FieldByName('name').AsString;
    edtInstance.Text := query.FieldByName('instance').AsString;
    edtContact1.Text := query.FieldByName('contact1').AsString;
    edtContact2.Text := query.FieldByName('contact2').AsString;
    mmNote.Text := query.FieldByName('note').AsString;
    edtPriceFood.Text := query.FieldByName('bill_food').AsString;
    edtPriceMisc.Text := query.FieldByName('bill_misc').AsString;
    edtPriceAdd.Text := query.FieldByName('bill_add').AsString;
    edtPriceRem.Text := query.FieldByName('bill_rem').AsString;
    edtPriceFront.Text := query.FieldByName('bill_front').AsString;
    edtIdentity.Text := query.FieldByName('stuffs').AsString;
    tmp := query.FieldByName('order_data').AsString;

    buf := 0;
    for i := 1 to Length(tmp) do
    begin
      if (tmp[i] = SEPARATOR) then
      begin
        sz := Length(tmpOrder);
        SetLength(tmpOrder, sz+1);

        tmpOrder[sz].id := buf;
        dump(buf);
        buf := 0;
      end else begin
        buf := buf*10;
        buf := buf + Ord(tmp[i]) - Ord('0');
      end;
    end;

    lookup := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
    lookup.SQL.Text := 'SELECT * FROM `orders` WHERE ';
    for i := 0 to Length(tmpOrder)-1 do
    begin
      if (i > 0) then
        lookup.SQL.Text := lookup.SQL.Text + 'OR ';
      lookup.SQL.Text := lookup.SQL.Text + '`id` = '+IntToStr(tmpOrder[i].id)+' ';
    end;
    lookup.Open;

    i := 0;
    while (not lookup.EOF) do
    begin
      //cari index nih kamar
      tmpOrder[i].id := lookup.FieldByName('room_id').AsInteger;

      l := 0;
      r := Length(tmp_id) - 1;
      idx := -1;
      while (l <= r) and (idx = -1) do
      begin
        mid := (l+r) div 2;
        if (tmpOrder[i].id < tmp_id[mid]) then
          r := mid - 1
        else if (tmpOrder[i].id > tmp_id[mid]) then
          l := mid + 1
        else if (tmpOrder[i].id = tmp_id[mid]) then
          idx := mid;
      end;

      tmpOrder[i].name := tmp_nama[idx];
      tmpOrder[i].jenis := tmp_jenis[idx];
      tmpOrder[i].harga := lookup.FieldByName('price').AsInteger;
      tmpOrder[i].checkin := lookup.FieldByName('checkin').AsString;
      tmpOrder[i].checkout := lookup.FieldByName('checkout').AsString;
      tmpOrder[i].days := DaysBetween(StrToDate(tmpOrder[i].checkin), StrToDate(tmpOrder[i].checkout));
      tmpOrder[i].sum := tmpOrder[i].harga * tmpOrder[i].days;
      tmpOrder[i].saved := true;

      inc(i);
      lookup.Next;
    end;

    lookup.Close;
    query.Close;
    query.Free;

    UpdateOrders;
  end;

  //pastiin gaada checkout pas buat baru
  if (editId = 0) and (cbStatus.Items.Count = 3) then
    cbStatus.Items.Delete(2)
	else if (editID > 0) and (cbStatus.Items.Count = 2) then
    cbStatus.Items.Add('Check-Out');
  cbStatus.ItemIndex := 0;
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

  if (IsFieldEmpty(edtIdentity)) then
    exit;

  if (lvRooms.Items.Count = 0) then
  begin
    application.MessageBox('Tidak ada ruangan yang dipesan.', 'Pesanan Invalid', MB_ICONEXCLAMATION);
    exit;
	end;

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
    OrderData := OrderData + IntToStr(start+i) + SEPARATOR;

    Query2.ParamByName('ownerid').AsInteger := OwnerID;
    Query2.ParamByName('roomid').AsInteger := tmpOrder[i].id;
    Query2.ParamByName('checkin').AsString := tmpOrder[i].checkin;
    Query2.ParamByName('checkout').AsString := tmpOrder[i].checkout;
    Query2.ParamByName('price').AsInteger := tmpOrder[i].harga;
    Query2.ExecSQL;
	end;
  frmMain.dbOrdersTransaction.Commit;

  Query1.SQL.Text := 'INSERT INTO `data`(`name`, `instance`, `contact1`, `contact2`, `note`, `bill_room`, `bill_food`, `bill_misc`, `bill_add`, `bill_rem`, `bill_front`, `active`, `date_created`, `order_data`, `by_who`, `stuffs`) '+
                     'VALUES (:name, :instance, :contact1, :contact2, :note, :bill_room, :bill_food, :bill_misc, :bill_add, :bill_rem, :bill_front, 1, :date_created, :order_data, :bywho, :stuffs)';

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
  Query1.ParamByName('bywho').AsString := Format('%s (%s)', [CurrentSession.FullName, CurrentSession.Username]);
  Query1.ParamByName('stuffs').AsString := edtIdentity.Text;
  Query1.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;;

  Query2.Free;
  Query1.Free;
  Close;

  //refresh orders
  frmCustomer.LoadData(frmCustomer.ListView1, 1);
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

