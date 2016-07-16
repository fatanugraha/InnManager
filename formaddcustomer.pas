{
  formaddcustomer.pas
  :: handles customer management and print invoices
}

unit formaddcustomer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  sqldb, memds, LCLType, dateUtils, ExtCtrls, ComCtrls, LR_Desgn,
  LR_Class, LR_DBSet;

type
  { TfrmAddCustomer }
  TOrderRec = record
    //auxiliary
    nama, jenis: string;
    sum, days: integer;
    //dari db
    checkin, checkout: string;
    room_id, harga: integer;
    db_id: integer; //0 kalau belom disimpan di database
  end;

  TRoomRec = record
    id, active: integer;
    nama, jenis: string;
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
    btnPrintAdv: TButton;
    btnPrintFull: TButton;
    Button3: TButton;
    Button6: TButton;
    edtContact1: TLabeledEdit;
    edtContact2: TLabeledEdit;
    edtIdentity: TLabeledEdit;
    edtInstance: TLabeledEdit;
    edtName: TLabeledEdit;
    edtPriceAdd: TLabeledEdit;
    edtPriceFood: TLabeledEdit;
    edtPriceFront: TLabeledEdit;
    edtPriceMisc: TLabeledEdit;
    edtPriceRem: TLabeledEdit;
    edtPriceRoom: TLabeledEdit;
    frDBDataSet1: TfrDBDataSet;
    frDBDataSet2: TfrDBDataSet;
    frReport1: TfrReport;
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
    lvRooms: TListView;
    ds1: TMemDataset;
    ds2: TMemDataset;
    mmNote: TMemo;
    Panel1: TPanel;
    pnlEdit: TPanel;
    procedure btnAddRoomClick(Sender: TObject);
    procedure btnRemoveRoomClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btnPrintAdvClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure edtPriceAddChange(Sender: TObject);
    procedure edtPriceRoomKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GroupBox2Click(Sender: TObject);
    procedure lvRoomsClick(Sender: TObject);
  private
    tmpKamar: array of TRoomRec;
    final: boolean;
  public
    FromCalendar: boolean;
    tmpKamarActive: array of TRoomRec;
    tmpOrder: array of TOrderRec;
    EditID: integer;
    //simpan id order yang udah dihapus
    tmpDeleted: array of integer;
    //refresh listview sama pesanan kamar current person
    procedure UpdateOrders;
  end;

var
  frmAddCustomer: TfrmAddCustomer;

implementation

{$R *.lfm}

{ TfrmAddCustomer }

uses
  formMain, formAddRoom, lib.common, lib.logger, lib.database, formLogin,
  formCustomer, formCalendar;

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
    item.SubItems.Add(tmpOrder[i].nama);
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
  EDIT_HEIGHT = 42;
  DEFAULT_HEIGHT = 600;
var
  query: TSQLQuery;
  i, buf, sz, l, r, idx, mid: integer;
  tmp: string;
