unit formaddroom;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, CheckLst,
  EditBtn, StdCtrls, ExtCtrls, sqldb, dateutils, LCLType;

type

  { TfrmAddRoom }

  TfrmAddRoom = class(TForm)
    Bevel1: TBevel;
    Button1: TButton;
    Button2: TButton;
    CheckListBox1: TCheckListBox;
    DateEdit1: TDateEdit;
    DateEdit2: TDateEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure DateEdit1AcceptDate(Sender: TObject; var ADate: TDateTime; var AcceptDate: Boolean);
    procedure DateEdit1Change(Sender: TObject);
    procedure DateEdit1KeyPress(Sender: TObject; var Key: char);
    procedure DateEdit2AcceptDate(Sender: TObject; var ADate: TDateTime; var AcceptDate: Boolean);
    procedure DateEdit2KeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAddRoom: TfrmAddRoom;

implementation

{$R *.lfm}

{ TfrmAddRoom }

uses
  FormMain, FormAddCustomer, lib.database, FormLogin, lib.logger, lib.common;

var
  valid: boolean;

procedure TfrmAddRoom.Button1Click(Sender: TObject);
var
  i, j, k, cnt, sz, price, current: integer;
  query, lookup: TSQLQuery;
  A, B, X, Y: TDateTime;

  flag: boolean;
  cant: array of integer;
  OK: boolean;
begin
  //pastiin form valid
  cnt := 0;
  for i := 0 to CheckListBox1.Count -1 do
    if CheckListBox1.Checked[i] then
      Inc(cnt);

  if (cnt = 0) then
  begin
    Application.MessageBox('Tidak ada ruangan yang di pilih', 'Data Salah', MB_ICONEXCLAMATION);
    exit;
  end;

  if (not valid) then
  begin
    Application.MessageBox('Tanggal check-in atau check-in tidak valid.', 'Data Salah', MB_ICONEXCLAMATION);
    exit;
  end;

  //check intersect sama existing orders terus simpan yang bentrok kamar apa aja
  query := CreateQuery(frmMain.dbOrdersConnection, frmMain.dbOrdersTransaction);
  query.SQL.Text := 'SELECT `room_id`, `checkin`,`checkout` FROM `orders` WHERE ';

  cnt := 0;
  for i := 0 to High(frmAddCustomer.tmpKamar) do
  begin
    if (CheckListBox1.Checked[i]) then
    begin
      if (cnt > 0) then
        query.SQL.Text := query.SQL.Text + 'OR ';
      query.SQL.Text := query.SQL.Text + Format('`room_id` = %d ', [frmAddCustomer.tmpKamar[i].id]);
      inc(cnt);
    end;
  end;

  if Length(frmAddCustomer.tmpDeleted) > 0 then
  begin
    query.SQL.Text := query.SQL.Text + 'AND (';
    for i := 0 to High(frmAddCustomer.tmpDeleted) do
    begin
      if i > 0 then
        query.SQL.Text := query.SQL.Text + 'OR ';
      query.SQL.Text := query.SQL.Text+Format('`id` != %d ', [frmAddCustomer.tmpDeleted[i]]);
    end;
    query.SQL.Text := query.SQL.Text + ')';
  end;
  query.open;

  A := DateEdit1.Date;
  B := IncDay(DateEdit2.Date, -1);

  OK := true;
  while (not query.EOF) do
  begin
    current := query.FieldByName('room_id').AsInteger;

    X := StrToDate(query.FieldByName('checkin').AsString);
    Y := IncDay(StrToDate(query.FieldByName('checkout').AsString), -1);

    if (isDateIntersect(A, B, X, Y)) then
    begin
      OK := false;
      //masukin ke list yang ga bisa -> O(N)
      flag := true;
      for i := 0 to Length(cant)-1 do
        if cant[i] = current then
        begin
          flag := false;
          break;
        end;

      if flag then
      begin
        i := Length(cant);
        SetLength(cant, i+1);
        cant[i] := current;
      end;
    end;

    query.Next;
  end;
  query.close;
  query.Free;

  //cek intersect sama yang sedang dipesan sama current customer
  for i := 0 to high(frmAddCustomer.tmpKamar) do
  begin
    if not CheckListBox1.Checked[i] then
      continue;

    for j := 0 to Length(frmAddCustomer.tmpOrder)-1 do
    begin
      if frmAddCustomer.tmpOrder[j].room_id = frmAddCustomer.tmpKamar[i].id then
      begin
        X := StrToDate(frmAddCustomer.tmpOrder[j].checkin);
        Y := IncDay(StrToDate(frmAddCustomer.tmpOrder[j].checkout), -1);

        if (isDateIntersect(A, B, X, Y)) then
        begin
          OK := false;

          //masukin ke list yang ga bisa -> O(N)
          flag := true;
          for k := 0 to Length(cant)-1 do
            if cant[k] = current then
            begin
              flag := false;
              break;
            end;

          if flag then
          begin
            k := Length(cant);
            SetLength(cant, k+1);
            cant[k] := current;
          end;
        end;
      end;
    end;
  end;

  if (not OK) then
  begin
    Application.MessageBox('Ada ruangan telah dipakai dalam rentang waktu yang diinginkan.', 'Reservasi Gagal',
    MB_ICONEXCLAMATION);
    exit;
  end;

  lookup := CreateQuery(frmLogin.dbCoreConnection, frmLogin.dbCoreTransaction);
  lookup.SQL.Text := 'SELECT `price` FROM `product_type` WHERE `name` = :name';

  //masukin ke tempOrder
  for i := 0 to High(frmAddCustomer.tmpKamar) do
  begin
    if (CheckListBox1.Checked[i]) then
    begin
      sz := Length(frmAddCustomer.tmpOrder);
      SetLength(frmAddCustomer.tmpOrder, sz+1);

      lookup.ParamByName('name').AsString := frmAddCustomer.tmpKamar[i].jenis;
      lookup.Open;
      frmAddCustomer.tmpOrder[sz].Harga := Lookup.FieldByName('price').AsInteger;
      Lookup.Close;

      with frmAddCustomer.tmpOrder[sz] do
      begin
        room_id := frmAddCustomer.tmpKamar[i].id;
        nama    := frmAddCustomer.tmpKamar[i].nama;
        jenis   := frmAddCustomer.tmpKamar[i].jenis;
        Days    := DaysBetween(DateEdit1.Date, DateEdit2.Date);
        sum     := frmAddCustomer.tmpOrder[sz].Harga*frmAddCustomer.tmpOrder[sz].Days;
        checkin := DateEdit1.Text;
        checkout:= DateEdit2.Text;
      end;
    end;
  end;

  lookup.free;
  frmAddCustomer.UpdateOrders;
  close;