begin
  if editID = 0 then
    Caption := Format('%s | %s', [APP_NAME, 'Buat Reservasi'])
  else
    Caption := Format('%s | %s', [APP_NAME, 'Lihat/Ubah Reservasi']);

  final := false;
  SetLength(tmpOrder, 0);
  SetLength(tmpKamar, 0);
  SetLength(tmpKamarActive, 0);
  SetLength(tmpDeleted, 0);

  btnRemoveRoom.visible := false;

  //load data kamar biar lookup id kamar biar ga query terus
  //assuming setiap query O(N) N = banyak record
  query := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  query.SQL.Text := 'SELECT `id`,`name`,`typename`,`active` FROM `product`';
  query.open;
  while not query.eof do
  begin
    sz := Length(tmpKamar);
    SetLength(tmpKamar, sz+1);
    tmpKamar[sz].id := query.FieldByName('id').AsInteger;
    tmpKamar[sz].nama := query.FieldByName('name').AsString;
    tmpKamar[sz].jenis := query.FieldByName('typename').AsString;
    tmpKamar[sz].active := query.FieldByName('active').AsInteger;

    if tmpKamar[sz].active = 1 then
    begin
      sz := Length(tmpKamarActive);
      SetLength(tmpKamarActive, sz+1);
      tmpKamarActive[sz].id := query.FieldByName('id').AsInteger;
      tmpKamarActive[sz].nama := query.FieldByName('name').AsString;
      tmpKamarActive[sz].jenis := query.FieldByName('typename').AsString;
      tmpKamarActive[sz].active := query.FieldByName('active').AsInteger;
    end;
    query.Next;
  end;
  query.close;
  query.Free;

  //reset form to its default
  pnlEdit.Height := 0;
  Height := DEFAULT_HEIGHT;
  edtPriceRoom.Text := '0';
  edtPriceFood.Text := '0';
  edtPriceMisc.Text := '0';
  edtPriceAdd.Text := '0';
  edtPriceRem.Text := '0';
  edtPriceFront.Text := '0';
  Label6.Caption := '0';
  Label11.Caption := '0';
  Label13.Caption := '0';
  edtName.Text := '';
  edtInstance.Text := '';
  edtContact1.Text := '';
  edtContact2.Text := '';
  mmNote.Text := '';
  edtIdentity.Text := '';
  lvRooms.Clear;
  lvRoomsClick(nil);

  //kalau sekarang modenya edit load data user ke form
  if (editID > 0) then
  begin
    //tampilin panel yang diatas
    Height := Height + EDIT_HEIGHT;
    pnlEdit.Height := EDIT_HEIGHT;

    query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
    query.SQL.Text := 'SELECT * FROM `data` WHERE `id` = :id';
    query.ParamByName('id').AsInteger := EditID;
    query.Open;
    edtName.Text       := query.FieldByName('name').AsString;
    edtInstance.Text   := query.FieldByName('instance').AsString;
    edtContact1.Text   := query.FieldByName('contact1').AsString;
    edtContact2.Text   := query.FieldByName('contact2').AsString;
    mmNote.Text        := query.FieldByName('note').AsString;
    edtPriceFood.Text  := query.FieldByName('bill_food').AsString;
    edtPriceMisc.Text  := query.FieldByName('bill_misc').AsString;
    edtPriceAdd.Text   := query.FieldByName('bill_add').AsString;
    edtPriceRem.Text   := query.FieldByName('bill_rem').AsString;
    edtPriceFront.Text := query.FieldByName('bill_front').AsString;
    edtIdentity.Text   := query.FieldByName('stuffs').AsString;
    tmp                := query.FieldByName('order_data').AsString;
    final              := query.FieldByName('done').AsInteger = 1;
    query.close;
    query.free;

    //masukin id orders ke daftar pesanan kamar current user
    buf := 0;
    for i := 1 to Length(tmp) do
      if (tmp[i] = SEPARATOR) then
      begin
        sz := Length(tmpOrder);
        SetLength(tmpOrder, sz+1);
        tmpOrder[sz].db_id := buf;
        buf := 0;
      end else begin
        buf := buf * 10;
        buf := buf + Ord(tmp[i]) - Ord('0');
      end;

    //load data orders dari id yang udah di provide
    query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
    query.SQL.Text := 'SELECT * FROM `orders` WHERE ';

    for i := 0 to Length(tmpOrder)-1 do
    begin
      if (i > 0) then
        query.SQL.Text := query.SQL.Text + 'OR ';
      query.SQL.Text := query.SQL.Text + Format('`id` = %d ', [tmpOrder[i].db_id]);
    end;

    query.Open;
    i := 0;
    while (not query.EOF) do
    begin
      tmpOrder[i].room_id := query.FieldByName('room_id').AsInteger;

      //binary search id kamar  -> ini overkill, TODO: ganti O(N) aja
      l := 0;
      r := High(tmpKamar);
      idx := -1;
      while (l <= r) and (idx = -1) do
      begin
        mid := (l+r) div 2;
        if (tmpOrder[i].room_id < tmpKamar[mid].id) then
          r := mid - 1
        else if (tmpOrder[i].room_id > tmpKamar[mid].id) then
          l := mid + 1
        else if (tmpOrder[i].room_id = tmpKamar[mid].id) then
          idx := mid;
      end;

      with tmpOrder[i] do
      begin
        harga    := query.FieldByName('price').AsInteger;
        checkin  := query.FieldByName('checkin').AsString;
        checkout := query.FieldByName('checkout').AsString;
        nama     := tmpKamar[idx].nama;
        jenis    := tmpKamar[idx].jenis;
        days     := DaysBetween(StrToDate(tmpOrder[i].checkin), StrToDate(tmpOrder[i].checkout));
        sum      := tmpOrder[i].harga * tmpOrder[i].days;
      end;

      inc(i);
      query.Next;
    end;
    query.Close;
    query.Free;

    UpdateOrders;
  end;

  for i := 0 to ComponentCount-1 do
  begin
    if copy(Components[i].Name, 1, 3) = 'edt' then
      TEdit(Components[i]).ReadOnly := final;
    if copy(Components[i].Name, 1, 2) = 'mm' then
      TMemo(Components[i]).ReadOnly := final;
  end;

  edtPriceRoom.ReadOnly:=true;
  btnAddRoom.Visible := not Final;
  button6.Enabled := not Final;

  if Final then
  begin
    button6.Caption := 'Telah Final';
    lvRooms.Width := btnAddRoom.Left+btnAddroom.Width-lvRooms.Left;
  end else begin
    lvRooms.Width := btnAddRoom.Left-8-lvRooms.Left;
    button6.Caption := 'Finalisasi Transaksi';
  end;
end;

procedure TfrmAddCustomer.GroupBox2Click(Sender: TObject);
begin

end;

procedure TfrmAddCustomer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmMain.Enabled := true;
  frmAddCustomer.FromCalendar := false;
end;

procedure TfrmAddCustomer.FormCreate(Sender: TObject);
begin
  frmAddCustomer.FromCalendar := false;
end;

procedure TfrmAddCustomer.btnAddRoomClick(Sender: TObject);
begin
  Enabled := false;
  frmAddRoom.Show;
end;

procedure TfrmAddCustomer.btnRemoveRoomClick(Sender: TObject);
var
  ret, i: integer;
begin
  ret := Application.MessageBox('Apakah anda yakin untuk menghapus pesanan kamar ini?', 'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);
  if ret <> ID_YES then
    exit;

  if tmpOrder[lvRooms.ItemIndex].db_id > 0 then
  begin
    i := Length(tmpDeleted);
    SetLength(tmpDeleted, i+1);
    tmpDeleted[i] := tmpOrder[lvRooms.ItemIndex].db_id;
  end;

  for i := lvRooms.ItemIndex to High(tmpOrder)-1 do
    tmpOrder[i] := tmpOrder[i+1];

  SetLength(tmpOrder, length(tmpOrder)-1);
  UpdateOrders;
end;

procedure TfrmAddCustomer.Button1Click(Sender: TObject);
const
  SEPARATOR = '|';
var
  Query1, Query2: TSQLQuery;
  j, buf, OwnerID, start, i, cnt: integer;
  prev, validprev, OrderData: string;
  ex: boolean;
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

  //tutup ordersquery untuk update
  frmMain.dbOrdersQuery.Close;

  //ambil ownerid untuk orders customer ini
  //isi database cuma 1 table, kalau lebih edit kodenya
  Query1 := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  Query1.SQL.Text := 'SELECT * FROM `sqlite_sequence`';
  Query1.Open;
  if (Query1.EOF) then
    OwnerID := 1
  else
    OwnerID := Query1.FieldByName('seq').AsInteger+1;
  Query1.Close;

  //tulis id orders yang dipesan current customer buat di store di field order_data
  //isi database cuma 1 table, kalau lebih edit kodenya
  Query2 := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  Query2.SQL.Text := 'SELECT * FROM `sqlite_sequence`';
  Query2.Open;
  if (Query2.EOF) then
    start := 1
  else
    start := Query2.FieldByName('seq').AsInteger+1;
  Query2.Close;

  Query2.SQL.Text := 'INSERT INTO `orders`(`owner_id`, `room_id`, `checkin`, `checkout`, `price`, `status`) VALUES '+
                     '(:ownerid, :roomid, :checkin, :checkout, :price, 1)';

  //sekalian masukin database order masing masing (beda kamar beda id order)
  cnt := 0;
  for i := 0 to High(tmpOrder) do
  begin
    if tmpOrder[i].db_id > 0 then
      continue;

    OrderData := OrderData + IntToStr(start+cnt) + SEPARATOR;

    if EditID > 0 then
      Query2.ParamByName('ownerid').AsInteger := EditID
    else
      Query2.ParamByName('ownerid').AsInteger := OwnerID;

    Query2.ParamByName('roomid').AsInteger  := tmpOrder[i].room_id;
    Query2.ParamByName('checkin').AsString  := tmpOrder[i].checkin;
    Query2.ParamByName('checkout').AsString := tmpOrder[i].checkout;
    Query2.ParamByName('price').AsInteger   := tmpOrder[i].harga;
    Query2.ExecSQL;

    inc(cnt);
  end;

  //hapus yang dihapus :v
  if Length(tmpDeleted) > 0 then
  begin
    Query2.SQL.Text := 'DELETE FROM `orders` WHERE ';

    for i := 0 to High(tmpDeleted) do
    begin
      if i > 0 then
        Query2.SQL.Text := Query2.SQL.Text + 'OR ';
      Query2.SQL.Text := Query2.SQL.Text + Format('`id` = %d ', [tmpDeleted[i]]);
    end;
    //dump(query2.SQL.Text);
    query2.ExecSQL;
  end;

  if EditID = 0 then
  begin
    //masukin data customer
    Query1.SQL.Text := 'INSERT INTO `data`(`name`, `instance`, `contact1`, `contact2`, `note`, `bill_room`, `bill_food`, `bill_misc`, `bill_add`, `bill_rem`, `bill_front`, `active`, `date_created`, `order_data`, `by_who`, `stuffs`, `done`) '+
                       'VALUES (:name, :instance, :contact1, :contact2, :note, :bill_room, :bill_food, :bill_misc, :bill_add, :bill_rem, :bill_front, 1, :date_created, :order_data, :bywho, :stuffs, 0)';

    Query1.ParamByName('name').AsString         := edtName.Text;
    Query1.ParamByName('instance').AsString     := edtInstance.Text;
    Query1.ParamByName('contact1').AsString     := edtContact1.Text;
    Query1.ParamByName('contact2').AsString     := edtContact2.Text;
    Query1.ParamByName('note').AsString         := mmNote.Text;
    Query1.ParamByName('bill_room').AsInteger   := UngroupDigits(edtPriceRoom.Text);
    Query1.ParamByName('bill_food').AsInteger   := UngroupDigits(edtPriceFood.Text);
    Query1.ParamByName('bill_misc').AsInteger   := UngroupDigits(edtPricemisc.Text);
    Query1.ParamByName('bill_add').AsInteger    := UngroupDigits(edtPriceadd.Text);
    Query1.ParamByName('bill_rem').AsInteger    := UngroupDigits(edtPricerem.Text);
    Query1.ParamByName('bill_front').AsInteger  := UngroupDigits(edtPricefront.Text);
    Query1.ParamByName('date_created').AsString := FormatDateTime('dddd, dd/mm/yyyy hh:nn:ss', now);
    Query1.ParamByName('order_data').AsString   := OrderData;
    Query1.ParamByName('bywho').AsString        := Format('%s (%s)', [CurrentSession.FullName, CurrentSession.Username]);
    Query1.ParamByName('stuffs').AsString       := edtIdentity.Text;
    Query1.ExecSQL;
  end else begin
    query1.SQL.Text := 'SELECT `order_data` FROM `data` WHERE `id` = :id';
    query1.ParamByName('id').AsInteger := EditID;
    query1.Open;
    prev := query1.FieldByName('order_data').AsString;
    query1.Close;

    //gabungin pesanan sebelumnya yang ngga dihapus sama yang baru
    buf := 0;
    for i := 1 to length(prev) do
    begin
      if prev[i] = SEPARATOR then
      begin
        ex := false;
        for j := 0 to High(tmpDeleted) do
          if tmpDeleted[j] = buf then
          begin
            ex := true;
            break;
          end;

        if not ex then
          validprev := validprev + IntToStr(buf) + SEPARATOR;

        buf := 0;
      end else begin
        buf := buf * 10 + Ord(prev[i]) - Ord('0');
      end;
    end;
    OrderData := validprev + OrderData;

    query1.SQL.Text := 'UPDATE `data` SET `name` = :name, `instance` = :instance, `contact1` = :contact1, `contact2` = :contact2, `note` = :note, `bill_room` = :bill_room, '+
                       '`bill_food` = :bill_food, `bill_misc` = :bill_misc, `bill_add` = :bill_add, `bill_rem` = :bill_rem, `bill_front` = :bill_front, '+
                       '`order_data` = :order_data, `stuffs` = :stuffs WHERE `id` = :id';

    Query1.ParamByName('name').AsString         := edtName.Text;
    Query1.ParamByName('instance').AsString     := edtInstance.Text;
    Query1.ParamByName('contact1').AsString     := edtContact1.Text;
    Query1.ParamByName('contact2').AsString     := edtContact2.Text;
    Query1.ParamByName('note').AsString         := mmNote.Text;
    Query1.ParamByName('bill_room').AsInteger   := UngroupDigits(edtPriceRoom.Text);
    Query1.ParamByName('bill_food').AsInteger   := UngroupDigits(edtPriceFood.Text);
    Query1.ParamByName('bill_misc').AsInteger   := UngroupDigits(edtPricemisc.Text);
    Query1.ParamByName('bill_add').AsInteger    := UngroupDigits(edtPriceadd.Text);
    Query1.ParamByName('bill_rem').AsInteger    := UngroupDigits(edtPricerem.Text);
    Query1.ParamByName('bill_front').AsInteger  := UngroupDigits(edtPricefront.Text);
    Query1.ParamByName('order_data').AsString   := OrderData;
    Query1.ParamByName('stuffs').AsString       := edtIdentity.Text;
    Query1.ExecSQL;
  end;
  frmMain.dbOrdersTransaction.Commit;
  frmMain.dbCustomersTransaction.Commit;

  Query2.Free;
  Query1.Free;

  if sender = button6 then
  begin
    //TODO: kitamark semua kamar checkout
  end;


  //buka lagi querynya setelah update
  frmMain.dbOrdersQuery.Open;

  //refresh orders
  if sender <> button6 then
    if not FromCalendar then
      frmCustomer.LoadData
    else
      frmCalendar.ReloadData;

  if (EditID = 0) and (UngroupDigits(edtPricefront.Text) > 0) then
  begin
    if Application.MessageBox('Cetak Nota Pembayaran DP?', 'Cetak Nota',
      MB_ICONQUESTION or MB_YESNO) = ID_YES then
      begin
        btnPrintAdv.Click;
      end;
  end;
  Close;
end;

procedure TfrmAddCustomer.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddCustomer.btnPrintAdvClick(Sender: TObject);
var
  i: integer;
begin
  with ds1 do
  begin
    ds1.Clear(false);
    Append;
    Fields[0].AsString    := edtName.Text + ' - ' + edtInstance.Text;

    if Sender = btnPrintAdv then
      Fields[1].AsString := 'Rp' + edtPriceFront.Text
    else
      Fields[1].AsString := 'Rp' + Label13.Caption;

    Fields[2].AsString :=  edtIdentity.Text;
    Fields[3].AsString := 'Rp' + edtPriceRoom.Text;
    Fields[4].AsString := 'Rp' + edtPricefood.Text;
    Fields[5].AsString := 'Rp' + edtPricemisc.Text;
    Fields[6].AsString := 'Rp' + edtPriceAdd.Text;
    Fields[7].AsString := 'Rp' + edtPriceRem.Text;
    Fields[8].AsString := 'Rp' + edtPricefront.Text;
    Fields[9].AsString := 'Rp' + label13.Caption;
    Fields[10].AsString := CurrentSession.FullName;
    Fields[11].AsString := FormatDateTime('dddd, dd mmmm yyyy', now);
    Fields[12].AsString := 'Rp' + label11.Caption;
  end;

  ds2.Clear(false);
  for i := 0 to LvRooms.Items.Count-1 do
  begin
    with ds2 do
    begin
      Append;
      Fields[0].AsInteger := i+1;
      Fields[1].AsString := lvRooms.Items[i].SubItems[0];
      Fields[2].AsString := lvRooms.Items[i].SubItems[1];
      Fields[3].AsString := lvRooms.Items[i].SubItems[4];
      Fields[4].AsString := lvRooms.Items[i].SubItems[2];
      Fields[5].AsString := lvRooms.Items[i].SubItems[3];
      Fields[6].AsString := lvRooms.Items[i].SubItems[5];
      Fields[7].AsString := lvRooms.Items[i].SubItems[6];
    end;
  end;

  if Sender = btnPrintAdv then
    frReport1.LoadFromFile(CurrentDir+FILE_INV_ADV)
  else
    frReport1.LoadFromFile(CurrentDir+FILE_INV_FULL);
  frReport1.ShowReport;
end;

procedure TfrmAddCustomer.Button3Click(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  ret := Application.MessageBox('Apakah anda yakin untuk menghapus data pelanggan ini?'+LineEnding+
                                'Semua pesanan pelanggan ini juga akan dihapus.', 'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);
  if ret <> ID_YES then
    exit;

  frmMain.dbOrdersQuery.Close;

  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'DELETE FROM `data` WHERE `id` = :id';
  query.ParamByName('id').AsInteger := EditId;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'DELETE FROM `orders` WHERE `owner_id` = :id';
  query.ParamByName('id').AsInteger := EditId;
  query.ExecSQL;
  frmMain.dbOrdersTransaction.Commit;
  query.Free;

  frmMain.dbOrdersQuery.Open;

  if not FromCalendar then
    frmCustomer.LoadData
  else
    frmCalendar.ReloadData;

  close;
end;

procedure TfrmAddCustomer.Button6Click(Sender: TObject);
var
  ret: integer;
  query: TSQLQuery;
begin
  ret := Application.MessageBox('Apakah anda ingin menandai kustomer ini telah '+
    'selesai transaksi dan telah melunasi pembayaran?'+LineEnding+
    'Data tidak dapat diubah setelah di finalisasi dan semua kamar '+
    'akan ditandai telah check-out',
    'Konfirmasi', MB_ICONQUESTION or MB_YESNOCANCEL);

  if ret <> ID_YES then
    exit;

  Button1Click(button6);

  //mark kalo selesai
  query := CreateQuery(frmMain.dbCustomersConnection, frmMain.dbCustomersTransaction);
  query.SQL.Text := 'UPDATE `data` SET `done` = 1, `active` = 0 WHERE `id` = :id';
  query.ParamByName('id').AsInteger := EditId;
  query.ExecSQL;
  frmMain.dbCustomersTransaction.Commit;
  query.Free;

  frmCustomer.LoadData;
end;

procedure TfrmAddCustomer.edtPriceAddChange(Sender: TObject);
begin
  TEdit(Sender).Text     := GroupDigits(UnGroupDigits(TEdit(Sender).Text));
  TEdit(sender).SelStart := Length(TEdit(Sender).Text);

  Label6.Caption  := GroupDigits(UnGroupDigits(edtPriceRoom.Text)+UnGroupDigits(edtPriceFood.Text)+UnGroupDigits(edtPriceMisc.Text));
  Label11.Caption := GroupDigits(UnGroupDigits(Label6.Caption)+UnGroupDigits(edtPriceAdd.Text)-UnGroupDigits(edtPriceRem.Text));
  Label13.Caption := GroupDigits(UnGroupDigits(Label11.Caption)-UnGroupDigits(edtPriceFront.Text));
end;

procedure TfrmAddCustomer.edtPriceRoomKeyPress(Sender: TObject; var Key: char);
begin
  //restrict selain angka sama backspace
  if not(('0' <= key) and (key <= '9') or (key = #8)) then
    key := #0
end;

end.