end;

procedure TfrmAddRoom.DateEdit2KeyPress(Sender: TObject; var Key: char);
begin
  key := #0;
end;

procedure TfrmAddRoom.DateEdit1KeyPress(Sender: TObject; var Key: char);
begin
  Key := #0;
end;

procedure TfrmAddRoom.DateEdit1AcceptDate(Sender: TObject; var ADate: TDateTime; var AcceptDate: Boolean);
begin
  //pastiin tanngal checkin lebih atau sama dari tanggal sekarang
  AcceptDate := (CompareDate(ADate, Now) >= 0);

  if (not AcceptDate) then
    Application.MessageBox('Tanggal check-in harus sama atau lebih dari tanggal sekarang', 'Data Salah', MB_ICONEXCLAMATION);
end;

procedure TfrmAddRoom.DateEdit2AcceptDate(Sender: TObject; var ADate: TDateTime; var AcceptDate: Boolean);
begin
  //pastiin tanngal checkout lebih dari tanggal sekarang
  AcceptDate := (CompareDate(ADate, DateEdit1.Date) > 0);

  if (not AcceptDate) then
    Application.MessageBox('Tanggal check-out harus lebih dari tanggal check-in', 'Data Salah', MB_ICONEXCLAMATION)
  else begin
    Label4.Caption := Format('Total Hari: %d', [DaysBetween(DateEdit1.Date, ADate)]);
    valid := true;
  end;
end;

procedure TfrmAddRoom.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddRoom.DateEdit1Change(Sender: TObject);
begin
  if (DateEdit1.Text <> '') then
    DateEdit2.Enabled := true;
end;

procedure TfrmAddRoom.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  frmAddCustomer.Enabled := true;
end;

procedure TfrmAddRoom.FormShow(Sender: TObject);
var
  i: integer;
begin
  CheckListBox1.Clear;
  for i := 0 to High(frmAddCustomer.tmpKamar) do
    CheckListBox1.Items.Add(Format('%s (%s)', [frmAddCustomer.tmpKamar[i].nama, frmAddCustomer.tmpKamar[i].jenis]));

  DateEdit1.Clear;
  DateEdit2.Clear;
  Label4.Caption := 'Total Hari: 0';
  DateEdit2.Enabled := false;

  valid := false;
end;

end.

